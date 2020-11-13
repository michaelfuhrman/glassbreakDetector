function [ThudChain, ShatterChain] = gb_model_2020_11_03(ramp, nnThud, nnShatter)

 % nnThud is the trained Thud neural net
 % nnShatter is the trained Shatter neural net
 
 % Parameters the code uses. It's located below.
 gbP = setDefaultParameters;
 ThudBeforeShatter = gbP('ThudBeforeShatter');
 
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
 PASS=ramp.ideal.pass();
 
 % getChainLog is below
 FeatureChain = getChainLog(ramp,gbP);
 if nargin < 3
     % Didn't receive neural net parameters,
     % so return feature chain for training
     ShatterChain = FeatureChain;
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
     
     if ThudBeforeShatter == 1
         if 0 
             % This doesn't work, it yields an empty chain
             wideValidThudPulseChain = [Chain_thud > THUDTHRESH > PULSE0001;
                 Chain_zcr > SHATTERTHRESH > ramp.ops.pulse('time',ShatterBeforeThudLimit) > ramp.ops.delay('delay',ShatterDelay) > NOT] > ...
                 AND > NOT > ramp.ops.pulse('time',ThudOverShatterUmbrella);
         else
             num = THUDTHRESH > PULSE0001;
             denom = SHATTERTHRESH > ramp.ops.pulse('time',ShatterBeforeThudLimit) > ramp.ops.delay('delay',ShatterDelay) > NOT;
             
             % This works
             wideValidThudPulseChain = [Chain_thud > num;
                                         Chain_zcr > denom] > ramp.logic.gate('type','and') > NOT > ramp.ops.pulse('time',ThudOverShatterUmbrella);
         end
         
         if 0
             % Chain without the  neural networks prepended in case we need to use it
             num = THUDTHRESH > PULSE0001;
             denom = SHATTERTHRESH > ramp.ops.pulse('time',ShatterBeforeThudLimit) > ramp.ops.delay('delay',ShatterDelay) > NOT;
             Chain1 = [num;denom] > ...
                 ramp.logic.gate('type','and') > NOT > ramp.ops.pulse('time',ThudOverShatterUmbrella);
             % With this chain, this construct works too:
             wideValidThudPulseChain = [Chain_thud;Chain_zcr] > Chain1;
         end

     else     
         wideValidThudPulseChain = Chain_thud > THUDTHRESH > PULSE0001 > NOT > ramp.ops.pulse('time',ThudOverShatterUmbrella);
     end
     
     % This works
     UpTime=.1;
     DownTime=.1;
     ShatterPulseChain = Chain_zcr > SHATTERTHRESH > ramp.ops.overhang('up',1.25/UpTime, 'down',1.25/DownTime) > CMPpt5 > PULSE0001;
     
     if ThudBeforeShatter == 1
         if 0
             % This does not work, it yields an empty chain
             validThudPulseChain = [Chain_thud > THUDTHRESH > PULSE0001;
                 Chain_zcr > SHATTERTHRESH > ramp.ops.pulse('time',ShatterBeforeThudLimit)> NOT] > AND > AMPpt4;
         else
             % This is working, and we are hitting these steps
             num = THUDTHRESH > PULSE0001;
             denom = SHATTERTHRESH > ramp.ops.pulse('time',ShatterBeforeThudLimit)> NOT;
             validThudPulseChain = [Chain_thud > num;
                                        Chain_zcr > denom] > AND > AMPpt4;
         end
         
         if 0
             % This construct doesn't work. The input chains need to be
             % within the brackets
             validThudPulseChain_tmp = [num;
                                      denom] > AND > AMPpt4;
              validThudPulseChain = [Chain_thud;Chain_zcr] > validThudPulseChain_tmp;
         end
     else
         % This works when we don't constrain Thud before Shatter
         validThudPulseChain = Chain_thud > THUDTHRESH > PULSE0001 > AMPpt4;
     end
          
     % This is working    
     ThudChain = validThudPulseChain;
     
     % This very last construct (the most important) is not working
     ShatterChain = [wideValidThudPulseChain;
                        ShatterPulseChain] > AND > AMPpt4;
                    
     % To view chains              
     % ThudChain
     % ShatterChain
     % wideValidThudPulseChain
     % ShatterPulseChain
 end
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

