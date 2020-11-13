function concatWavFiles
close all
dataDir = '../../../data';
fname{1} = 'GB_TestClip_v1_16000.wav';
fname{2} = 'GB_TestClip_v1_16000_mixed_included.wav';
fname{3} = 'GB_TestClip_Training_v1_16000.wav';
fname{4} = 'GB_TestClip_v2_16000.wav';
fname{5} = 'GB_TestClip_Short_v1_16000.wav';
fname{6}='hour2.wav';
fname{7} = 'first6min.wav';

labelName{1}='GB_TestClip_v1_label.csv';
labelName{2}='GB_TestClip_v1_label_mixed_included.csv';
labelName{3}='GB_TestClip_Training_v1_label.csv';
labelName{4}='GB_TestClip_v2_label.csv';
labelName{5}='GB_TestClip_Short_v1_label.csv';
labelName{6}='hour2.csv';
labelName{7} = 'first6min.csv';

xp = [];
tEnd = 0;
labelsP=[];
for audioFileNumber = [2 3 4 5 6]  %1:length(fname)
        %% Read the labels
    labels=csvread(fullfile(dataDir, labelName{audioFileNumber}));
    labels = labels(:,1:2);
    % Append these labels to last set of labels
    % Get the end time of the last file and push this set of labels back in
    % time
    labelsP = [labelsP;
        labels + tEnd];
    
    %% Read in audio file and labels
    [~,rootFname] = fileparts(fname{audioFileNumber});
    thisFile = fullfile(dataDir,fname{audioFileNumber});
    % x is a column vector
    [x,Fs]=audioread(thisFile);
    t=(0:length(x)-1)/Fs; t=t(:);
    
    % Grab the end time the file that was just read in to add to the next
    % set of labels
    tEnd = t(end)+tEnd;
    xp = [xp;x];
    Fs
    t(end)/60
end
halfHour = 16000*60*30;

xp = xp(1:halfHour,1);

t=(0:length(xp)-1)/Fs; t=t(:);
t(end)/60

labelsP(end,:)=[];

%audiowrite(fullfile(dataDir,'appendedWithHour2NPR.wav'),xp,Fs);
audiowrite(fullfile(dataDir,'FourClipsAppendedWithHour2NPR.wav'),xp,Fs);
% Write the labels

%csvwrite(fullfile(dataDir,'appendedWithHour2NPR.csv'),labelsP);
csvwrite(fullfile(dataDir,'FourClipsAppendedWithHour2NPR.csv'),labelsP);
l=List2Detections(t,labelsP);

%figure;plot(t,xp,t,l,'k')
return


