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

def get_features(data, rate, orig_labels, data_duration, num_feat, sliding_ratio):
    clip_duration = len(data)/rate
    data_pt_duration = data_duration
    window_width = rate*data_pt_duration
    num_data_pts = round(clip_duration/(data_pt_duration*sliding_ratio)) - (int(1/sliding_ratio) - 1)

    feats = []
    labels = []
    for i in range(num_data_pts):
        if i == 0:
            start = 0
            end = int(window_width)
        else:
            start = int(i*window_width*sliding_ratio)
            end = int(start+window_width) if i<num_data_pts else -1
        mfcc_feature = librosa.feature.mfcc(data[start:end], rate, n_mfcc=num_feat).T.flatten()[:, np.newaxis].T
        label = orig_labels[start:end][-1]
        if i == 0:
            feat_size = len(mfcc_feature[0])
        if len(mfcc_feature[0]) == feat_size:
            feats.append(mfcc_feature)
            labels.append(label)
    feats = np.vstack(feats)

    assert(len(feats) == len(labels))
    return feats, labels

######## Duration and feature settings #########
data_duration = 0.2 ### Time Period of each data point in seconds 
num_feat = 50 #### n_mfcc setting in librosa mfcc function
slide_ratio = 0.5 ### The ratio determines by how much you want to slide the window wrt the window width. 0.5 means half the width of window.
datapath = '../../../data'

############# Preprocessing for Training data ###########
data, rate = librosa.load(os.path.join(datapath,'GB_TestClip_v1_16000.wav'),sr=None)
t = [x/rate for x in range(len(data))]

with open(os.path.join(datapath,'GB_TestClip_v1_label.csv'), newline='') as csvfile:
    label_file = csv.reader(csvfile, delimiter=',')
    DetList = []
    for row in label_file:
        row =[float(val) for val in row]
        DetList.append(row)
orig_labels = List2Detection(t,DetList) 

train_feats, train_labels = get_features(data, rate, orig_labels, data_duration, num_feat, slide_ratio)
print("Training data done !!!")

############## Preprocessing for validation data #############
data, rate = librosa.load(os.path.join(datapath,'GB_TestClip_Short_v1_16000.wav'),sr=None)
t = [x/rate for x in range(len(data))]

with open(os.path.join(datapath,'GB_TestClip_Short_v1_label.csv'), newline='') as csvfile:
    label_file = csv.reader(csvfile, delimiter=',')
    DetList = []
    for row in label_file:
        row =[float(val) for val in row]
        DetList.append(row)
orig_labels = List2Detection(t,DetList) 

val_feats, val_labels = get_features(data, rate, orig_labels, data_duration, num_feat, slide_ratio)
print("Validation data done !!!")

######## Save features and labels ########
np.save('train_feats.npy', train_feats)
np.save('train_labels.npy', train_labels)
np.save('val_feats.npy', val_feats)
np.save('val_labels.npy', val_labels)