% Test
rampSimBin='rampSim.exe';

% Load test file
inFile = 'GB_TestClip_v1_16000_mixed_included.wav';
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

%{
% Infineon's glass break detector
IASchain=ramp.dsp.infineondetector('sensitivity','v3_1');

% load(outputTarget.mat); % loads variable outputTarget
% filesMatch = sum( (outputTarget>0) ~= (outDetect>0) ) < 100;

% Read the rampsim output that has preroll appended
[out,Fs]=audioread(outFile);

% Plot rampsim output
subplot(2,2,2*i-1); plot(t,in,t,out);
title({'Input and rampsim output',strrep(inFile,'_','')});

% Plot Infineon detection with us and without us
iasDetect=IASchain(t,in);
aspIasDetect=IASchain(t,out);
subplot(2,2,2*i); plot(t,2.5*(outDetect>1.25),t,iasDetect,t,aspIasDetect);
title({'Detections',strrep(inFile,'_','')}); legend('RAMP','IAS','RAMP+IAS')
%}
