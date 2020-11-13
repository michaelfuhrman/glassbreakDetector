
function runCreateNeuralNets


ramp_operator_setup;
gbP = setDefaultParameters;
trainingDataNumber = 6;

% Directory where the neural networks are being saved
matDir = './nnMatFiles';
if ~exist(matDir,'dir')
   mkdir(matDir);
end

%% Need a chain
nnChainNumber = 2;

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

%%
% Now we need training data
dataDir = './data';
dataDir = '../../../data';
fname{1} = 'GB_TestClip_v1_16000.wav';
fname{2} = 'GB_TestClip_v1_16000_mixed_included.wav';
fname{3} = 'GB_TestClip_Training_v1_16000.wav';
fname{4} = 'GB_TestClip_v2_16000.wav';
fname{5} = 'GB_TestClip_Short_v1_16000.wav';
fname{6} = 'appendedWith6minNPR.wav';
fname{7} = 'appendedWithHour2NPR.wav';

% And labels, i.e. a list of times
labelName{1}='GB_TestClip_v1_label.csv';
labelName{2}='GB_TestClip_v1_label_mixed_included.csv';
labelName{3}='GB_TestClip_Training_v1_label.csv';
labelName{4}='GB_TestClip_v2_label.csv';
labelName{5}='GB_TestClip_Short_v1_label.csv';
labelName{6}='appendedWith6minNPR.csv';
labelName{7}='appendedWithHour2NPR.csv';
%labelName{6}='GB_TestClip_v1_label_mixed_included.csv';
%labelName{7}='GB_TestClip_v1_label.csv';

labels=csvread(fullfile(dataDir, labelName{trainingDataNumber}));

%% Read in audio file
[~,rootFname] = fileparts(fname{trainingDataNumber});
thisFile = fullfile(dataDir,fname{trainingDataNumber});
disp(['Reading ' thisFile])
[x,Fs]=audioread(thisFile);
t=(0:length(x)-1)/Fs;

% Convert label times to a signal
l=List2Detections(t,labels);

sTrain = ['TrainAudio' num2str(trainingDataNumber)];
iterations = 5000;sIterations = '5K';  

% Enable RAMPdev
ramp_operator_setup;

%% The features
y=Chain(t,x);

%%
% The Thud NN
gap=0;sGap='pt0';
acceptableLatency = .05;sLatency='pt05';
[nnThud,event_indexThud, noise_indexThud]=gb_testClip_train(t,y,l,acceptableLatency,gap,iterations);
nnThud=nnScrub(nnThud);
% Save the neural network with aunique file name
nnName = [sMethod '.' sTrain '.'  sGap '.' sLatency '.' sIterations '.mat']; 
nnTHUD_Name = fullfile(matDir,['nnThud.' nnName]);
save(nnTHUD_Name, 'nnThud','event_indexThud', 'noise_indexThud','gap','acceptableLatency');

%%
% The Shatter NN
gap=.05; sGap = 'pt05';
acceptableLatency = .2;sLatency='pt2'; 
[nnZCR,event_indexZCR, noise_indexZCR]=gb_testClip_train(t,y,l,acceptableLatency,gap,iterations);
nnZCR=nnScrub(nnZCR);
% Save the neural network with aunique file name - note the gap changes
nnName = [sMethod '.' sTrain '.'  sGap '.' sLatency '.' sIterations '.mat']; 
nnShatter_Name = fullfile(matDir,['nnZCR.' nnName]);
save(nnShatter_Name, 'nnZCR','event_indexZCR', 'noise_indexZCR','gap','acceptableLatency');

%[nnThud, nnZCR] = createNeuralNets(ramp, nnChainNumber,gbP,audioFileNumber,trainingDataNumber)

return

function createNeuralNets(ramp,nnChainNumber,gbP,audioFileNumber,trainingDataNumber)


sTrain = ['TrainAudio' num2str(trainingDataNumber)];
gap = 0; sGap = 'pt0';
latency = .2; sLatency = 'pt2';
iterations = 5000;sIterations = '5K';
nnName = [sMethod '.' sTrain '.'  sGap '.' sLatency '.' sIterations '.mat'];  
nnTHUD_Name = fullfile(matDir,['nnThud.' nnName]);
nnZCR_Name = fullfile(matDir,['nnZCR.' nnName]);

return


%%
% Here are all the chains
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
