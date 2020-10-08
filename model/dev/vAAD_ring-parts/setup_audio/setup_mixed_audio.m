%% Testing

% Load audio and labels
audio_path  = expandVarPath('../../../../data/');
[x,Fs]      = audioread([audio_path 'GB_TestClip_v1_16000_mixed_included.wav']);
label_list  = csvread([audio_path 'GB_TestClip_v1_label_mixed_included.csv']);

% Create audio variables
x           = x;
t           = 0:1/Fs:(length(x)-1)/Fs;
lab         = List2Detections(t,label_list);
T0          = 1;
x(t<T0)     = 0;
sig_in      = [x -x];




