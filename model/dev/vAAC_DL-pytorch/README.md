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
4. `feats_sequential.py` extracts features just like `feats.py` for 2 audio files. Features and labels corresponding to 1 audio file are used for training and the other is used for validation.

# Current Status
Result folder contains all the details of the experiments performed and the results obtained for each of them. The one common trend that can be noticed with the current results is that when the network achieves low FAR its TPR also reduces. Being able to achieve low FAR while maintaining a high TPR is a big hurdle that we need to cross.

# Future Steps
A few ideas that can be implemented in the future to get better performing network:
1. Use a sliding window over the audio signal and extract MFCC features over the windowed clips. This might help by providing more data and context.
2. Increasing/Decreasing the size of the network by adding/removing layers.
3. Training the model with features extracted using window of varying length in a single training set.
