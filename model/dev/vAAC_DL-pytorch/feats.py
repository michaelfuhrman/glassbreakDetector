import os 
import csv
import pdb
import random
import librosa
import numpy as np

def List2Detection(t,DetList):
    t = np.array(t)
    Detections = np.zeros((len(t)),dtype=int)
    if sum(map(sum, DetList)) > 0:
        for i in range(len(DetList)):
            nD = np.where((t >= DetList[i][0]) & (t<= DetList[i][1]))[0]
            Detections[nD] = 1
    return Detections

datapath = '../../../data'

data, rate = librosa.load(os.path.join(datapath,'GB_TestClip_v1_16000.wav'))
t = [x/rate for x in range(len(data))]

with open(os.path.join(datapath,'GB_TestClip_v1_label.csv'), newline='') as csvfile:
    label_file = csv.reader(csvfile, delimiter=',')
    DetList = []
    for row in label_file:
        row =[float(val) for val in row]
        DetList.append(row)
orig_labels = List2Detection(t,DetList) 

clip_duration = len(data)/rate
data_pt_duration = 0.05 ### Time Period of each data point in seconds 

window_width = rate*data_pt_duration
num_data_pts = round(clip_duration/data_pt_duration)
feats = []
labels = []
for i in range(num_data_pts):
    start = int(i*window_width)
    end = int((i+1)*window_width) if i<num_data_pts-1 else -1
    mfcc_feature = librosa.feature.mfcc(data[start:end], rate, n_mfcc=50).T.flatten()[:, np.newaxis].T
    label = orig_labels[start:end][-1]
    if i == 0:
        feat_size = len(mfcc_feature[0])
    if len(mfcc_feature[0]) == feat_size:
        feats.append(mfcc_feature)
        labels.append(label)
feats = np.vstack(feats)

assert(len(feats) == len(labels))

dist_rate = 0.25 #75% data for training and 25% for validation
num_val_pts = round(dist_rate*len(labels))
val_idx = random.sample(range(len(labels)),num_val_pts)

train_feats = []
train_labels = []
val_feats = []
val_labels = []
for i in range(len(labels)):
    if i in val_idx:
        val_feats.append(feats[i])
        val_labels.append(labels[i])
    else:
        train_feats.append(feats[i])
        train_labels.append(labels[i])

######## Save features and labels ########

np.save('train_feats.npy', train_feats)
np.save('train_labels.npy', train_labels)
np.save('val_feats.npy', val_feats)
np.save('val_labels.npy', val_labels)
