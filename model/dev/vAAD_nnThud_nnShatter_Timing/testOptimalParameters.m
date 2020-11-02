function testOptimalParameters(gbP) 
% Driver for glassBreakRampDevWithParameters_v3
% They are not used at the moment but we have control over the baseline
% attack and decay parameters.
% The parameters used are:
%   1) the nnChainNumber (only these four are really run
%       -1 to use Brandon's single NN
%        0 sMethod='LogMinusBaselineAndZCR' (3 signals)
%        1 sMethod='LogBaselineAndZCR' (5 signals)
%        2 sMethod='TanhBaselineAndZCR'; (5 signals)
%   2) The baseline attack and decay parameters if desired
%   3) The audioFileNumber
%   4) THUDPEAK, whether to sample the Thud NN at high frequency peaks
%         This seems to offer the best results

% Might use the date and time as part of a file naming convention
% startTime = datestr(now,30);

% Choices
% Sample Thud at HF peaks or not
% NN Chain we want to test

% 0 or 1: Thud associated with HF peak
% Use
% [0 0]
% [1 0]
% [0 1]
% [1 1]
%THUDPEAK=0;
% 0 or 1: Simple Timing or a little more sophistication
%SIMPLESHATTERAFTERTHUD=0;

if 0
    % Starting from scratch so remove the existing files in this directory
    if exist('GlassbreakResults.csv','file')
        delete('GlassbreakResults.csv');
    end
    if exist('GlassbreakResults.md','file')
        delete('GlassbreakResults.md');
    end
end


if 0 % The optimal parameters were not very optimal:
    
    load('scores.mat','AtkDecParams','TS','SS','nnChainNumber','audioFileNumber','counter');
    bestThudParameters = AtkDecParams(find(TS==max(TS)),:);
    bestShatterParameters = AtkDecParams(find(SS==max(SS)),:);
    bestParameters = [bestThudParameters(:,1:2) bestShatterParameters(:,3:4)];
    
    % These were the original nominal parameters which we're sticking with.
    bestParameters = [143,90,54,90];
end
% For reference
% nnChainNumer 0: 'LogMinusBaselineAndZCR'
% nnChainNumer 1: 'LogBaselineAndZCR'
% nnChainNumer 2: 'TanhBaselineAndZCR'

% Test changing
% gbP('ShatterBeforeThudLimit')=.2;
% gbP('ThudOverShatterUmbrella')=.150;
% gbP('ShatterDelay')=.2;
%gbP('thudThresh')=.5;

% If gbP('TrainingData') == [] the training data will be 'self' 
%gbP('TrainingData')=[];
% the default is GB_TestClip_Training_v1_16000
% Group by chain, then by processing method
for nnChainNumber = 1 %[1 2] %[0 1 2]
    for THUDPEAK = [0 1 2 3]
        % Loop through all the audio files
        for audioFileNumber = [1 2 3 4 5 6 7]
            gbP('ThudPeak')=THUDPEAK;
            glassBreakRampDevWithParameters_v3(nnChainNumber,gbP,audioFileNumber);
        end
    end
end

rootTableName = 'GBResults';
csvFinalFileName = [rootTableName '.csv'];
mdFinalFileName = [rootTableName '.md'];

% Prepend the glassbreak results with a header
command = ['type ResultsHeader.csv  GlassbreakResults.csv > ' csvFinalFileName];
system(command);

% The md file
% Prepend the glassbreak results with a header
command = ['type ResultsHeader.md  GlassbreakResults.md > ' mdFinalFileName];
system(command);

% Then copy or move the file to the TabularResults folder
command = ['copy ' csvFinalFileName ' .\TabularResults\' csvFinalFileName];
system(command);

command = ['copy ' mdFinalFileName ' .\TabularResults\' mdFinalFileName];
system(command);

return