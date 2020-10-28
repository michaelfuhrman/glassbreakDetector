import os
import pdb
import torch
import numpy as np
import torch.nn as nn
from torch.utils import data
import torch.nn.functional as F
import matplotlib.pyplot as plt
from torchvision import transforms
from sklearn.metrics import confusion_matrix
from torch.utils.data import DataLoader, Dataset

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(device)

class LoadData():
    def __init__(self,feats_path,labels_path,training=True):
        super(LoadData).__init__()
        self.feats = np.load(feats_path)
        self.labels = np.load(labels_path)
        self.training = training

    def __getitem__(self,index):
        feature = self.feats[index]
        feature = np.expand_dims(feature, axis=0)
        label = self.labels[index]
        # label = torch.as_tensor(label)
        return feature,label
    
    def __len__(self):
        return len(self.feats)

class Network(nn.Module):
    def __init__(self,feat_size, num_classes=2):
        super(Network,self).__init__()
        self.num_classes = num_classes
        self.lstm1 = nn.LSTM(feat_size,feat_size)
        self.dropout1 = nn.Dropout(0.5)
        self.lstm2 = nn.LSTM(feat_size,feat_size)
        self.dropout2 = nn.Dropout(0.5)
        self.fc = nn.Linear(feat_size,num_classes)
    
    def forward(self,x):
        x, (_, _) = self.lstm1(x)
        x = self.dropout1(x)
        x, (_, _) = self.lstm2(x)
        x = self.dropout2(x)
        x = self.fc(x)
        return x.squeeze(1)

def train(model, train_loader, val_loader, epochs):
    best_val = 0
    for epoch in range(epochs):
        print("Epoch: ",epoch)
        TN, FP, FN, TP = 0, 0, 0, 0
        avg_loss = 0
        acc = 0
        model.train()
        for batch_num, (feats,target) in enumerate(train_loader):
            output = model(feats)
            loss = criterion(output,target)
            optimizer.zero_grad()
            loss.backward()
            optimizer.step()

            avg_loss += loss.item()

            if batch_num % 5 == 4:
                print("Batch {}, loss = {}".format(batch_num+1, loss))

            pred_prob = F.softmax(output, dim=1)
            _, pred = torch.max(pred_prob,1)
            acc += torch.sum(torch.eq(pred,target)).item()/len(target)
            tn, fp, fn, tp = confusion_matrix(target,pred, labels=[0,1]).ravel()
            TP += tp
            TN += tn
            FP += fp
            FN += fn     
        FAR = FP/(FP+TN)
        TPR = TP/(TP+FN)

        train_FAR.append(FAR)
        train_tpr.append(TPR)
        train_loss.append(avg_loss/(batch_num+1))
        train_acc.append(acc/(batch_num+1))
        print("Training Loss = {}, Accuracy = {}".format(avg_loss/(batch_num+1),acc/(batch_num+1)))

        valid_loss, valid_acc, valid_TPR, valid_FAR = validate(model, val_loader)
        print("Validation Loss = {}, FAR = {}".format(valid_loss,FAR))

        val_FAR.append(valid_FAR)
        val_tpr.append(valid_TPR)
        val_loss.append(valid_loss)
        val_acc.append(valid_acc)

        if acc > best_val:
            best_val = acc
            torch.save({
                'model_state_dict': model.state_dict(),
                'optimizer_state_dict': optimizer.state_dict(),
                'best_val_acc': best_val,
                'Epoch': epoch
            }, 'saved_models/glassbreak_50ms_50feat.pt')

def validate(model, val_loader):
    model.eval()
    TN, FP, FN, TP = 0, 0, 0, 0
    avg_loss = 0
    acc = 0
    for batch_num, (feats,target) in enumerate(val_loader):
        feats, target = feats.to(device), target.to(device)
        output = model(feats)
        loss = criterion(output,target)
        avg_loss += loss.item()

        pred_prob = F.softmax(output, dim=1)
        _, pred = torch.max(pred_prob,1)
        acc += torch.sum(torch.eq(pred,target)).item()/len(target)
        tn, fp, fn, tp = confusion_matrix(target,pred, labels=[0,1]).ravel()
        TP += tp
        TN += tn
        FP += fp
        FN += fn

    avg_acc = acc/(batch_num+1)
    avg_loss = avg_loss/(batch_num+1)
    FAR = FP/(FP+TN)
    TPR = TP/(TP+FN)
    return avg_loss, avg_acc, TPR, FAR


######## Main Code ###############
train_feats_path = 'train_feats.npy'
train_labels_path = 'train_labels.npy'
val_feats_path = 'val_feats.npy'
val_labels_path = 'val_labels.npy'
num_epochs = 100

######### Get feature size #########
train_feats = np.load(train_feats_path)
feat_size = len(train_feats[0])
print("No of MFCC features = ",feat_size)
del train_feats

#### FAR ####
train_FAR = []
val_FAR = []
#### Loss ####
train_loss = []
val_loss = []
#### Accuracy ####
train_acc = []
val_acc = []
#### TPR ####
train_tpr = []
val_tpr = []

######### Train Dataloader ###########
train_dataset = LoadData(train_feats_path, train_labels_path, training = True)
train_dataloader = data.DataLoader(train_dataset, shuffle=True, batch_size=128, num_workers=16, pin_memory=True)

######### Validation Dataloader ############
val_dataset = LoadData(val_feats_path, val_labels_path, training = False)
val_dataloader = data.DataLoader(val_dataset, shuffle=False, batch_size=64, num_workers=16, pin_memory=True)

######### Model Initialisation ###########
model = Network(feat_size)
model = nn.DataParallel(model).to(device)

######### Loss Function ###########
weights = [0.25, 1.0]
class_weights = torch.FloatTensor(weights).to(device)
criterion = nn.CrossEntropyLoss(weight=class_weights)

######### Optimizer ############
optimizer = torch.optim.Adam(model.parameters(), lr=0.001)

##### Model Training #####
train(model, train_dataloader, val_dataloader, num_epochs)

####### Plot Curves ######
fig, axs = plt.subplots(2, 2,figsize=(10, 10))
x = np.arange(1,num_epochs+1)

####### Loss Plot #######
axs[0,0].plot(x,train_loss, label = 'Training Loss')
axs[0,0].plot(x,val_loss, label = 'Validation Loss')
axs[0,0].set_xlabel('Epochs')
axs[0,0].set_ylabel('Loss')
axs[0,0].set_title('Loss Plot')
axs[0,0].legend()

####### Accuracy Plot #######
axs[0,1].plot(x,train_acc, label = 'Training Accuracy')
axs[0,1].plot(x,val_acc, label = 'Validation Accuracy')
axs[0,1].set_xlabel('Epochs')
axs[0,1].set_ylabel('Accuracy')
axs[0,1].set_title('Accuracy Plot')
axs[0,1].legend()

####### TPR Plot #######
axs[1,0].plot(x,train_tpr, label = 'Training TPR')
axs[1,0].plot(x,val_tpr, label = 'Validation TPR')
axs[1,0].set_xlabel('Epochs')
axs[1,0].set_ylabel('TPR')
axs[1,0].set_title('TPR Plot')
axs[1,0].legend()

####### FAR Plot #######
axs[1,1].plot(x,train_FAR, label = 'Training FAR')
axs[1,1].plot(x,val_FAR, label = 'Validation FAR')
axs[1,1].set_xlabel('Epochs')
axs[1,1].set_ylabel('FAR')
axs[1,1].set_title('FAR Plot')
axs[1,1].legend()

fig.savefig('metrics_plot_50ms_50feat.jpg')







    


        

