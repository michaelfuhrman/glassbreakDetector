% Test without training

[x,Fs]=audioread('GB_TestClip_v1_16000_mixed_included.wav');
t=(0:length(x)-1)/Fs;

labels=csvread('GB_TestClip_v1_label_mixed_included.csv');
l=List2Detections(t,labels);
disp(['Number of labeled glass breaks: ' num2str(length(labels))])
ramp_operator_setup;

%% detector
gain=1;

load('nnThud.mat', 'nnThud');
load('nnZCR.mat', 'nnZCR');

[Chain_declareThud, Chain_declareShatter] = gb_model_2020_09_09(ramp, gain, nnThud, nnZCR);

nD=1:25*Fs; % subset of indices to run the test on
nD=1:length(t);
% nD=find(t>80 & t<140);

% The Matlab eval
thudEval = Chain_declareThud(t(nD),x(nD));
shatterEval = Chain_declareShatter(t(nD),x(nD));
a1=subplot(2,1,1); plot(t(nD),thudEval*1.1, t(nD),l(nD)*2.5);
subplot(2,1,2); plot(t(nD),shatterEval*1.1, t(nD),l(nD)*2.5);

% Now in rampsim
% rampSim=expandVarPath('%AspBox%\engr\sw\Utilities\rampSim\bin\rampSim.exe');
% inFile=tmpFile('inRunNetlist.wav');
% outFile=tmpFile('outRunNetlist.auf');
% netlistName='netlist.net';

% [status,output]=system(sprintf('"%s" "%s" "%s" "%s"',rampSim,netlistName,inFile,outFile));
% [y]=audioread(outFile);
% a2=subplot(2,1,2); plot(t(nD),y*5);

thudSim = modelChain(Chain_declareThud,t(nD),x(nD));
shatterSim = modelChain(Chain_declareShatter,t(nD),x(nD));
subplot(2,1,1); plot(t(nD),thudEval*1.1, t(nD),thudSim(:,2)*1.2, t(nD),l(nD)*2.5);
subplot(2,1,2); plot(t(nD),shatterEval*1.1, t(nD),shatterSim(:,2)*1.2, t(nD),l(nD)*2.5);
