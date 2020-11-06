function runGlassBreakOptimizeParameters_v2

counter = 1;
AtkDecParams= [8130,143,20,90,813,54,20,90];

% Baseline parameters
A = [143,90,54,90];
% Factorial design for four parameters
B = 1+.1*ff2n(4)';
Bp = [1-.1*ff2n(4)'];
Bp(:,1) = [];
B = [B Bp];

% The first row is
% AtkDecParams= [8130,143,20,90,813,54,20,90];
% All the combinations
AtkDecParams = (A'.*B)';


p=1;
for nnChainNumber = 2 %[0 1 2]
    for audioFileNumber = 1
        for p=1:size(AtkDecParams,1)
            %1:5
            % Provide the Neural Network Chain Number, audio file number
            % Also provide attack and decay parameters and NN thresholds
            % Also timing parameters
            % Return TP and FP before timing
            % Return TP and FP after timing
            
            % Why are the results worse when the baseline is subtracted from
            % the envelope? Look at NN outputs.
            tic
            [thisChainName, ThudScore, ShatterScore] = ...
                glassBreakOptimizeParameters_v2(nnChainNumber,AtkDecParams(p,:), audioFileNumber);
            toc
            disp(['Thud Score: ' num2str(ThudScore)])
            disp(['Shatter Score: ' num2str(ShatterScore)])

            TS(counter,1) = ThudScore;
            SS(counter,1) = ShatterScore;

            counter = counter+1;
            save('scores.mat','AtkDecParams','TS','SS','nnChainNumber','audioFileNumber','counter');
        end
    end
end
save('scores.mat','AtkDecParams','TS','SS','nnChainNumber','audioFileNumber','counter');

% Optimal parameters:
load('scores.mat','AtkDecParams','TS','SS','nnChainNumber','audioFileNumber','counter');

% Satrting with [143,90,54,90];
bestThudParameters = AtkDecParams(find(TS==max(TS)),:)

bestShatterParameters = AtkDecParams(find(SS==max(SS)),:)

bestParameters = [bestThudParameters(:,1:2) bestShatterParameters(:,3:4)];

glassBreakRampDevWithParameters_v2(nnChainNumber,bestParameters,audioFileNumber);

return
