function performance=EvalChainSetSplSweep(chain,dataset_txl,threshold,dBSPL,latency)
  % Get performance sweeping over dataset for each level in dBSPL
  % Assume for now that the dataset is scaled to -36dBFS = 94dBSPL

  if nargin<5
    latency=[];
  end

  performance=[];

  for i=1:length(dBSPL)
    gain=10^((dBSPL(i)-94)/20);
    [t,y,l]=EvalChainSet(chain,dataset_txl,gain);
    [DetectTimes,LabelTimes,Durations]=ExtractDetections(t,y,l,threshold,latency);
    performance{i}=ExtractDetectionPerformance(DetectTimes,LabelTimes,Durations);
  end
end
