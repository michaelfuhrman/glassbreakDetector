# Goal
The goal of this pytorch implementation of a LSTM based network is to understand if our RAMP-friendly implementations are limited by the fact that they are RAMP-friendly or if they are limited by the fact that we are requiring such a low detection latency. We want to test the limits to which we can achieve low FAR and latency without any hardware/software restrictions. This will help us to get an idea of a value of latency and FAR that can be considered reasonable for the data at hand. 

# Background
This code is a pytorch imlementation of acoustic even detection network in the following repo: [LSTM Acoustic Event Classification](https://github.com/misskaseyann/acoustic-event-detection). Here the model is trained on NYU’s Urbansound8K dataset which contains 8,732 labeled sound excerpts lasting up to four seconds of urban sounds. There are ten classes total which are drawn from the urban sound taxonomy: air conditioner, car horn, children playing, dog bark, drilling, engine idling, gun shot, jackhammer, siren, and street music.

# Data
The audio files and their corresponding labels, used in training and testing the model can be found in `glassbreak/data` folder. The audio files used and training and testing the model are as follows:
1. `GB_TestClip_v1_16000.wav` is used for training and validating the model in the case where the data was shuffled. It is used only for training in the case where the model is trained with sequential order of data.
2. `GB_TestClip_Short_v1_16000.wav` is used only for validation in the case where the model is trained with sequential order of data.
3. `GB_TestClip_Training_v1_16000.wav` is used for testing the trained models.

# Contents
This folder contains the python/pytorch files used in feature extraction and training the LSTM based model for glassbreak detection. The files currently being used are as follows:
1. `feats.py` contains code that extracts features and labels from an audio file and it's corresponding label file. It divides the audio signal into smaller clips of desired window of time (10ms, 50ms etc) and extracts MFCC features for each of those clips. Label for each of the clips correspond to the label at the end of that window. The clips and corresponding labes are then randomly divided as training set(75%) and validation set(25%).
2. `glassbreak.py` contains the code that instantiates and trains the model for several epochs. The weights of model with the best validation accuracy are saved as a checkpoint to be used later for testing.
3. `glassbreak_test.py` contains the code that loads the saved checkpoint and tests the performace of the model on an unseen audio file. It contains the code for both feature extraction and testing.
4. `feats_sequential.py` extracts features in the same way as `feats.py` for 2 audio files. Features and labels corresponding to 1 audio file are used for training and the other is used for validation.
5. `feats_sliding.py` extracts features in the same way as `feats_sequential.py` but instead of extracting featues over non-overlapping windows, this slides the window by half the width of the window. 

# Current Status
Result folder contains all the details of the experiments performed and the results obtained for each of them. We found that more number of layers does not always mean better performance as we were able to achieve good results with 1 LSTM layer (compared to 2 LSTM layers). The one common trend that can also be noticed with the current results is that there is a trade-off between FAR and event based latency. When the latency is low, FAR is quite high and vice versa. The performance of the current best model is similar to the glassbreak model on RAMP.  

# Future Steps
The next steps for this project include:
1. Using techniques that will help in reducing the event based latency without increasing the FAR or reducing TPR.
2. Create a RAMP friendly version of the current model so that it can be tested further.
