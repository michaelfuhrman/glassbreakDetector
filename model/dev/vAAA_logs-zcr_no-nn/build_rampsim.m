ramp_operator_setup;

% Location to copy repo and build -- will want to manage this process differently
buildDir='build/rampsim_gb_preroll';

% Define the signal chain
gain = 1/5; prerollOn = 1;
ChainDetector = glassbreak_chain(ramp,gain,prerollOn);

% Build into a rampsim binary
options=struct('numChanToOutput',1);
rampSimFile=buildStandaloneModel(ChainDetector,buildDir,options);
