function glassBreakRampDev_v2(nnChainNumber,audioFileNumber)
% function glassBreakRampDevFunctionalForm(nnChainNumber, audioFileNumber, NNSUBTRACTIONS)

% Input switches
%       caseNumber: which Neural Network chain should be used
%       fileNumber: which audio file to train and test on

% Todo (from Brandon's code
%  - Verify each component: sw, rampsim, hw;  bpf, peak, log, zcr, lpf, ...
%  - Get a manageable set of features
%  - Fill in hardware and rampsim details
%  - Convert to trim project

%% Preliminaries
close all

% Select short (1) or long (2) audio file
% Testing different chains
if ~exist('nnChainNumber', 'var')
    nnChainNumber = 1;
end
if ~exist('audioFileNumber', 'var')
    audioFileNumber = 1;
end

% Whether to subtract Thud NN output from Shatter NN output and vice versa
% The rationale is to suppress times where the input signals are not
% specific to one sound or the other
NNSUBTRACTIONS=0;
% Wei for combining neural net outputs
nnWeight = 1;

% Determine whether program is running in Matlab or Octave
% The difference is whether fig-files and mat-files can be saved, and
% whether avi files can be generated from a sequence of figures
Octave = exist('OCTAVE_VERSION', 'builtin') == 5;

% First of several differences between Octave and Matlab
% Initialize the random number generator to repeatedly get the same results
% from the Neural Networks
if Octave
    rand ("seed", "reset")
else
    rng('default');
end

% Directory where the neural networks are being saved
matDir = './nnMatFiles';
if ~exist(matDir,'dir')
   mkdir(matDir);
end

% Location for saving intermediate results
dataMatDir = './dataMatFiles';
if ~exist(dataMatDir,'dir')
   mkdir(dataMatDir);
end

% Location for saving intermediate results
FigDir = './FigFiles';
if ~exist(FigDir,'dir')
   mkdir(FigDir);
end

dataDir = './data';
dataDir = '../../../data';
fname{1} = 'GB_TestClip_v1_16000.wav';
fname{2} = 'GB_TestClip_v1_16000_mixed_included.wav';
fname{3} = 'GB_TestClip_Training_v1_16000.wav';
fname{4} = 'GB_TestClip_v2_16000.wav';
fname{5} = 'GB_TestClip_Short_v1_16000.wav';
%fname{6} = 'overdriven_glass_break_1_000_a003_30_60_000.wav';
%fname{7} = 'GBTD-01-01-LP-gb1_000.wav';

% Enable RAMPdev. We can pass the variable ramp into subroutines
ramp_operator_setup;

%% Read in audio file and labels
[~,rootFname] = fileparts(fname{audioFileNumber});
thisFile = fullfile(dataDir,fname{audioFileNumber});
disp(['Reading ' thisFile])
[x,Fs]=audioread(thisFile);

t=(0:length(x)-1)/Fs;

% Listen to the audio at this point if desired
% soundsc(x,Fs);

disp(['Fs = ' num2str(Fs)])
disp(['Signal length = ' num2str(t(end)) ' seconds'])

% Label list of times
clear labels;
labelName{1}='GB_TestClip_v1_label.csv';
labelName{2}='GB_TestClip_v1_label_mixed_included.csv';
labelName{3}='GB_TestClip_Training_v1_label.csv';
labelName{4}='GB_TestClip_v2_label.csv';
labelName{5}='GB_TestClip_Short_v1_label.csv';
%labelName{6}='GB_TestClip_v1_label_mixed_included.csv';
%labelName{7}='GB_TestClip_v1_label.csv';

labels=csvread(fullfile(dataDir, labelName{audioFileNumber}));

% Convert label times to signal
l=List2Detections(t,labels);
disp(['Number of labeled glass breaks: ' num2str(length(labels))])


switch nnChainNumber
    case 0
        % This is the chain being sent to Ring; it does baseline
        % subtraction
        gain=1;
        Chain = ConstructFeatureChain(ramp,gain);
        sMethod='LogMinusBaselineAndZCR'
    case 1
        Chain = getChainLog;
        sMethod='LogBaselineAndZCR';
    case 2
        % uses ramp.ideal.tanh instead of ramp.ideal.log
        Chain = getChainTanh;
        sMethod='Tanh';        
    case 3
        Chain = getChainZCREnvelope;
        sMethod='ZCREnv';
    case 4
        % Still using ramp.ideal.log; Envelope baseline subtraction
        Chain = getChain3BandLog;
        sMethod='3BandLog';
    otherwise
        disp('other value')
end


% The chain was selected above; Log or Tanh is determined by the chain, not
% the training method
y=Chain(t,x);
%y = modelChain(Chain, t, x);
    
% Train the neural network with the five inputs in y and the labels
% Number of iteration and corresponding string
iterations=5e3; sIter='5000';

% Train from label to acceptable latency; this was Brandon's original NN
% but this NN is not used so it's commented out
% gap = 0;
% acceptableLatency = .2;
% [nn,S,N]=gb_testClip_train(t,y,l,acceptableLatency,gap,iterations);

% Listening for the thud, but not beyond the thud
% Change these variable names so as not to conflict with shatter?
gap=0;sGap='pt0';
acceptableLatency = .05;sLatency='pt05';

% Include the source of the traing data in the filename
nnTHUD_Name = fullfile(matDir,['nnThud_' sMethod '_gap_' sGap '_latency_' sLatency '_' rootFname '.mat']);
if ~exist(nnTHUD_Name,'file')
    [nnThud,event_indexThud, noise_indexThud]=gb_testClip_train(t,y,l,acceptableLatency,gap,iterations);
    save(nnTHUD_Name, 'nnThud','event_indexThud', 'noise_indexThud','gap','acceptableLatency');
else
    load(nnTHUD_Name, 'nnThud','event_indexThud', 'noise_indexThud','gap','acceptableLatency');    
end

% Now listen beyond the thud
% Don't collect training data until 50msec passed label
gap=.05; sGap = 'pt05';
acceptableLatency = .2;sLatency='pt2';
nnZCR_Name = fullfile(matDir,['nnZCR_' sMethod '_gap_' sGap '_latency_' sLatency '_' rootFname '.mat']);
if ~exist(nnZCR_Name,'file')
    [nnZCR,event_indexZCR, noise_indexZCR]=gb_testClip_train(t,y,l,acceptableLatency,gap,iterations);
    save(nnZCR_Name, 'nnZCR','event_indexZCR', 'noise_indexZCR','gap','acceptableLatency');
else
    load(nnZCR_Name, 'nnZCR','event_indexZCR', 'noise_indexZCR','gap','acceptableLatency');    
end

% Are the two methods for generating and evaluating the NN equivalent?
ynnThud=ramp_nn_eval(t,y,nnThud);
ynnShatter=ramp_nn_eval(t,y,nnZCR);


[declareThud, declareShatter] = applyTimingLogic_v2(ramp,t,l,ynnThud, ynnShatter);
%figure;plot(t,1.05*declareThud,'b',t,1.05*declareShatter,'r', t,l,'k')
%title('validThudPulse and wideValidThudPulse.*shatterPulse')

LabelList = labels;
DetectionList=Detection2List(t,declareShatter);
Performance=DetectionPerformance(DetectionList,LabelList(:,1:2),t(end));
P = Performance;
FAR = P.T_Noise_LabeledSpeech / (P.T_Noise_LabeledSpeech+P.T_Noise_LabeledNoise);
FRR = P.T_Speech_LabeledNoise / (P.T_Speech_LabeledNoise+P.T_Speech_LabeledSpeech);
mnLatency=mean(P.Syllables_Latency);
missedDetects = P.Syllables_Missed;
falseTriggers = P.FalseTriggers;
potentialDetects = P.Syllables_Total;
s=['Missed Detections = ' num2str(missedDetects) ' / ' num2str(potentialDetects) ' , False Triggers = ' num2str(falseTriggers)];

figure;plot(t,1.05*declareShatter,'r', t,l,'k')
v=axis;
v(4)=1.4;axis(v);
legend('Declared Shatter Onset', 'Labels')
title({rootFname,[sMethod ' Chain: Declared Shatter Onset'],['FRR = ' num2str(FRR,3) ',  FAR = ' num2str(FAR,3) ',  Mean Latency = ' num2str(1000*mnLatency,3) 'msec'],s},'interpreter','none')
%set(gcf,'position',[43          91        1186         420])

saveas(gcf,fullfile(FigDir, ['DeclareShatter_' sMethod '_' rootFname 'TimingLogicV2.png']));

saveppt2(fullfile(FigDir,'PNGs.ppt'));

% Print to screen for validation
Performance
return

function Chain = getChainLog
ramp_operator_setup;
gain=1;

% Chain1 and Chain2 each generate two outputs
% 4kHz BPF > PkDe > Log > {Pass;Baseline]
Chain1=ramp.ops.bpf('fc',4e3, 'Av',gain) > ramp.ops.peak('atk',8.13e3, 'dec',143, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];

% 400 Hz BPF > PkDe > Log > {Pass;Baseline]
Chain2=ramp.ops.bpf('fc',4e2, 'Av',gain) > ramp.ops.peak('atk',8.13e2, 'dec',54, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];

voltageScale=ramp.ideal.scale_fs_v('fs_to_v',-8);

% Chain generates five outputs
Chain=voltageScale > [ramp.ops.zcr() > ramp.ideal.amp('Av',.001); ...
    Chain1; ...
    Chain2];

return


function Chain = getChain3BandLog
ramp_operator_setup;
gain=1;

% Chain1 and Chain2 each generate two outputs
% 4kHz BPF > PkDe > Log > {Pass;Baseline]
Chain1=ramp.ops.bpf('fc',4e3, 'Av',gain) > ramp.ops.peak('atk',8.13e3, 'dec',143, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',10, 'dec',200, 'modelVersion','PDmodelDynamic')] > ramp.ideal.minus();

% 400 Hz BPF > PkDe > Log > {Pass;Baseline]
Chain2=ramp.ops.bpf('fc',4e2, 'Av',gain) > ramp.ops.peak('atk',8.13e2, 'dec',54, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',10, 'dec',200, 'modelVersion','PDmodelDynamic')] > ramp.ideal.minus();

% 6kHz BPF > PkDe > Log > {Pass;Baseline]
Chain3=ramp.ops.bpf('fc',6e3, 'Av',gain) > ramp.ops.peak('atk',12.13e3, 'dec',54, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',10, 'dec',200, 'modelVersion','PDmodelDynamic')] > ramp.ideal.minus();

voltageScale=ramp.ideal.scale_fs_v('fs_to_v',-8);

% Chain generates five outputs
Chain=voltageScale > [ramp.ops.zcr() > ramp.ideal.amp('Av',.001); ...
    Chain2; ...
    Chain1; ...
    Chain3];

return


function Chain = getChainTanh
ramp_operator_setup;
gain=1;

% Chain1 and Chain2 each generate two outputs
% 4kHz BPF > PkDe > Log > {Pass;Baseline]
Chain1=ramp.ops.bpf('fc',4e3, 'Av',gain) > ramp.ops.peak('atk',8.13e3, 'dec',143, 'modelVersion','PDmodelDynamic') > ramp.ideal.tanh('in_gain',20, 'out_min',0,'out_gain',.18) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];

% 400 Hz BPF > PkDe > Log > {Pass;Baseline]
Chain2=ramp.ops.bpf('fc',4e2, 'Av',gain) > ramp.ops.peak('atk',8.13e2, 'dec',54, 'modelVersion','PDmodelDynamic') > ramp.ideal.tanh('in_gain',20, 'out_min',0,'out_gain',.18) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];

voltageScale=ramp.ideal.scale_fs_v('fs_to_v',-8);

% Chain generates five outputs
Chain=voltageScale > [ramp.ops.zcr() > ramp.ideal.amp('Av',.001); ...
    Chain1; ...
    Chain2];

return

function FeatureChain = ConstructFeatureChain(ramp,gain)
	% 4kHz BPF > PkDe > Log > {Pass;Baseline]
	HiFreq = ramp.ops.bpf('fc',4e3, 'Av',gain) ...
					 > ramp.ops.peak('atk',8.13e2, 'dec',143) ... %, 'modelVersion','PDmodelDynamic') ...
					 > ramp.ideal.log('in_offset',6e-3) ...
					 > [ramp.ideal.pass(); ...
							ramp.ops.peak('atk',30, 'dec',90, 'modelVersion','PDmodelDynamic')];

    % 	HiFreq = ramp.ops.hpf('fc',6e3) ...
    % 					 > ramp.ops.peak('atk',8.13e2, 'dec',143) ... %, 'modelVersion','PDmodelDynamic') ...
    % 					 > ramp.ideal.log('in_offset',6e-3) ...
    % 					 > [ramp.ideal.pass(); ...
    % 							ramp.ops.peak('atk',30, 'dec',90, 'modelVersion','PDmodelDynamic')];

	% 400 Hz BPF > PkDe > Log > {Pass;Baseline]
	LoFreq = ramp.ops.bpf('fc',4e2, 'Av',gain) ...
					 > ramp.ops.peak('atk',8.13e2, 'dec',54) ... %, 'modelVersion','PDmodelDynamic') ...
					 > ramp.ideal.log('in_offset',6e-3) ...
					 > [ramp.ideal.pass(); ...
							ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];

	% Chain generates three outputs
	FeatureChain = [ramp.ops.zcr(); ...
									[HiFreq(); HiFreq()] > ramp.ideal.minus(); ...
									[LoFreq(); LoFreq()] > ramp.ideal.minus()];
                                
% 	FeatureChain = [ramp.ops.zcr(); ...
% 									[HiFreq(); HiFreq()]; ...
% 									[LoFreq(); LoFreq()]];                                
return

function Chain = getChainZCREnvelope
ramp_operator_setup;
gain=1;

% Chain1 and Chain2 each generate two outputs
% 4kHz BPF > PkDe > Log > {Pass;Baseline]
Chain1=ramp.ops.bpf('fc',4e3, 'Av',gain) > ramp.ops.peak('atk',8.13e3, 'dec',143, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];

% 400 Hz BPF > PkDe > Log > {Pass;Baseline]
Chain2=ramp.ops.bpf('fc',4e2, 'Av',gain) > ramp.ops.peak('atk',8.13e2, 'dec',54, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];

voltageScale=ramp.ideal.scale_fs_v('fs_to_v',-8);

% Chain generates five outputs
LPF = ramp.ops.lpf('fc',2e3);
trainZCR = LPF > ramp.ops.zcr() > ramp.ideal.amp('Av',1e3) > ramp.ops.peak('atk',100, 'dec',4) > ramp.ops.peak('atk',100, 'dec',100);
envelopeZCR = LPF > ramp.ops.zcr() > ramp.ideal.amp('Av',1e3) > ramp.ops.peak('atk',100, 'dec',4) > ramp.ops.peak('atk',100, 'dec',100) > ...
    [ramp.ideal.pass();ramp.ops.cmp('thresh',.3)] > ramp.ideal.mult('Av',.4);
Chain=voltageScale > [envelopeZCR; ...
    Chain1; ...
    Chain2];

return