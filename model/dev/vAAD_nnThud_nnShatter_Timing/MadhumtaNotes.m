%% Some Notes
% --- pulse_op* are the detections of the chain passing through a pulse
%     detector
% --- Chain_net1_detection and pulse_op1 are the chains for detection not
%     including the fast onset features.
% --- Chain_net2_detection and pulse_op2 are the chains for detection including
%     the fast onset features.
% --- The following features are used: Filtered signal energy through 300Hz
%     filter (chain1_1), chain1_1's baseline (chain4_1), filtered signal
%     energy at 4kHz (chain3_1), chain3_1 minus it's baseline (chain5_1),
%     gain compression on chain5_1 (chain8_1)
% --- Works reasonably okay even if feature chain8_1 is removed (using only
%     4 features)
% --- Each run gives a slightly different output. 
% --- Observations: Latency is higher for features including the fast onset.
%     But has a better performance in terms of false positives and
%     sometimes the missed detections
%%
clear
close all
clc
ramp_operator_setup;
?
%% Reading data
[x, Fs] = audioread('../../data/vad_ces2020.wav');
[l] = audioread('../../data/vad_ces2020_label.wav');
t = (0 : (length(x) - 1)) / Fs;
?
%% Feature chain
?
fc = 300; Q = 1.25;
Bpf_1 = ramp.ideal.handle('func', @(t,x)filter_order2(x, t, fc, Q));
?
fc = 4e3; Q = 4;
Bpf_3 = ramp.ideal.handle('func', @(t,x)filter_order2(x, t, fc, Q));
?
chain1_1=Bpf_1>ramp.ops.peak('atk',500,'dec',40)>ramp.ideal.log('in_offset', 2e-3);
chain3_1=Bpf_3>ramp.ops.peak('atk',20,'dec',10)>ramp.ideal.log('in_offset', 2e-3);
chain4_1=chain1_1>ramp.ops.peak('atk',4,'dec',40);
chain5_1=chain3_1>[ramp.ideal.pass();ramp.ops.peak('atk',4,'dec',10)]>ramp.ideal.minus();
%gain supression
chain6_1=chain5_1>[ramp.ideal.pass();ramp.ops.cmp('thresh',0.02)>ramp.ideal.amp('Av',0.4)]>ramp.ideal.mult()>ramp.ideal.amp('Av',0);
chain7_1=chain5_1>[ramp.ideal.pass();ramp.ops.cmp('thresh',0.02)>ramp.logic.gate('type','not')>ramp.ideal.amp('Av',0.4)]>ramp.ideal.mult();
chain8_1=[chain6_1;chain7_1]>ramp.ideal.sum();
?
SigChain=[chain1_1;chain4_1;chain3_1;chain5_1;chain8_1];
?
?
%% Creating some fast features to filter fast onset
WideBandEnvelope = ramp.ops.peak('atk', 1.1e3, 'dec', 24);
FastestAcceptableEnvelope = ramp.ops.peak('atk', 100, 'dec', 24);
ReLU = ramp.ideal.handle('func', @(t,x)max(x,0)); 
?
TooFast = WideBandEnvelope ...
          > [ramp.ideal.pass(); ...
             FastestAcceptableEnvelope] ...
          > ramp.ideal.minus() ...
          > ReLU;
      
Features = [SigChain];
FeaturesFast = [SigChain;
                TooFast];
?
%%
X_PureSig = Features(t, x);
y_PureSig = X_PureSig;
?
% NN training!!
acceptableLatency = 0.1;
[X,Y] = dataSplitter(t, y_PureSig, l', acceptableLatency);
?
% Train
rate=.3; iterations=25e3; hiddenLayers=[8 8];
nn=nnModelCreate(X,Y,rate,iterations,hiddenLayers);
nn=nnScrub(nn);
?
?
X_PureSig = FeaturesFast(t, x);
y_PureSig = X_PureSig;
?
% NN training!!
acceptableLatency = 0.1;
[X,Y] = dataSplitter(t, y_PureSig, l', acceptableLatency);
?
% Train
rate=.3; iterations=25e3; hiddenLayers=[8 8];
nnFast=nnModelCreate(X,Y,rate,iterations,hiddenLayers);
nnFast=nnScrub(nnFast);
?
%% Decision integration and plotting for regular features
net_eval=ramp.learn.nn('nn',nn);
Chain_net1=Features>net_eval;
?
net_eval=ramp.learn.nn('nn',nnFast);
Chain_net2=FeaturesFast>net_eval;
?
lpf = ramp.ops.lpf('fc', 20);
Chain_net1_detection = Chain_net1>lpf>ramp.ops.cmp('thresh', 0.7) > ramp.ops.overhang('up',40, 'down',10);
pulse_op1 = Chain_net1_detection>ramp.ops.cmp('thresh', 0.4)>ramp.ops.pulse('time',100e-3);
?
Chain_net2_detection = Chain_net2>lpf>ramp.ops.cmp('thresh', 0.7) > ramp.ops.overhang('up',40, 'down',10);
pulse_op2 = Chain_net2_detection>ramp.ops.cmp('thresh', 0.4)>ramp.ops.pulse('time',100e-3);
?
if 0
figure,
subplot(3,1,1)
plot(t,x,t,l)
subplot(3,1,2)
plot(t,Chain_net1_detection(t,x),t,l)
subplot(3,1,3)
plot(t,pulse_op1(t,x),t,l)
?
figure,
subplot(3,1,1)
plot(t,x,t,l)
subplot(3,1,2)
plot(t,Chain_net2_detection(t,x),t,l)
subplot(3,1,3)
plot(t,pulse_op2(t,x),t,l)
end
?
%%
function [X,Y] = dataSplitter(t, y, l, acceptableLatency)
  %% Extract feature vector
  % Non-events are wherever the label is 0
  noise_index=find(l==0);
  
  % Events are wherever the label is higher for less than the acceptable latency time
  labels=Detection2List(t,l);
  labels_acceptable=[labels(:,1) min(labels(:,2),labels(:,1)+acceptableLatency)];
  l_acceptable=List2Detections(t,labels_acceptable);
  
  % Split into event and noise
  event_index=find(l_acceptable==1);
  noise_index=noise_index;
  
  event_to_noise_samples = 1; % balance of the event to noise
  noise_index = randsample(noise_index, length(event_index));
  
  % Our final training data
  X=y([event_index noise_index],:);
  Y=[ones(size(event_index)) zeros(size(noise_index))]';
  % Downsampled for the sake of training time
  X=X(1:20:end,:);
  Y=Y(1:20:end,:);
end