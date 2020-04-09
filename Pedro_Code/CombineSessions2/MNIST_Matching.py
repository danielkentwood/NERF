# %%

# Model
import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
import numpy as np
from torchvision import datasets, transforms
from PIL import Image
import math
from torch.utils.data import Dataset
from torch.utils.data.sampler import BatchSampler
import matplotlib.pyplot as plt
import os
from tabulate import tabulate

class LogisticRegression_on_Diff(nn.Module):
    def __init__(self, input_size):
        super(LogisticRegression_on_Diff, self).__init__()
        self.linear = nn.Linear(input_size, 1)
        self.sigma = nn.Sigmoid()
    
    def forward(self, x,y):
        diff = abs(x-y)
        out = self.linear(diff)
        out = self.sigma(out)
        return out

class triplet_cross_entropy_loss(nn.Module):
    def __init__(self,device):
        super(triplet_cross_entropy_loss, self).__init__()
        self.bceloss = torch.nn.BCELoss(reduction="mean")
        self.device = device
    def forward(self, positive_prob,negative_prob):
        return self.bceloss(positive_prob, torch.ones(positive_prob.shape[0],1).to(self.device)) + self.bceloss(negative_prob, torch.zeros(negative_prob.shape[0],1).to(self.device))

# samplers
# https://github.com/adambielski/siamese-triplet/blob/master/datasets.py
class TripletMNIST(Dataset):
    """
    Train: For each sample (anchor) randomly chooses a positive and negative samples
    Test: Creates fixed triplets for testing
    """

    def __init__(self, data, labels, istrain):
        self.data = data
        self.labels = labels
        self.train = istrain
        
        
        self.labels_set = set(self.labels.numpy())
        self.label_to_indices = {label: np.where(self.labels.numpy() == label)[0]
                                    for label in self.labels_set}

        if not self.train:
            # generate fixed triplets for testing

            random_state = np.random.RandomState(29)

            triplets = [[i,
                         random_state.choice(self.label_to_indices[self.labels[i].item()]),
                         random_state.choice(self.label_to_indices[
                                                 random_state.choice(
                                                     list(self.labels_set - set([self.labels[i].item()]))
                                                 )
                                             ])
                         ]
                        for i in range(len(self.data))]
            self.test_triplets = triplets

    def __getitem__(self, index):
        if self.train:
            img1, label1 = self.data[index], self.labels[index].item()
            positive_index = index
            while positive_index == index:
                positive_index = np.random.choice(self.label_to_indices[label1])
            negative_label = np.random.choice(list(self.labels_set - set([label1])))
            negative_index = np.random.choice(self.label_to_indices[negative_label])
            img2 = self.data[positive_index]
            img3 = self.data[negative_index]

            label1 = self.labels[index]
            label2 = self.labels[positive_index]
            label3 = self.labels[negative_index]

        else:
            img1 = self.data[self.test_triplets[index][0]]
            img2 = self.data[self.test_triplets[index][1]]
            img3 = self.data[self.test_triplets[index][2]]

            label1 = self.labels[self.test_triplets[index][0]]
            label2 = self.labels[self.test_triplets[index][1]]
            label3 = self.labels[self.test_triplets[index][2]]
        
        return (img1, img2, img3), (label1, label2, label3)

    def __len__(self):
        return len(self.data)

def train_model_with_validation(model, device, trainloader, valloader, Num_epochs, LEARNING_RATE, save_folder=None,max_streak = 25,tol=0.0000001):
    if save_folder != None:
        if not os.path.exists(save_folder):
            os.makedirs(save_folder)

    loss_fn = triplet_cross_entropy_loss(device)
    optimizer = optim.Adam(model.parameters(), lr=LEARNING_RATE)

    num_train_samples = len(trainloader.dataset)
    num_val_samples = len(valloader.dataset)


    all_loss_train = []
    all_loss_val = []

    best_val = math.inf
    prev_loss = math.inf
    not_better_streak = 0
    not_better_streak_tol =0

    for epoch in range(0, Num_epochs):
        #Train
        print(epoch)
        model.train()

        train_loss_run = 0
        for i, data in enumerate(trainloader, 0):
            (anchors, positives, negatives),(l1, l2, l3) = data
            #anchors, positives, negatives = anchors.to(device), positives.to(device), negatives.to(device)

            optimizer.zero_grad()  # zero the parameter gradient
            pos_prob = model(anchors, positives)
            neg_prob = model(anchors, negatives)

            loss = loss_fn(pos_prob, neg_prob)
            loss.backward()
            optimizer.step()

            this_batch_size = len(anchors)

            train_loss_run = train_loss_run + loss.item() * this_batch_size  # loss is averaged, multiplying by n to undo and average later.

        train_loss = train_loss_run / num_train_samples
        all_loss_train.append(train_loss)


        #Validation
        model.eval()

        val_loss_run = 0
        with torch.no_grad():
            for i, data in enumerate(valloader, 0):
                (anchors, positives, negatives),(l1, l2, l3) = data
                anchors, positives, negatives = anchors.to(device), positives.to(device), negatives.to(device)

                optimizer.zero_grad()  # zero the parameter gradient
                pos_prob = model(anchors, positives)
                neg_prob = model(anchors, negatives)

                loss = loss_fn(pos_prob, neg_prob)

                this_batch_size = len(anchors)
                val_loss_run = val_loss_run + loss.item() * this_batch_size  # loss is averaged, multiplying by n to undo and average later.

        val_loss = val_loss_run / num_val_samples
        all_loss_val.append(val_loss)

        if val_loss < best_val:  # If our model has improved
            not_better_streak = 0
            best_val = val_loss
        else:  # if the model has not improved
            not_better_streak = not_better_streak + 1

        if prev_loss - val_loss<tol:
                not_better_streak_tol = not_better_streak_tol + 1
                #print("Early stopping - tol")
                #break
        else:
            not_better_streak_tol = 0

        prev_loss = val_loss

        if not_better_streak >= max_streak or not_better_streak_tol>= max_streak:
            print("Early stopping")
            break

    print("done")
    return all_loss_train, all_loss_val

def train_model(model, device, trainloader,Num_epochs, LEARNING_RATE, save_folder=None,max_streak = 25,tol=0.0000001):
    if save_folder != None:
        if not os.path.exists(save_folder):
            os.makedirs(save_folder)

    loss_fn = triplet_cross_entropy_loss(device)
    optimizer = optim.Adam(model.parameters(), lr=LEARNING_RATE)

    num_train_samples = len(trainloader.dataset)

    all_loss_train = []

    best_train_loss = math.inf
    prev_loss = math.inf
    not_better_streak = 0
    not_better_streak_tol =0

    for epoch in range(0, Num_epochs):
        #Train
        print(epoch)
        model.train()

        train_loss_run = 0
        for i, data in enumerate(trainloader, 0):
            (anchors, positives, negatives),(l1, l2, l3) = data
            anchors, positives, negatives = anchors.to(device), positives.to(device), negatives.to(device)

            optimizer.zero_grad()  # zero the parameter gradient
            pos_prob = model(anchors, positives)
            neg_prob = model(anchors, negatives)

            loss = loss_fn(pos_prob, neg_prob)
            loss.backward()
            optimizer.step()

            this_batch_size = len(anchors)

            train_loss_run = train_loss_run + loss.item() * this_batch_size  # loss is averaged, multiplying by n to undo and average later.

        train_loss = train_loss_run / num_train_samples
        all_loss_train.append(train_loss)

        if train_loss < best_train_loss:  # If our model has improved
            not_better_streak = 0
            best_train_loss = train_loss
        else:  # if the model has not improved
            not_better_streak = not_better_streak + 1

        if prev_loss - train_loss<tol:
                not_better_streak_tol = not_better_streak_tol + 1
                #print("Early stopping - tol")
                #break
        else:
            not_better_streak_tol = 0

        prev_loss = train_loss

        if not_better_streak >= max_streak or not_better_streak_tol>= max_streak:
            print("Early stopping")
            break

    print("done")
    return all_loss_train

def evaluate_model(model, device, trainloader,save_folder=None):
    num_train_samples = len(trainloader.dataset)
    model.eval()


    true_positives = 0
    true_negatives = 0

    with torch.no_grad():
        for i, data in enumerate(trainloader, 0):
            (anchors, positives, negatives),(l1, l2, l3) = data
            anchors, positives, negatives = anchors.to(device), positives.to(device), negatives.to(device)
            pos_prob = model(anchors, positives).detach().cpu().numpy()
            neg_prob = model(anchors, negatives).detach().cpu().numpy()

            true_positives = true_positives + np.sum(pos_prob>=.5)
            true_negatives = true_negatives + np.sum(neg_prob<.5)
        
    false_negative = num_train_samples - true_positives
    false_positive = num_train_samples - true_negatives

    print_confusion_matrix(true_positives, true_negatives, false_negative, false_positive)
    return true_positives, true_negatives, false_negative, false_positive


def print_confusion_matrix(true_positives, true_negatives, false_negative, false_positive):
    headers = ["Predicted Same","Predicted Different"]
    table = [["Actual Same",true_positives,false_negative],
    ["Actural Different",false_positive,true_negatives]]
    print(tabulate(table, headers, tablefmt="grid"))


# %%


os.environ['CUDA_VISIBLE_DEVICES']= ''
device = torch.device("cpu")#torch.device("cpu")

mnist_train = datasets.MNIST('/data/ribeiro/torchvision_datasets', train=True, download=True)
mnist_test = datasets.MNIST('/data/ribeiro/torchvision_datasets', train=False, download=True)

train_indeces = (mnist_train.train_labels == 1) | (mnist_train.train_labels == 0)
test_indeces = (mnist_test.test_labels == 1) | (mnist_test.test_labels == 0)
train_dataset = TripletMNIST(mnist_train.data.float().view(mnist_train.data.shape[0],-1)[train_indeces,:],mnist_train.train_labels[train_indeces],True)
test_dataset = TripletMNIST(mnist_test.data.float().view(mnist_test.data.shape[0],-1)[test_indeces,:],mnist_test.test_labels[test_indeces],True)


#train_dataset = TripletMNIST(mnist_train.data.float().view(mnist_train.data.shape[0],-1),mnist_train.train_labels,True)
#test_dataset = TripletMNIST(mnist_test.data.float().view(mnist_test.data.shape[0],-1),mnist_test.test_labels,True)


model = LogisticRegression_on_Diff(784)
model = model.to(device)

trainloader = torch.utils.data.DataLoader(train_dataset, batch_size=64)
testloader = torch.utils.data.DataLoader(test_dataset, batch_size=20000)

Num_epochs = 200
LEARNING_RATE = 0.0001
all_loss_train= train_model(model, device, trainloader, Num_epochs, LEARNING_RATE, save_folder=None,max_streak = 5,tol=0.000001)


plt.figure()
plt.plot(all_loss_train)
plt.show()

#%% Evaluate
evaluate_model(model, device, trainloader,save_folder=None)

# %%
def matching_alg_greedy(model, data, labels, threshold=10):
    
    matched_indeces = []
    matched_labels = []

    for data_idx, cur_data in enumerate(data): #Loop over data. cur_data is the current datapoint we want to categorize
        print(data_idx/len(data))
        
        matched = False
        for matched_units_idx, matched_units in enumerate(matched_indeces): #Loop over categories - matched_units is the current category of datapoints
            if matched == True:
                break
            for this_unit_idx, compare_this_unit_idx in enumerate(matched_units): #Loop over items in the category
                
                if model(cur_data,data[compare_this_unit_idx]).item() > threshold:        #If the current datapoint looks like an item in the category, assign it to the category
                    matched_units.append(data_idx)
                    matched_labels[matched_units_idx].append(labels[data_idx])      
                    matched = True
                    break
        
        if matched == False: #If the units never look like an item in the category, create a new category.
            matched_indeces.append([data_idx])
            matched_labels.append([labels[data_idx]])

    
    return matched_indeces, matched_labels


matched_indeces, matched_labels = matching_alg_greedy(model,mnist_test.data.float().view(mnist_test.data.shape[0],-1)[test_indeces,:],mnist_test.test_labels[test_indeces],threshold=.99)

print(matched_labels)

# %%
for i in matched_labels:
    print(len(i))

print("done")

#%% Test functions
'''os.environ['CUDA_VISIBLE_DEVICES'] = ''
device = torch.device("cpu")
model = LogisticRegression_on_Diff(784)
loss_fn = triplet_cross_entropy_loss(device)

(img1, img2, img3),(l1,l2,l3) = train_dataset[0]

pos_prob = model(img1, img2)
neg_prob = model(img1, img3)

loss = loss_fn(pos_prob,neg_prob)

#%%
trainloader = torch.utils.data.DataLoader(train_dataset, batch_size=5)

for i, data in enumerate(trainloader, 0):
    print(i)
    (anchors, positives, negatives),(l1,l2,l3) = data
    pos_prob = model(anchors, positives)
    neg_prob = model(anchors, negatives)

    loss = loss_fn(pos_prob,neg_prob)
    break

# %%
a = TripletMNIST(mnist_train.data,mnist_train.train_labels,True)

(img1, img2, img3),(l1,l2,l3) = a[0]

fig, axes = plt.subplots(1,3)
axes[0].imshow(img1)
axes[0].set_title(l1.item())
axes[1].imshow(img2)
axes[1].set_title(l2.item())
axes[2].imshow(img3)
axes[2].set_title(l3.item())

plt.show()'''