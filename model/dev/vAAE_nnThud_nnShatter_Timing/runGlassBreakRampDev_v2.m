function runGlassBreakRampDev_v2

counter = 1;
for nnChainNumber = [0 1 2]
    for audioFileNumber = 1:5
        % Provide the Neural Network Chain Number, audio file number
        % Also provide attack and decay parameters and NN thresholds
        % Also timing parameters
        % Return TP and FP before timing
        % Return TP and FP after timing
        
        % Why are the results worse when the baseline is subtracted from
        % the envelope? Look at NN outputs.
        
        [thisChainName, thisTP, thisFP] = glassBreakRampDev_v2(nnChainNumber,audioFileNumber);
        ChainName{counter} = thisChainName;
        TP(counter,1) = thisTP;
        TF(counter,1) = thisFP;
        counter = counter+1;
    end
end
return
