function runTestOptimalParameters
% Close all files with open file IDs
fclose all;

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

testOptimalParameters(gbParameters);
            
return
