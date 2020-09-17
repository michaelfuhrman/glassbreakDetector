% Run this to train and create new neural net models in nnThud.mat and nnZCR.mat

[x,Fs]=audioread('../../data/GB_TestClip_v1_16000_mixed_included.wav');
t=(0:length(x)-1)/Fs;

labels=csvread('GB_TestClip_v1_label_mixed_included.csv');
l=List2Detections(t,labels);

ramp_operator_setup;

%% detector
gain=1;
% For declaring glass break

Chain = gb_model_2020_09_09(ramp,gain);
% y=Chain(t,x);
y=modelChain(Chain > ramp.pin.A3(),t,x);
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
