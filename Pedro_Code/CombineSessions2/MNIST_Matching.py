# %%

print(9)

# %%
from matching_functions import *


os.environ['CUDA_VISIBLE_DEVICES']= ''
device = torch.device("cpu")#torch.device("cpu")

mnist_train = datasets.MNIST('/data2/ribeiro/torchvision_datasets', train=True, download=True)
mnist_test = datasets.MNIST('/data2/ribeiro/torchvision_datasets', train=False, download=True)

train_indeces = (mnist_train.train_labels == 1) | (mnist_train.train_labels == 0)
test_indeces = (mnist_test.test_labels == 1) | (mnist_test.test_labels == 0)
train_dataset = TripletDataset(mnist_train.data.float().view(mnist_train.data.shape[0],-1)[train_indeces,:],mnist_train.train_labels[train_indeces],True)
test_dataset = TripletDataset(mnist_test.data.float().view(mnist_test.data.shape[0],-1)[test_indeces,:],mnist_test.test_labels[test_indeces],True)


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