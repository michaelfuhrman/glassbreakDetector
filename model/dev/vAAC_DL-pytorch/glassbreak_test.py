import os
import csv
import pdb
import torch
import random
import librosa
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

def List2Detection(t,DetList):
    t = np.array(t)
    Detections = np.zeros((len(t)),dtype=int)
    if sum(map(sum, DetList)) > 0:
        for i in range(len(DetList)):
            nD = np.where((t >= DetList[i][0]) & (t<= DetList[i][1]))[0]
            Detections[nD] = 1
    return Detections

def get_features(data, rate, orig_labels, data_duration, feat_size):
    clip_duration = len(data)/rate
    data_pt_duration = data_duration
    window_width = rate*data_pt_duration
    num_data_pts = round(clip_duration/data_pt_duration)
    feats = []
    labels = []
    plot_idx = []
    for i in range(num_data_pts):
        start = int(i*window_width)
        end = int((i+1)*window_width) if i<num_data_pts-1 else -1
        end_val = -1 if end == -1 else end-1
        ####### extract features and labels #######
        mfcc_feature = librosa.feature.mfcc(data[start:end], rate, n_mfcc=feat_size).T.flatten()[:, np.newaxis].T
        label = orig_labels[start:end][-1]
        if i == 0:
            feat_sz = len(mfcc_feature[0])
        if len(mfcc_feature[0]) == feat_sz:
            feats.append(mfcc_feature)
            labels.append(label)
            plot_idx.append(end_val)
    feats = np.vstack(feats)
    return feats, labels, plot_idx

class LoadData():
    def __init__(self,feats,labels,training=True):
        super(LoadData).__init__()
        self.feats = feats
        self.labels = labels
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

def validate(model, val_loader):
    model.eval()
    TN, FP, FN, TP = 0, 0, 0, 0
    pred_list = []
    avg_loss = 0
    acc = 0
    for batch_num, (feats,target) in enumerate(val_loader):
        feats, target = feats.to(device), target.to(device)
        output = model(feats)
        loss = criterion(output,target)
        avg_loss += loss.item()

        pred_prob = F.softmax(output, dim=1)
        _, pred = torch.max(pred_prob,1)
        for val in pred:
            pred_list.append(val)
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
    return avg_loss, avg_acc, TPR, FAR, pred_list

######### Test data pre processing #########
datapath = '../../../data'

audio, rate = librosa.load(os.path.join(datapath,'GB_TestClip_Training_v1_16000.wav'))
t = [x/rate for x in range(len(audio))]

with open(os.path.join(datapath,'GB_TestClip_Training_v1_label.csv'), newline='') as csvfile:
    label_file = csv.reader(csvfile, delimiter=',')
    DetList = []
    for row in label_file:
        row =[float(val) for val in row]
        DetList.append(row)
orig_labels = List2Detection(t,DetList) 

data_duration = 0.05 ### Time Period of each data point in seconds
num_feat = 50 #### n_mfcc setting in librosa mfcc function

features, labels, plot_idx = get_features(audio, rate, orig_labels, data_duration, num_feat)
feat_size = len(features[0])

######### Test Dataloader ############
test_dataset = LoadData(features, labels, training = False)
test_dataloader = data.DataLoader(test_dataset, shuffle=False, batch_size=64, num_workers=16, pin_memory=True)

######### Model Initialisation ###########
model = Network(feat_size)
model = nn.DataParallel(model).to(device)

######### Load saved model from checkpoint ##########
checkpoint = torch.load('saved_models/glassbreak_50ms_50feat.pt', map_location=torch.device('cpu'))

model.load_state_dict(checkpoint['model_state_dict'])

######### Loss Function ###########
weights = [0.25, 1.0]
class_weights = torch.FloatTensor(weights).to(device)
criterion = nn.CrossEntropyLoss(weight=class_weights)

######### Test on the data #########
loss, acc, TPR, FAR, pred = validate(model, test_dataloader)
print('Loss = {}, Accuracy = {}'.format(loss,acc))
print('TPR = {}, FAR = {}'.format(TPR, FAR))

######### Get label and pred in format for plotting ########
plot_label = np.zeros((len(t)))
plot_pred = np.zeros((len(t)))
for i,idx in enumerate(plot_idx):
    plot_label[idx] = labels[i]*0.8
    plot_pred[idx] = pred[i]

######### Plot results #########
fig, axs = plt.subplots(2, 1,figsize=(10, 10))

axs[0].plot(t,audio, label = 'Audio signal')
axs[0].plot(t,orig_labels, label = 'label')
axs[0].set_xlabel('Time')
axs[0].set_ylabel('Amplitude')
axs[0].legend()

axs[1].plot(t,plot_pred, label = 'Predicted Labels')
axs[1].plot(t,plot_label, label = 'Target Label')
axs[1].set_xlabel('Time')
axs[1].set_ylabel('Amplitude')
axs[1].legend()

fig.savefig('Result_plot_50ms_50feat.jpg')



