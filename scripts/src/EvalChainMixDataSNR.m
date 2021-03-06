function [t,x,l,spl,snr]=EvalChainMixDataSNR(chain,dataset1_txl,dataset2_txl,dBSPL1,dBSPL2,event_time,no_files,targ_fs)
  % Get performance sweeping over dataset for each level in dBSPL
  % Assume for now that the dataset is scaled to -36dBFS = 94dBSPL

  if nargin<8
    latency=[];
  end

  t=[]; x=[]; l=[]; spl=[]; snr=[];

  for i=1:length(dBSPL1)
    for j=1:length(dBSPL2)
      gain1=10^((dBSPL1(i)-94)/20);
      gain2=10^((dBSPL2(j)-94)/20);
      [t{end+1},x{end+1},l{end+1}]=EvalChainMixData(chain,dataset1_txl,dataset2_txl,gain1,gain2,event_time,no_files,targ_fs);
      spl(end+1)=dBSPL1(i);
      snr(end+1)=dBSPL1(i)-dBSPL2(j);
    end
  end
end
