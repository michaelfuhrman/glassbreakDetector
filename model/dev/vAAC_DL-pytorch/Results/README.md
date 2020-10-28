
# Result 9: New features concatenated with MFCC features
T - Duration of each clip over which features are extracted  
N - Number of MFCC features for each clip  
Fs = 16kHz

Trained both 1 and 2 layer model with data in sequential format where the features are concatenation of MFCC of current window and average of the MFCC of current and last 3 windows. It didn't improve the performance in either of the 2 cases.  
(Note: The `get_features` function in `glassbreak_test.py` must be same as the one in `feats_sequential.py`)

You can find the evaluation result for 1 Layer model [here](Sept-28-2020/README.md).  
You can find the evaluation result for 2 Layer model [here](Sept-29-2020/README.md).

# Result 8: Reducing the network to 1 LSTM layer
T - Duration of each clip over which features are extracted  
N - Number of MFCC features for each clip  
Fs = 16kHz

Changed the network in `glassbreak.py` and `glassbreak_test.py` to the following and trained the model with the data in sequential format
```
class Network(nn.Module):
    def __init__(self,feat_size, num_classes=2):
        super(Network,self).__init__()
        self.num_classes = num_classes
        self.lstm1 = nn.LSTM(feat_size,feat_size//2)
        self.dropout1 = nn.Dropout(0.5)
        self.fc = nn.Linear(feat_size//2,num_classes)
    
    def forward(self,x):
        x, (_, _) = self.lstm1(x)
        x = self.dropout1(x)
        x = self.fc(x)
        return x.squeeze(1)
```
There was a small improvement in the overall performance of the model wrt FAR. The number of network parameters is less than half of that of the original network. This shows that deeper network doesn't mean better results. It's possible that the network is able to learn well with just 1 LSTM layer as the data isn't very complex.
The model was also trained on sliding window data. The performance slightly reduced wrt to FAR but has much lesser latency.  
(Note: The `get_features` function in `glassbreak_test.py` must be same as the one in `feats_sequential.py`)

You can find the evaluation result for model trained in sequential format [here](Sept-24-2020/README.md).  
You can find the evaluation result for model trained with sliding window data [here](Sept-25-2020/README.md).

# Result 7: Tapering the network
T - Duration of each clip over which features are extracted  
N - Number of MFCC features for each clip  
Fs = 16kHz

Changed the network in `glassbreak.py` and `glassbreak_test.py` to the following and trained the model with the data in sequential format
```
class Network(nn.Module):
    def __init__(self,feat_size, num_classes=2):
        super(Network,self).__init__()
        self.num_classes = num_classes
        self.lstm1 = nn.LSTM(feat_size,feat_size//2)
        self.dropout1 = nn.Dropout(0.5)
        self.lstm2 = nn.LSTM(feat_size//2,feat_size//4)
        self.dropout2 = nn.Dropout(0.5)
        self.fc = nn.Linear(feat_size//4,num_classes)
    
    def forward(self,x):
        x, (_, _) = self.lstm1(x)
        x = self.dropout1(x)
        x, (_, _) = self.lstm2(x)
        x = self.dropout2(x)
        x = self.fc(x)
        return x.squeeze(1)
```
There was no improvement in the performance compared to previous results. But since there was no decline in the performance we can see that the network performs just as well with half the number of parameters. The same experiment was repeated by changing the cross entropy loss weight from \[0.25,1] to \[0.5,1] and no significant improvement was observed.  
(Note: The `get_features` function in `glassbreak_test.py` must be same as the one in `feats_sequential.py`)

You can find the evaluation result [here](Sept-22-2020/README.md).

# Result 6: Sliding window experiment
T - Duration of each clip over which features are extracted  
N - Number of MFCC features for each clip  
Fs = 16kHz

Generated features by sliding the window by half the window width. Eg: I window_width = 800 samples then slide the window by 400 samples. 
The goal of using this technique was to increase the amount of data  used to train the model and give it more contextual information. The model was trained by feeding the data in sequential format. There was not much improvement in the performance.
The model was also trained by setting the value of N = 100 for different values of T. There was no improvement in the performance in that case as well.
(Note: The `get_features` function in `glassbreak_test.py` must be same as the one in `feats_sliding.py`)

You can find the evaluation result [here](Sept-21-2020/README.md).

# Result 5: Same number of features for audio clip of different length
T - Duration of each clip over which features are extracted  
N - Number of MFCC features for each clip  
Fs = 16kHz

Trained the model with same value of N for different value of T. This was achieved by changing the value of `hop_length` setting in `librosa.feature.mfcc`. 
Eg: `mfcc_feature = librosa.feature.mfcc(data, rate, n_mfcc=50, hop_length = 512*2)` to get N = 100 for T = 100ms.  
The explanation of how length of audio changes the number of features generated can be found [here](https://stackoverflow.com/questions/37963042/python-librosa-what-is-the-default-frame-size-used-to-compute-the-mfcc-feature).  
The documentation for `librosa.feature.mfcc` can be found [here](http://man.hubwiz.com/docset/LibROSA.docset/Contents/Resources/Documents/generated/librosa.feature.mfcc.html).  
In order to achieve a value of N = 100 following hop_length values were used.
Length of audio clip | T = 50ms | T = 100ms | T = 150ms | T = 200ms
:-------------------:|:--------:|:---------:|:---------:|:---------:
hop_length | 512 | 512\*2 | 512\*3 | 512\*4  

(Note: The `get_features` function in `glassbreak_test.py` must be same as the one in `feats_sequential.py`)
There was not much change in the performance.

You can find the evaluation result [here](Sept-19-2020/README.md).

# Result 4: Changed sampling rate to 16kHz
T - Duration of each clip over which features are extracted  
N - Number of MFCC features for each clip  
Fs = 16kHz

Changed the sampling frequency to 16kHz and trained model for T = 50ms, T = 100ms, T = 150ms and T = 200ms. The data was again fed in the order in which the data occurs in the original audio file and the model was trained. Here we notice that the number of features reduced for different values of T compared to that for 22KHz. The results were similar to the one before.  
(Note: The `get_features` function in `glassbreak_test.py` must be same as the one in `feats_sequential.py`)

You can find the evaluation result [here](Sept-18-2020/README.md).

 
# Result 3: Feed the data to the model in sequential format
T - Duration of each clip over which features are extracted  
N - Number of MFCC features for each clip  
Fs = 22kHz (librosa default- did not notice it until later)

Until now the data was shuffled before it was fed to the model for training. Now we maintain the order in which the data occurs in the original audio file and train the model. Trained the model only for T = 50ms, T = 100ms and T = 150ms gave the best results in the previous experiment. Here we also noticed that as the FAR decreases so does the TPR.  
(Note: The `get_features` function in `glassbreak_test.py` must be same as the one in `feats_sequential.py`).

You can find the evaluation result [here](Sept-17-2020/README.md).

 
# Result 2: Experiment with different time duration of audio clips
T - Duration of each clip over which features are extracted  
N - Number of MFCC features for each clip  
Fs = 22kHz (librosa default- did not notice it until later)

Experimented with different duration of the audio clip ie., value of T. T = 50ms, T = 100ms and T = 150ms gave the best results.  
Trained the model for only 100 epochs as it might start overfitting beyond that.

You can find the evaluation result [here](Sept-16-2020/README.md).

 
# Result 1: Experiment with different number of MFCC features
T - Duration of each clip over which features are extracted  
N - Number of MFCC features for each clip  
Fs = 22kHz (librosa default- did not notice it until later)

Experimented with different values of T and N. We can see from the figures below, higher the number of features per data point better the results. Hence tested the model on the test audio clip for N = 50(for 10ms and 20 ms) and N = 150 (for 50ms as MFCC function in librosa generated 3x50 features for a 50ms clip). 

You can find the evaluation result [here](Sept-15-2020/README.md).

