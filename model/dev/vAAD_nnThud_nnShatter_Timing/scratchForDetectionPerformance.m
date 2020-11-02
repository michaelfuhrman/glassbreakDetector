function [declareShatter, mfilename, wavFile,TPs,FPs,mnLatency,duration] = scratchForDetectionPerformance(audioFileNumber)

% Todo
%  - Verify each component: sw, rampsim, hw;  bpf, peak, log, zcr, lpf, ...
%  - Get a manageable set of features
%  - Fill in hardware and rampsim details
%  - Convert to trim project

if ~exist('audioFileNumber','var')
    audioFileNumber = 1;
end

dataDir = '../../../data';
fname{1} = 'GB_TestClip_v1_16000.wav';
fname{2} = 'GB_TestClip_v1_16000_mixed_included.wav';
fname{3} = 'GB_TestClip_Training_v1_16000.wav';
fname{4} = 'GB_TestClip_v2_16000.wav';
fname{5} = 'GB_TestClip_Short_v1_16000.wav';
%fname{6} = 'overdriven_glass_break_1_000_a003_30_60_000.wav';
%fname{7} = 'GBTD-01-01-LP-gb1_000.wav';

%% Read in audio file and labels
[~,rootFname] = fileparts(fname{audioFileNumber});
thisFile = fullfile(dataDir,fname{audioFileNumber});
disp(['Reading ' thisFile])
[x,Fs]=audioread(thisFile);

t=(0:length(x)-1)/Fs;

labelName{1}='GB_TestClip_v1_label.csv';
labelName{2}='GB_TestClip_v1_label_mixed_included.csv';
labelName{3}='GB_TestClip_Training_v1_label.csv';
labelName{4}='GB_TestClip_v2_label.csv';
labelName{5}='GB_TestClip_Short_v1_label.csv';
%labelName{6}='GB_TestClip_v1_label_mixed_included.csv';
%labelName{7}='GB_TestClip_v1_label.csv';

labels=csvread(fullfile(dataDir, labelName{audioFileNumber}));

l=List2Detections(t,labels);

ramp_operator_setup;
gain=1;                                                                                                          
                                                                                                                
Chain1=ramp.ops.bpf('fc',4e3, 'Av',gain) > ramp.ops.peak('atk',8.13e3, 'dec',143, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > [ramp.ideal.pass(); ...
                                                                                                                     ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];
Chain2=ramp.ops.bpf('fc',4e2, 'Av',gain) > ramp.ops.peak('atk',8.13e2, 'dec',54, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > [ramp.ideal.pass(); ...
																																																																												ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];
voltageScale=ramp.ideal.scale_fs_v('fs_to_v',-8);
voltageLevel=voltageScale(t,x);

Chain=voltageScale > [ramp.ops.zcr() > ramp.ideal.amp('Av',.001); Chain1; Chain2];

y=Chain(t,x);
%[nn, event_index, noise_index] = gb_testClip_train(t,y,l,acceptableLatency,gap,iterations)
nn=gb_testClip_train(t,y,l,.2,0,5000);
ynn=ramp_nn_eval(t,y,nn);

if 0
    figure(2); a1=subplot(2,1,1); plot(t,x,t,y)
    figure(1);
    figure(3); a1=subplot(2,1,1); plot(t,x,t,y); a2=subplot(2,1,2); plot(t,ynn,t,l);
    
    IASchain=ramp.dsp.infineondetector('sensitivity','v3_1');
    IASout=IASchain(t,x);
    % a1=subplot(2,1,1); plot(t,x,t,l,t,IASchain(t,x)*.8)
    % a2=subplot(2,1,2); plot(t,ChainDetect(t,x))
    linkaxes([a1,a2],'x')
end

% Decision integration
DecInt=ramp.ops.overhang('up',8, 'down',10);

% Compute performance using DecInt(t,ynn) with a threshold
declareShatter = DecInt(t,ynn)>.5;
DetectionList=Detection2List(t,declareShatter);
LabelList=labels;

% New performance code
Performance=DetectionPerformance(DetectionList,LabelList(:,1:2),t(end));
P = Performance;
FAR = P.T_Noise_LabeledSpeech / (P.T_Noise_LabeledSpeech+P.T_Noise_LabeledNoise);
FRR = P.T_Speech_LabeledNoise / (P.T_Speech_LabeledNoise+P.T_Speech_LabeledSpeech);
mnLatency=mean(P.Syllables_Latency);
missedDetects = P.Syllables_Missed;
falseTriggers = P.FalseTriggers;
potentialDetects = P.Syllables_Total;

TPs = potentialDetects - missedDetects;
FPs = falseTriggers;
mfilename = 'scratch';
wavFile = fname{audioFileNumber};
duration = t(end)
if 0 % Old performance code
    Performance=DetectionPerformance(DetectionList,LabelList(:,1:2),t(end));
    P = Performance;
    FAR = P.T_Noise_LabeledSpeech / (P.T_Noise_LabeledSpeech+P.T_Noise_LabeledNoise);
    FRR = P.T_Speech_LabeledNoise / (P.T_Speech_LabeledNoise+P.T_Speech_LabeledSpeech);
    mnLatency=mean(P.Syllables_Latency);
    missedDetects = P.Syllables_Missed;
    falseTriggers = P.FalseTriggers;
    potentialDetects = P.Syllables_Total;
    s=['Missed Detections = ' num2str(missedDetects) ' / ' num2str(potentialDetects) ' , False Triggers = ' num2str(falseTriggers)]
end

return
