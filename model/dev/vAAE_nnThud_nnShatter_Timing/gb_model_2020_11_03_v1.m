function [ThudChain, ShatterChain] = gb_model_2020_11_03(ramp, nnThud, nnShatter)

 % nnThud is the trained Thud neural net
 % nnShatter is the trained Shatter neural net

 % Replace with my feature vector
 % FeatureChain = ConstructFeatureChain(ramp,gain);
 
 % Parameters mgf code uses
 gbP = setDefaultParameters;
 if ~exist('ThudBeforeShatter', 'var')
     ThudBeforeShatter = 1;
 end
 
 % Thud within this window after shatter is not valid
 ShatterBeforeThudLimit = gbP('ShatterBeforeThudLimit');
 % Thud and shatter onsets may be closely spaced, so delay shatter
 ShatterDelay = gbP('ShatterDelay');

 % Shatter must occur before this time limit
 ThudOverShatterUmbrella = gbP('ThudOverShatterUmbrella');
 %ThudOverShatterUmbrella=.05;
 % Thresholds specific to Thud and Shatter
 THUDTHRESH = ramp.ops.cmp('thresh',gbP('thudThresh'));
 SHATTERTHRESH = ramp.ops.cmp('thresh',gbP('shatterThresh'));
 % Other operators
 CMPpt5 = ramp.ops.cmp('thresh',.5);
 PULSE0001=ramp.ops.pulse('time',1e-6);
 NOT = ramp.logic.gate('type','not');
 AND = ramp.logic.gate('type','and');
 AMPpt4=ramp.ideal.amp('Av',.4);
 
 
 
 FeatureChain = getChainLog(ramp,gbP);
 
 if nargin < 3
     % Didn't receive neural net parameters,
     % so return feature chain for training
     ThudChain = FeatureChain;
     ShatterChain = [];
 else
     
     % Otherwise provide the trained neural network
     % and continue building the full chain
     net_eval_thud=ramp.learn.ideal('nn',nnThud);
     net_eval_zcr=ramp.learn.ideal('nn',nnShatter);
     
     % This is the part of the overall chain that generates the features
     % and the outputs of the neural nets
     Chain_thud=FeatureChain ...
         > net_eval_thud;
     Chain_zcr=FeatureChain ...
         > net_eval_zcr;
     
     % For troubleshooting 
     ThudChain = Chain_thud;
     ShatterChain = Chain_zcr;
     
     %%%%%
     
     if ThudBeforeShatter == 1
         % Explained in main version of code
         wideValidThudPulseChain = [ThudChain > THUDTHRESH > PULSE0001;
             ShatterChain > SHATTERTHRESH > ramp.ops.pulse('time',ShatterBeforeThudLimit) > ramp.ops.delay('delay',ShatterDelay) > NOT] > ...
             AND > NOT > ramp.ops.pulse('time',ThudOverShatterUmbrella);
     else
         
         wideValidThudPulseChain = ThudChain > THUDTHRESH > PULSE0001 > NOT > ramp.ops.pulse('time',ThudOverShatterUmbrella);
     end
     
     UpTime=.1; %.1
     DownTime=.1; %.1
     ShatterPulseChain = ShatterChain > SHATTERTHRESH > ramp.ops.overhang('up',1.25/UpTime, 'down',1.25/DownTime) > CMPpt5 > PULSE0001;
     
     % Don't have t
     %shatterPulse = ShatterPulseChain(t,ynnShatter); % <-- Needed to declare Shatter
     
     
     if ThudBeforeShatter == 1
         validThudPulseChain = [ThudChain > THUDTHRESH > PULSE0001;
             ShatterChain > SHATTERTHRESH > ramp.ops.pulse('time',ShatterBeforeThudLimit)> NOT] > AND > AMPpt4;
     else
         validThudPulseChain = ThudChain > THUDTHRESH > PULSE0001 > AMPpt4;
     end
     
     
     
     %validThudPulse = validThudPulseChain(t,[ynnThud ynnShatter]); % <-- The Thud declaration
     
     %wideValidThudPulse = wideValidThudPulseChain(t,[ynnThud ynnShatter]); % <-- Needed to declare Shatter

     %%% Not sure how to implement this step,,, it doesn't seem to provide the
     %%% same answer as declareShatter
     if 0
         declareShatterChain = [wideValidThudPulseChain;
             ShatterPulseChain] > AND > AMPpt4;
         declareShatterTest = declareShatterChain(t,[ynnThud ynnShatter ynnShatter]);
     end
     %%%
     
     %declareThud = validThudPulse;
     %declareShatter = AMPpt4(t,AND(t,[wideValidThudPulse shatterPulse]));
     
     ThudChain = validThudPulseChain;
     %ShatterChain =ShatterPulseChain> AMPpt4;    
     ShatterChain = [wideValidThudPulseChain;
             ShatterPulseChain] > AND > AMPpt4;
     
 end
end

function chain = Overhang(ramp, rates, thresh)
chain = ramp.ops.overhang('up', rates(1),   'down', rates(2)) ...
    > ramp.ops.cmp('thresh', thresh);
end

function FeatureChain = ConstructFeatureChain(ramp,gain)
% 4kHz BPF > PkDe > Log > {Pass;Baseline]
HiFreq = ramp.ops.bpf('fc',4e3, 'Av',gain) ...
    > ramp.ops.peak('atk',8.13e2, 'dec',143) ... %, 'modelVersion','PDmodelDynamic') ...
    > ramp.ideal.log('in_offset',6e-3) ...
    > [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',30, 'dec',90, 'modelVersion','PDmodelDynamic')];

% 400 Hz BPF > PkDe > Log > {Pass;Baseline]
LoFreq = ramp.ops.bpf('fc',4e2, 'Av',gain) ...
    > ramp.ops.peak('atk',8.13e2, 'dec',54) ... %, 'modelVersion','PDmodelDynamic') ...
    > ramp.ideal.log('in_offset',6e-3) ...
    > [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];

% Chain generates three outputs
FeatureChain = [ramp.ideal.amp('Av',gain) > ramp.ops.zcr(); ...
    [HiFreq(); HiFreq()] > ramp.ideal.minus(); ...
    [LoFreq(); LoFreq()] > ramp.ideal.minus()];
end

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

end

function gbParameters = setDefaultParameters
% Parameter keys for default values below
parameterKeys = {'thudThresh'
    'shatterThresh'
    'hfFC'
    'lfFC'
    'hfEnvAtk'
    'hfEnvDec'
    'lfEnvAtk'
    'lfEnvDec'
    'hfBaseAtk'
    'hfBaseDec'
    'lfBaseAtk'
    'lfBaseDec'
    'ShatterDelay'
    'ThudOverShatterUmbrella'
    'ShatterBeforeThudLimit'
    'ThudPeak'
    'ThudBeforeShatter'
    'SIMPLESHATTERAFTERTHUD'
    'Iterations'
    'TrainingData'
    'TrainingLabels'};

% ThudPeak can take on 3 values: 0, 1, 2
% 0: Sample Thud neural network everywhere
% 1: Sample at high frequency envelope peaks
% 2: Sample at peak of HF-LF envelopes

% The following are all default values which can be
% modified within the nested loops in testOptimalParameters
parameterValues = {.3
    .3
    4000
    400 
    8.13e3
    143
    8.13e2
    54
    20
    90
    20
    90
    .05
    .15
    .2
    2
    1
    0
    5000
    'GB_TestClip_Training_v1_16000'
    'GB_TestClip_Training_v1_label'};

gbParameters = containers.Map(parameterKeys, parameterValues);
end
