%% Testing

% Load audio and labels
audio_path  = expandVarPath('../../../../data/');
[x,Fs]      = audioread([audio_path 'GB_TestClip_Short_v1_16000.wav']);
label_list  = csvread([audio_path 'GB_TestClip_Short_v1_label.csv']);

% Create audio variables
x           = x; % *10^(-8/20); Used -8dB on the initial trim, but after reviewing mic recordings don't think we should have it--because it's a differential mic?
t           = 0:1/Fs:(length(x)-1)/Fs;
lab         = List2Detections(t,label_list);
T0          = 1;
x(t<T0)     = 0;
sig_in      = [x -x];

% Save into trim routine variables
sig_trim.x       = x;
sig_trim.lab     = lab;
sig_trim.t       = t;
sig_trim.Fs      = Fs;
sig_trim.T0      = T0;
sig_trim.sig_in  = sig_in;

sig_test  = sig_trim;
sig_train = sig_trim;

