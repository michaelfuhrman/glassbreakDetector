% Update with pre gain to fix the modelChain mismatch and longer hold

ramp_operator_setup;

% Location to copy repo and build -- will want to manage this process differently
buildDir='rampsim_gb_preroll_2a_holdTime_scaling';

% Define the signal chain
gain = 1/5;
load('nnThud.mat', 'nnThud');
load('nnZCR.mat', 'nnZCR');

[Chain_declareThud, Chain_declareShatter] = gb_model_2020_09_09(ramp, gain, nnThud, nnZCR);

% Preroll compression and decompression
Preroll=ramp.app.prerollrecongb('enable',1);

% Full signal chain that we will build
FullChain=[ramp.ideal.pass(); ...
					 Chain_declareShatter ...
					 > ramp.ops.overhang('up',1e3, 'down',3) ...
					 > ramp.ops.cmp('thresh',.3,'printTimeStamp',1)] ...
					> Preroll > ramp.pin.A3();

% Build into a rampsim binary
options=struct('numChanToOutput',1);
rampSimFile=buildStandaloneModel(FullChain,buildDir,options);

copyfile([buildDir '/bin/rampSim.exe'],'rampSim2_holdTime_scaling.exe');
copyfile([buildDir '/src/compileIn.h'],'compileIn2_holdTime_scaling.h');
