function performance=EvalChainMixDataSNRSweep(chain,dataset1_txl,dataset2_txl,threshold,dBSPL1,dBSPL2,event_time,no_files,targ_fs,latency)
% Get performance sweeping over dataset for each level in dBSPL
% Assume for now that the dataset is scaled to -36dBFS = 94dBSPL

if nargin<8
    latency=[];
end

performance=[];

for i=1:length(dBSPL1)
    for j=1:length(dBSPL2)
        gain1=10^((dBSPL1(i)-94)/20);
        gain2=10^((dBSPL2(j)-94)/20);
        [t,y,l]=EvalChainMixData(chain,dataset1_txl,dataset2_txl,gain1,gain2,event_time,no_files,targ_fs);
        [DetectTimes,LabelTimes,Durations]=ExtractDetections(t,y,l,threshold,latency);
        performance{i}=ExtractDetectionPerformance(DetectTimes,LabelTimes,Durations);
    end
end

