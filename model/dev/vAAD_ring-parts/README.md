# Preparing model for Ring parts

* Had to setup multi-output neural net for this project. The details are in `brandon-scratch/sw/ml/vAAA_weight_scaling/multi-output`.
* Am approaching this with [first step](v0_basic-validation) to do a simple architecture w/ simplest features that still has diff-amp, preroll, and timing logic.

## Todo

- Setup a framework to take a simple version of the signal chain and go through the process
  - Verify trimming feasibility
  - Run with mic and glassbreak tester
  - Capture w/ preroll through H7 and run through their test
- Part ID readout
- Setup a framework to evaluate the options
  - ZCR or not, based on preroll or not
  - Log or not
  - Min or LPF, multiple?
  - 2 or 3 channels
  - LPF on the output or not
- Push through the trimming

## Code sent by Madhumita

```
function [declareThud, declareShatter] = applyTimingLogic_chain(t,l,ynnThud, ynnShatter)
​
% Enable RAMPdev
ramp_operator_setup;
​
CMPpt5 = ramp.ops.cmp('thresh',.5);
PULSE0001=ramp.ops.pulse('time',1e-6);
NOT = ramp.logic.gate('type','not');
AND = ramp.logic.gate('type','and');
AMPpt4=ramp.ideal.amp('Av',.4);
​
% wideValidThudPulseChain = [CMPpt5 > PULSE0001;
%     CMPpt5 > PULSE0001 > NOT > ramp.ops.pulse('time',.2)> NOT] > ...
%     AND > NOT > ramp.ops.pulse('time',.15);
​
%
UpTime=1e-1; DownTime=1e-1;
% ShatterPulseChain = ramp.ops.overhang('up',1.25/UpTime, 'down',1.25/DownTime) > CMPpt5 > PULSE0001;
wideValidThudPulse = [ynnThud > CMPpt5 > PULSE0001; ...
    ynnShatter > CMPpt5 > PULSE0001 > NOT > ramp.ops.pulse('time',.2)> NOT] > ...
    AND > NOT > ramp.ops.pulse('time',.15);
shatterPulse = ynnShatter > ramp.ops.overhang('up',1.25/UpTime, 'down',1.25/DownTime) > CMPpt5 > PULSE0001;
%wideValidThudPulse = wideValidThudPulseChain(t,[ynnThud ynnShatter]);
%shatterPulse = ShatterPulseChain(t,ynnShatter);
​
% validThudPulseChain = [CMPpt5 > PULSE0001;
%     CMPpt5 > PULSE0001 > NOT > ramp.ops.pulse('time',.2)> NOT] > AND > AMPpt4;
​
validThudPulse = [ynnThud > CMPpt5 > PULSE0001; ...
    ynnShatter > CMPpt5 > PULSE0001 > NOT > ramp.ops.pulse('time',.2)> NOT] > AND > AMPpt4;
%validThudPulse = validThudPulseChain(t,[ynnThud ynnShatter]);
​
%%% Not sure how to implement this step,,, it doesn't seem to provide the
%%% same answer as declareShatter
if 0
    declareShatterChain = [wideValidThudPulseChain;
        ShatterPulseChain] > AND > AMPpt4;
    declareShatterTest = declareShatterChain(t,[ynnThud ynnShatter ynnShatter]);
end
%%%
​
declareThud = validThudPulse;
declareShatter = [wideValidThudPulse;shatterPulse] > AND > AMPpt4;
%declareShatter = AMPpt4(t,AND(t,[wideValidThudPulse shatterPulse]));
​
return
```

and

```
clear
close all
clc
​
% Select short (1) or long (2) audio file
audioFileNumber = 1;
​
% Testing different chains
nnChainNumber = 1;
​
% Whether to subtract Thud NN output from Shatter NN output and vice versa
% The rationale is to suppress times where the input signals are not
% specific to one sound or the other
NNSUBTRACTIONS=0;
% Wei for combining neural net outputs
nnWeight = 1;
​
% Determine whether program is running in Matlab or Octave
% The difference is whether fig-files and mat-files can be saved, and
% whether avi files can be generated from a sequence of figures
Octave = exist('OCTAVE_VERSION', 'builtin') == 5;
​
% First of several differences between Octave and Matlab
% Initialize the random number generator to repeatedly get the same results
% from the Neural Networks
if Octave
    rand ("seed", "reset")
else
    rng('default');
end
​
% Directory where the neural networks are being saved
matDir = './nnMatFiles';
if ~exist(matDir,'dir')
   mkdir(matDir);
end
​
% Location for saving intermediate results
dataMatDir = './dataMatFiles';
if ~exist(dataMatDir,'dir')
   mkdir(dataMatDir);
end
​
% Location for saving intermediate results
FigDir = './FigFiles';
if ~exist(FigDir,'dir')
   mkdir(FigDir);
end
​
dataDir = '';
fname{1} = 'GB_TestClip_v1_16000.wav';
fname{2} = 'GB_TestClip_v1_16000_mixed_included.wav';
​
% Enable RAMPdev
ramp_operator_setup;
%%
[~,rootFname] = fileparts(fname{audioFileNumber});
thisFile = fullfile(dataDir,fname{audioFileNumber});
disp(['Reading ' thisFile])
[x,Fs]=audioread(thisFile);
​
t=(0:length(x)-1)/Fs;
​
% Listen to the audio at this point if desired
% soundsc(x,Fs);
​
disp(['Fs = ' num2str(Fs)])
disp(['Signal length = ' num2str(t(end)) ' seconds'])
​
% Label list of times
clear labels;
labelName{1}='GB_TestClip_v1_label.csv';
labelName{2}='GB_TestClip_v1_label_mixed_included.csv';
labels=csvread(fullfile(dataDir, labelName{audioFileNumber}));
​
% Convert label times to signal
l=List2Detections(t,labels);
disp(['Number of labeled glass breaks: ' num2str(length(labels))])
%% Getting feature chain (just taking one feature chain from Michael's program)
gain=1;
% Chain1 and Chain2 each generate two outputs
% 4kHz BPF > PkDe > Log > {Pass;Baseline]
Chain1=ramp.ops.bpf('fc',4e3, 'Av',gain) > ramp.ops.peak('atk',8.13e3, 'dec',143, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];
​
% 400 Hz BPF > PkDe > Log > {Pass;Baseline]
Chain2=ramp.ops.bpf('fc',4e2, 'Av',gain) > ramp.ops.peak('atk',8.13e2, 'dec',54, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];
​
voltageScale=ramp.ideal.scale_fs_v('fs_to_v',-8);
​
% Chain generates five outputs
Chain=voltageScale > [ramp.ops.zcr() > ramp.ideal.amp('Av',.001); ...
    Chain1; ...
    Chain2];
​
sMethod='Log';
​
y=Chain(t,x);
%%
iterations=5e3;sIter='5000';
​
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
​
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
​
%%
​
net_eval_thud=ramp.learn.nn('nn',nnThud);
net_eval_zcr=ramp.learn.nn('nn',nnZCR);
​
ynnThud=Chain>net_eval_thud;
ynnShatter=Chain>net_eval_zcr;
​
%%
[declareThud, declareShatter] = applyTimingLogic_chain(t,l,ynnThud, ynnShatter);
figure;plot(t,1.05*declareShatter(t,x),'r', t,l,'k')
legend('Declared Shatter Onset', 'Labels')
title('Declared Shatter Onset')
set(gcf,'position',[43          91        1186         420])
```


## Michael's input
- Don't do background subtraction, let the neural nets sort it out for now.
- Tanh may be viable if we use ROC curves to optimize parameters, which we need to do anyway.
- Training should be less incestuous. I need to augment the training data.
