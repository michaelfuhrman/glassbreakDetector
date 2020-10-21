%% Testing

% Load audio and labels
audio_path  = expandVarPath('../../../../data/');
[x_m,Fs]      = audioread([audio_path 'GB_TestClip_v1_16000_mixed_included.wav']);
t_m           = 0:1/Fs:(length(x_m)-1)/Fs;
label_list_m  = csvread([audio_path 'GB_TestClip_v1_label_mixed_included.csv']);
lab_m = List2Detections(t_m,label_list_m);

[x_t,Fs]      = audioread([audio_path 'GB_TestClip_Training_v1_16000.wav']);
t_t           = 0:1/Fs:(length(x_t)-1)/Fs;
label_list_t  = csvread([audio_path 'GB_TestClip_Training_v1_label.csv']);
lab_t = List2Detections(t_t,label_list_t);

% Create audio variables
x           = [x_m; x_t]; % *10^(-8/20); % Was using -8dB, but mic recordings seem to indicate we shouldn't have it
t           = 0:1/Fs:(length(x)-1)/Fs;
lab         = [lab_m lab_t];
T0          = 1;
x(t<T0)     = 0;
sig_in      = [x -x];




