% Test
% buildDir variable comes from build_rampsim.m
rampSimBin=expandVarPath(['%AspBox%/engr/sig_proc/Projects/External/Infineon/IAS_glassbreak/bdr/bundle_build/' buildDir '/bin/rampSim.exe']);

% Load test file
wavFiles={ ...
					 'GBTD-01-01-LP-gb1_000.wav', ...
					 'overdriven_glass_break_1_000_a003_30_60_000.wav'};
inFile = wavFiles{1};
[in,Fs]=audioread(inFile);
t=(0:(length(in)-1))/Fs;

% Run through rampsim
outFile='out.wav';
cmd=sprintf('"%s" "%s" "%s"',rampSimBin,inFile,outFile);
[~,output]=system(cmd);

% Extract the detections from stdout
% For some reason, Octave is not capturing the stdout on windows like Matlab did
triggersCell=regexp(output,'Event trigger from ([.0-9]*)s to ([.0-9]*)s','tokens');
triggers=[];
for j=1:length(triggersCell)
	triggers(j,1)=str2num(triggersCell{j}{1});
	triggers(j,2)=str2num(triggersCell{j}{2});
end
outDetect=2.5*List2Detections(t,triggers);

load prebuild_outputs.mat
fprintf('Matlab eval to sim build mismatched points = %d\n',sum(yMatlab(:) ~= outDetect(:)));

