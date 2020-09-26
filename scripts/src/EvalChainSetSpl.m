function [t,x,l]=EvalChainSetSpl(chain,dataset_txl,dBSPL)
  % Get output sweeping over dataset for each level in dBSPL
  % Assume for now that the dataset is scaled to -36dBFS = 94dBSPL

  t=[]; x=[]; l=[];

  for i=1:length(dBSPL)
    gain=10^((dBSPL(i)-94)/20);
    [t{i},x{i},l{i}]=EvalChainSet(chain,dataset_txl,gain);
  end
end
