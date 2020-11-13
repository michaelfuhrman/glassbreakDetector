function glassBreakRampDevWithParameters_v3(nnChainNumber,gbP,audioFileNumber,trainingDataNumber)
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

fName=mfilename;idx=find(mfilename=='_');sFname=fName(idx+1:end);
sThudThresh = num2str(gbP('thudThresh'));
sShatterThresh = num2str(gbP('shatterThresh'));
sThudOverShatterUmbrella = num2str(gbP('ThudOverShatterUmbrella'));
sShatterBeforeThudLimit = num2str(gbP('ShatterBeforeThudLimit'));
sShatterDelay = num2str(gbP('ShatterDelay'));

SIMPLESHATTERAFTERTHUD=gbP('SIMPLESHATTERAFTERTHUD');
THUDPEAK=gbP('ThudPeak');

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
sNNSubtraction=num2str(NNSUBTRACTIONS);
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

TablesDir = './TabularResults';
if ~exist(TablesDir,'dir')
   mkdir(TablesDir);
end

dataDir = './data';
dataDir = '../../../data';
fname{1} = 'GB_TestClip_v1_16000.wav';
fname{2} = 'GB_TestClip_v1_16000_mixed_included.wav';
fname{3} = 'GB_TestClip_Training_v1_16000.wav';
fname{4} = 'GB_TestClip_v2_16000.wav';
fname{5} = 'GB_TestClip_Short_v1_16000.wav';
fname{6} = 'appendedWith6minNPR.wav';
fname{7} = 'appendedWithHour2NPR.wav';

%fname{6} = 'overdriven_glass_break_1_000_a003_30_60_000.wav';
%fname{7} = 'GBTD-01-01-LP-gb1_000.wav';

% Enable RAMPdev
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
labelName{6}='appendedWith6minNPR.csv';
labelName{7}='appendedWithHour2NPR.csv';
%labelName{6}='GB_TestClip_v1_label_mixed_included.csv';
%labelName{7}='GB_TestClip_v1_label.csv';

labels=csvread(fullfile(dataDir, labelName{audioFileNumber}));

% Convert label times to signal
l=List2Detections(t,labels);
disp(['Number of labeled glass breaks: ' num2str(length(labels))])

sHF = num2str(gbP('hfFC'));
sLF = num2str(gbP('lfFC'));
switch nnChainNumber
    case -1
        gain=1;
        Chain = getChainScratch(ramp,gain);
        sMethod='Scratch';
    case 0
        % This is the chain being sent to Ring; it does baseline
        % subtraction
        gain=1;
        Chain = ConstructFeatureChain(ramp,gain);
        sMethod='LogMinusBslnZCR';
    case 1
        Chain = getChainLog(ramp,gbP);
        sMethod='LogBslnZCR';

    case 2
        % uses ramp.ideal.tanh instead of ramp.ideal.log
        Chain = getChainTanh(ramp,gbP);
        sMethod='TanhBslnZCR';        
    case 3
        Chain = getChainZCREnvelope(ramp);
        sMethod='ZCREnv';
    case 4
        % Still using ramp.ideal.log; Envelope baseline subtraction
        Chain = getChain3BandLog(ramp);
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
iterations=gbP('Iterations');
sIter=num2str(iterations);
%iterations=5e3; sIter='5000';

% Train from label to acceptable latency; this was Brandon's original NN
% but this NN is not used so it's commented out
% gap = 0;
% acceptableLatency = .2;
% [nn,S,N]=gb_testClip_train(t,y,l,acceptableLatency,gap,iterations);

% Listening for the thud, but not beyond the thud
% Change these variable names so as not to conflict with shatter?
gap=0;sGap='pt0';
acceptableLatency = .05;sLatency='pt05';

% Include the source of the training data in the filename
[~,trainingFileName] = fileparts(fname{trainingDataNumber});

sTrain = ['TrainAudio' num2str(trainingDataNumber)];
gap = 0; sGap = 'pt0';
latency = .2; sLatency = 'pt2';
iterations = 5000;sIterations = '5K';
nnName = [sMethod '.' sTrain '.'  sGap '.' sLatency '.' sIterations '.mat'];  
nnTHUD_Name = fullfile(matDir,['nnThud.' nnName]);
nnZCR_Name = fullfile(matDir,['nnZCR.' nnName]);

% Read in the training audio if it doesn't correspond to the input audio
if audioFileNumber~=trainingDataNumber
    [xTraining,FsTraining]=audioread(thisFile);
    tTraining=(0:length(xTraining)-1)/FsTraining;
    yTraining=Chain(tTraining,xTraining);
end




sFreq = ['_fc_' num2str(gbP('lfFC')) '_' num2str(gbP('hfFC'))];
%nnTHUD_Name = fullfile(matDir,['nnThud' '_Iter' sIter sFreq sMethod '_gap_' sGap '_lat_' sLatency '_' rootFname '.mat']);
nnTHUD_Name = fullfile(matDir,['nnThud_' sMethod '_gap_' sGap '_latency_' sLatency '_' trainingFileName '.mat']);
if ~exist(nnTHUD_Name,'file')
    [nnThud,event_indexThud, noise_indexThud]=gb_testClip_train(t,y,l,acceptableLatency,gap,iterations);
    nnThud=nnScrub(nnThud);
    save(nnTHUD_Name, 'nnThud','event_indexThud', 'noise_indexThud','gap','acceptableLatency');
else
    load(nnTHUD_Name, 'nnThud','event_indexThud', 'noise_indexThud','gap','acceptableLatency');    
end

% Now listen beyond the thud
% Don't collect training data until 50msec passed label
gap=.05; sGap = 'pt05';
acceptableLatency = .2;sLatency='pt2';
%nnZCR_Name = fullfile(matDir,['nnZCR' '_Iter' sIter sFreq sMethod '_gap_' sGap '_lat_' sLatency '_' rootFname '.mat']);
nnZCR_Name = fullfile(matDir,['nnZCR_' sMethod '_gap_' sGap '_latency_' sLatency '_' trainingFileName '.mat']);
if ~exist(nnZCR_Name,'file')
    [nnZCR,event_indexZCR, noise_indexZCR]=gb_testClip_train(t,y,l,acceptableLatency,gap,iterations);
    nnZCR=nnScrub(nnZCR);
    save(nnZCR_Name, 'nnZCR','event_indexZCR', 'noise_indexZCR','gap','acceptableLatency');
else
    load(nnZCR_Name, 'nnZCR','event_indexZCR', 'noise_indexZCR','gap','acceptableLatency');    
end

close all
% Override the neural nets
if isempty(gbP('TrainingData'))
    trainingData = 'self';
else
    trainingData = gbP('TrainingData');
    if nnChainNumber == 1
        % 'LogBslnZCR'
        load(fullfile(matDir, ['nnThud' sFreq sMethod '_gap_pt0_lat_pt05_' trainingData '.mat']));
        load(fullfile(matDir, ['nnZCR' sFreq sMethod '_gap_' sGap '_lat_' sLatency '_' trainingData '.mat']));
    elseif nnChainNumber == 2
        % 'TanhBslnZCR'
        load(fullfile(matDir, 'nnThud_TanhBaselineAndZCR_gap_pt0_latency_pt05_appendedWith6minNPR.mat'));
        load(fullfile(matDir, 'nnZCR_TanhBaselineAndZCR_gap_pt05_latency_pt2_appendedWith6minNPR.mat  '));
        trainingData = 'appendedWith6minNPR';
    else
        trainingData = 'self';
    end
end
% No longer need the original signal
% clear noise_indexThud;
% clear noise_indexZCR;
% clear event_indexZCR;
% clear event_indexThud;
% clear x;

% Cut back to one half hour
oneHalfHr=16000*60*30;
if length(t) > oneHalfHr
    x=x(1:oneHalfHr,1); % Column vector
    t=t(1:oneHalfHr); % Row vector
    y=y(1:oneHalfHr,:); % Column vector
    l=l(1:oneHalfHr); % Row vector
end

% Are the two methods for generating and evaluating the NN equivalent?
load('nnThud_Iter5000_fc_400_4000LogBslnZCR_gap_pt0_lat_pt05_appendedWith6minNPR.mat','nnThud')
load('nnZCR_Iter5000_fc_400_4000LogBslnZCR_gap_pt05_lat_pt2_appendedWith6minNPR.mat','nnZCR')
ynnThud=ramp_nn_eval(t,y,nnThud);
ynnShatter=ramp_nn_eval(t,y,nnZCR);

% Thuds at Peaks
% Default initialization
sPeaks='noPeaks';
if THUDPEAK > 0
    % Attempts at smoothing
    % ramp.ops.overhang('up',1000, 'down',10);
    % ramp.ops.peak('atk',1000, 'dec',1000) >
    Peak=ramp.ops.peak('atk',1000, 'dec',10, 'modelVersion','PDmodelDynamic');
    RMS = ramp.ops.peak('atk',100, 'dec',1, 'modelVersion','PDmodelDynamic');
    CMPNN = ramp.ops.cmp('thresh',.5);
    AMPpt4=ramp.ideal.amp('Av',.4);
    
    % This is the asynchronous peak detector
    if 1
        hfPeakChain = [RMS;
            ramp.ideal.pass()] > ...
            ramp.ideal.minus() > ramp.ops.cmp('thresh',0) > ...
            ramp.ops.pulse('time',1e-6) > AMPpt4;
    else
        % Difference of two peak detectors
        P1=ramp.ops.peak('atk',1000, 'dec',10, 'modelVersion','PDmodelDynamic');
        P2=ramp.ops.peak('atk',100, 'dec',10, 'modelVersion','PDmodelDynamic');
        hfPeakChain = [P1;
            P2] > ...
            ramp.ideal.minus() > ramp.ops.cmp('thresh',0) > ...
            ramp.ops.pulse('time',1e-6) > AMPpt4;
    end
    
    % Numerator outputs when peaks are detected in y(:,2) or y(:,2)-y(:,4)
    % Denominator takes ynnThud as input and applies a threshold
    % Consider lowering ramp.ops.cmp('thresh',.3)
    peakNNChain = [hfPeakChain;
                    ramp.ideal.pass() > ramp.ops.cmp('thresh',.5)] > ramp.logic.gate('type','and') > AMPpt4;
    %   
    if THUDPEAK == 1
        ynnThudAtPeaks = peakNNChain(t, [y(:,4), ynnThud]);
        % Appending _hfPeaks to the NN chain name
        sPeaks='lf';
    elseif THUDPEAK == 2
        ynnThudAtPeaks = peakNNChain(t, [y(:,2), ynnThud]);
        % Appending _hfPeaks to the NN chain name
        sPeaks='hf';    
    elseif THUDPEAK == 3
        ynnThudAtPeaks = peakNNChain(t, [y(:,2)-y(:,4), ynnThud]);
        % Appending _hfMlfPeaks to the NN chain name
        sPeaks='hf-lf';
    end
    
    if 0
        RMS = ramp.ops.peak('atk',10, 'dec',1, 'modelVersion','PDmodelDynamic');
        Peak=ramp.ops.peak('atk',1000, 'dec',10, 'modelVersion','PDmodelDynamic');
        CMP = ramp.ops.cmp('thresh',0);
        Z = .4*CMP(t,Peak(t,y(:,2))-RMS(t,y(:,2)));
        ynnThudAtPeaks = Z.* ynnThud;
        yp=Peak(t,y(1:end,2));
        [tmaxHF,valmaxHF,idxHF]=asyncSamplingMax(yp,t,1000,1000);
        ynnThudAtPeaks = 0*ynnThud;
        ynnThudAtPeaks(idxHF,1) = ynnThud(idxHF,1);
    end
else
    % sMethod isn't modified
end

if SIMPLESHATTERAFTERTHUD == 1
    sTiming = 'simpleTiming';
else
    sTiming = 'v3Timing';
end

if 0
    figure;plot(t,1.1*thudAtPeaks,t,l,'k');
                
    figure;plot(t,1.1*hfPeakChain(t,y(:,2)).*CMPNN(t,ynnThud),t,l,'k');
    
    figure;plot(t,RMS(t,y(:,2))-y(:,2));
    
    % Perhaps grab thuds which occur at signal peaks
    [tmaxHF,valmaxHF,idxHF]=asyncSamplingMax(y(:,2),t,100,1);
    [tmaxHF,valmaxHF,idxHF]=asyncSamplingMax(y(:,2)-y(:,4),t,100,1);
    temp=0*ynnThud;
    temp(idxHF)=ynnThud(idxHF);
    ynnThud=temp;
end

if 0
    % Scratch work
    Peak=ramp.ops.peak('atk',10000, 'dec',100, 'modelVersion','PDmodelDynamic');
    %Rms = ramp.ops.peak();
    [a,d]=PDbias(0.7,.1,200); a=5*4000;
    Rms = ramp.ops.peak('atk',a, 'dec',d);
    sigRms = Rms(t,y(:,2));
    
    idx = [];idxLF=[];idxHF=[];
    %[tmaxLF,valmaxLF,idxLF]=asyncSamplingMax((y(:,4)),t,100,1);
    
    % Rise quickly to peak but decay slowly over subsequent signal
    [tmaxHF,valmaxHF,idxHF]=asyncSamplingMax((y(:,2)),t,1000,1);
    
    Rms = ramp.ops.peak('atk',100, 'dec',1, 'modelVersion','PDmodelDynamic');
    %sigRms = Rms(t,Rms(t,y(:,2)));
    %[tmaxHF,valmaxHF,idxHF]=asyncSamplingMax(y(:,2),t,10000,100);
    [tmaxHF,valmaxHF,idxHF]=asyncSamplingMax(sigRms,t,100,1);
end

%figure;plot(t(idx), declareThud(idx))

if NNSUBTRACTIONS==1
    ynnThud = ynnThud-ynnShatter;
    ynnShatter = -ynnThud;
    ynnThud(ynnThud<0)=0;
    ynnShatter(ynnShatter<0)=0;
end

%
ThudBeforeShatter = gbP('ThudBeforeShatter');
if THUDPEAK == 1
    [declareThud, declareShatter] = applyTimingLogic_v3(ramp, t,l,ynnThudAtPeaks, ynnShatter, gbP, ThudBeforeShatter);
else
    [declareThud, declareShatter] = applyTimingLogic_v3(ramp, t,l,ynnThud, ynnShatter,gbP,ThudBeforeShatter);
end

% Compare with model chain
if 1
    load('nnThud_Iter5000_fc_400_4000LogBslnZCR_gap_pt0_lat_pt05_appendedWith6minNPR.mat','nnThud')
    load('nnZCR_Iter5000_fc_400_4000LogBslnZCR_gap_pt05_lat_pt2_appendedWith6minNPR.mat','nnZCR')
    [ThudChain, ShatterChain] = gb_model_2020_11_03_v2(ramp,nnThud, nnZCR);
    
    figure;
    subplot(211);plot(t,1.05*declareShatter,'r', t,l,'k');ax(1)= gca;
    title('applyTimingLogic_v3 Results','interpreter','none')
    xlabel('Time (seconds)')
    subplot(212);plot(t,1.1*ShatterChain(t,x),'r',t,l,'k');ax(2)=gca;
    title('gb_model_2020_11_03 Results','interpreter','none')
    xlabel('Time (seconds)')
    linkaxes(ax)
end
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

sTPR = ['TPR = ' num2str(potentialDetects-missedDetects) ' / ' num2str(potentialDetects)];
sTPs = num2str(potentialDetects-missedDetects);
sPDs = num2str(potentialDetects);
sFPs = num2str(falseTriggers);
sFalseTriggers = ['FPs = ' num2str(falseTriggers)];

% Reformat
s=['Missed Detections = ' num2str(missedDetects) ' / ' num2str(potentialDetects) ' , False Triggers = ' num2str(falseTriggers)];


if 0
    figure;
    subplot(311)
    plot(t,ynnThud,'b', t,ynnShatter,'r', t,l,'k')
    title({rootFname,[sMethod ' Chain: Declared Shatter Onset'],['FRR = ' num2str(FRR,3) ',  FAR = ' num2str(FAR,3) ',  Mean Latency = ' num2str(1000*mnLatency,3) 'msec'],s},'interpreter','none')
    ax(1)=gca;
    subplot(312)
    plot(t,1.05*declareThud,'b', t,1.05*declareShatter,'r', t,l,'k')
    ax(2)=gca;
    subplot(313)
    plot(t,1.05*declareShatter,'r', t,l,'k')
    axis('tight')
    ax(3)=gca;
    v=axis;
    v(4)=1.4;axis(v);
    legend('Declared Shatter Onset', 'Labels')
    linkaxes(ax);
    %set(gcf,'position',[43          91        1186         420])
    
    % The csv file is continuously appended
    saveas(gcf,fullfile(FigDir, ['DeclareShatter_' sMethod '_' rootFname 'TimingLogicV3.png']));
end

% fileLength = ['Duration = ' num2str(t(end),'%.2f')];
% meanLatency = ['Mean Latency = ' num2str(1000*mnLatency,3) 'msec'];
%fileLength = [num2str(t(end),'%.2f') 'sec'];
fileLength = num2str(t(end)/60,'%.2f');
meanLatency = [num2str(1000*mnLatency,3) 'msec'];
% Place it in this directory and then move it later
fid = fopen('GlassbreakResults.csv', 'a');
% m-file, nn chain, wav filename, duration, missed detects / possible detects, false triggers, mean latency
%fprintf(fid,'%s,%s,%s,%s,%s,%s,%s\n',mfilename,sMethod,rootFname,fileLength,sTPR,sFalseTriggers,meanLatency);
fprintf(fid,'%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n',sFname,sMethod,sLF,sHF,sThudThresh,sShatterThresh,sNNSubtraction,sShatterDelay,sThudOverShatterUmbrella,sShatterBeforeThudLimit,sPeaks,sTiming,trainingData,sIter,rootFname,fileLength,sTPs,sPDs,sFPs,meanLatency);
fclose(fid);

% Create markdown table. The header will get attached to the results by the
% function which is calling this function repeatedly, with the appropriate
% file name which will be dependent of the processing
% Place it in this directory and then move it later
fid = fopen('GlassbreakResults.md', 'a');
%fprintf(fid,'%s%s%s%s%s%s%s\n',['| ' mfilename ' | '],[sMethod ' | '],[ rootFname ' | '],[fileLength ' | '],[sTPR ' | '], [sFalseTriggers ' | '], [meanLatency ' |']);
fprintf(fid,'%s%s%s%s%s%s%s%s%s\n',['| ' sFname ' | '],[sMethod ' | '],[sLF ' | '],[sHF ' | '],[sPeaks ' | '],[sTiming ' | '],[trainingData ' | '],[ rootFname ' | '],[fileLength ' | '],[sTPs ' | '], [sPDs ' | '], [sFPs ' | '], [meanLatency ' |']);
fclose(fid);


%saveppt2(fullfile(FigDir,'PNGs.ppt'));

% Print to screen for validation
Performance
return

function Chain = getChainScratch(ramp,gain)
Chain1=ramp.ops.bpf('fc',4e3, 'Av',gain) > ramp.ops.peak('atk',8.13e3, 'dec',143, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > [ramp.ideal.pass(); ...
                                                                                                                     ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];
Chain2=ramp.ops.bpf('fc',4e2, 'Av',gain) > ramp.ops.peak('atk',8.13e2, 'dec',54, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > [ramp.ideal.pass(); ...
																																																																												ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];
voltageScale=ramp.ideal.scale_fs_v('fs_to_v',-8);
voltageLevel=voltageScale(t,x);

Chain=voltageScale > [ramp.ops.zcr() > ramp.ideal.amp('Av',.001); Chain1; Chain2];

return

function Chain = getChainLog(ramp,gbP)
gain=1;

% Chain1 and Chain2 each generate two outputs
% 4kHz BPF > PkDe > Log > {Pass;Baseline]
Chain1=ramp.ops.bpf('fc',gbP('hfFC'), 'Av',gain) > ramp.ops.peak('atk',gbP('hfEnvAtk'), 'dec',gbP('hfEnvDec'), 'modelVersion','PDmodelDynamic') > ...
    ramp.ideal.log('in_offset',6e-3) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',gbP('hfBaseAtk'), 'dec',gbP('hfBaseDec'), 'modelVersion','PDmodelDynamic')];

% 400 Hz BPF > PkDe > Log > {Pass;Baseline]
Chain2=ramp.ops.bpf('fc',gbP('lfFC'), 'Av',gain) > ramp.ops.peak('atk',gbP('lfEnvAtk'), 'dec',gbP('lfEnvDec'), 'modelVersion','PDmodelDynamic') > ...
    ramp.ideal.log('in_offset',6e-3) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',gbP('lfBaseAtk'), 'dec',gbP('lfBaseDec'), 'modelVersion','PDmodelDynamic')];

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


function Chain = getChainTanh(ramp,gbP)
gain=1;

% Chain1 and Chain2 each generate two outputs
% 4kHz BPF > PkDe > Log > {Pass;Baseline]
Chain1=ramp.ops.bpf('fc',4e3, 'Av',gain) > ramp.ops.peak('atk',gbP('hfEnvAtk'), 'dec',gbP('hfEnvDec'), 'modelVersion','PDmodelDynamic') > ramp.ideal.tanh('in_gain',20, 'out_min',0,'out_gain',.18) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',gbP('hfBaseAtk'), 'dec',gbP('hfBaseDec'), 'modelVersion','PDmodelDynamic')];

% 400 Hz BPF > PkDe > Log > {Pass;Baseline]
Chain2=ramp.ops.bpf('fc',4e2, 'Av',gain) > ramp.ops.peak('atk',gbP('lfEnvAtk'), 'dec',gbP('lfEnvDec'), 'modelVersion','PDmodelDynamic') > ramp.ideal.tanh('in_gain',20, 'out_min',0,'out_gain',.18) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',gbP('lfBaseAtk'), 'dec',gbP('lfBaseDec'), 'modelVersion','PDmodelDynamic')];

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