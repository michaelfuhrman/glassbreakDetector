ramp_operator_setup;

% Load test file
wavFiles={ ...
           'GBTD-01-01-LP-gb1_000.wav', ...
           'overdriven_glass_break_1_000_a003_30_60_000.wav'};
inFile = wavFiles{1};
[in,Fs]=audioread(inFile);
t=(0:(length(in)-1))/Fs;

% Build detector-only chain for tests
gain = 1; prerollOn = 0;
ChainDetector = glassbreak_chain(ramp,gain,prerollOn);

% Get results for the chain w/ Matlab eval
yMatlab = ChainDetector(t,in); % This is our reference point

% Get results for the chain w/ generic rampsim build (i.e. we supply netlist at run time)
ySimNetlist = modelChain(ChainDetector,t,in);

% Check matching between Matlab and sim
fprintf('Matlab eval to sim netlist mismatched points = %d\n',sum(yMatlab ~= ySimNetlist));

save prebuild_outputs.mat yMatlab ySimNetlist
