# %%

import numpy 
import scipy.io
from matching_functions import *

features_file = "maeve_test.mat"

S = scipy.io.loadmat(features_file)
all_average_waveform_PC = S['S'][0][0][0]
all_isi_hist = S['S'][0][0][1]
unit_groups = S['S'][0][0][2]
plx_source_file = np.transpose(np.expand_dims(S['S'][0][0][3],0))
unit_number = S['S'][0][0][4]


# %%
os.environ['CUDA_VISIBLE_DEVICES']= ''
device = torch.device("cpu")#torch.device("cpu")

features = np.concatenate((all_average_waveform_PC,all_isi_hist),1)
normed_features = (features - np.mean(features,0))/np.std(features,0)


model = LogisticRegression_on_Diff(features.shape[1])
model = model.to(device)

dataset = TripletDataset(torch.FloatTensor(normed_features),torch.IntTensor(unit_groups),True)



loader = torch.utils.data.DataLoader(dataset, batch_size=64)

Num_epochs = 1000
LEARNING_RATE = 0.001
all_loss_train= train_model(model, device, loader, Num_epochs, LEARNING_RATE, save_folder=None,max_streak = 25,tol=0.000001)


plt.figure()
plt.plot(all_loss_train)
plt.show()

#%% Evaluate
evaluate_model(model, device, loader,save_folder=None)

# %%
from collections import Counter

print(Counter(unit_groups.flatten()).keys())
print(Counter(unit_groups.flatten()).values())

# %%


for this_unit in list(set(unit_groups.flatten())):
    this_features = features[unit_groups.flatten()==this_unit,:]
    
    print(plx_source_file[unit_groups.flatten()==this_unit][0])

    this_labels = unit_number[unit_groups.flatten()==this_unit,:]

    matched_indeces, matched_labels = matching_alg_greedy(model,torch.FloatTensor(this_features),this_labels,threshold=.99)

    print("matched units")
    print(matched_labels)

#print(matched_labels)


# %%
