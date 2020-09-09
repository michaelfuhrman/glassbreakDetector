% Run this to train and create new neural net models in nnThud.mat and nnZCR.mat

disp('Reading mixed GB_TestClip_v1_16000.wav')
audioPath = expandVarPath('%AspBox%/engr/sig_proc/Projects/External/Infineon/IAS_glassbreak/mharish/michael_gb_code/');
% [x,Fs]=audioread('GB_TestClip_v1_16000.wav');
[x,Fs]=audioread([audioPath 'GB_TestClip_v1_16000_mixed_included.wav']);
t=(0:length(x)-1)/Fs;

disp(['Fs = ' num2str(Fs)])
disp(['Signal length = ' num2str(t(end)) ' seconds'])

% labels=csvread('GB_TestClip_v1_label.csv');
labels=csvread([audioPath 'GB_TestClip_v1_label_mixed_included.csv']);
l=List2Detections(t,labels);
disp(['Number of labeled glass breaks: ' num2str(length(labels))])
ramp_operator_setup;

%% detector
gain=1;
% For declaring glass break

Chain = gb_model_2020_09_09(ramp,gain);
y=Chain(t,x);
iterations=8000; %5000 before
gap=0;
acceptableLatency = .05;
[nnThud,event_indexThud, noise_indexThud]=gb_testClip_train(t,y,l,acceptableLatency,gap,iterations);
nnThud = nnScrub(nnThud); % remove gradients, etc so file isn't so bit
save('nnThud.mat', 'nnThud');

% Don't collect training data until 50msec passed label
gap=0.05;
acceptableLatency = .2;
[nnZCR,event_indexZCR, noise_indexZCR]=gb_testClip_train(t,y,l,acceptableLatency,gap,iterations);
nnZCR = nnScrub(nnZCR); % remove gradients, etc so file isn't so bit
save('nnZCR.mat', 'nnZCR');
