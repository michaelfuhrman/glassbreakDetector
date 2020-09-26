function sweep_sigarray = DatasetSplSweep(dataset_path,sweepSPL,chain)
% Function to sweep through SPL levels for datasets
%   dataset_path: Path to the dataset
%   sweepSPL: Array containing SPL levels to sweep through
%  	chain: Signal chain used to evaluate the signal during the SPL sweep

sweep_sigarray=[];
% Load event dataset
% Depending on options, load from dropbox/cloud for given dataset
if dataset_path
    dataset=expandVarPath(dataset_path);
else
    %Fill up big query cloud part
end
[t,x,l]=LoadDataset(dataset);
dataStruct=json_read(dataset);
dataset_txl.t=t; dataset_txl.x=x; dataset_txl.l=l; dataset_txl.jsonFile=dataStruct;

% Run sweep
[sweep_sigarray.t,sweep_sigarray.x,sweep_sigarray.l]=EvalChainSetSpl(chain,dataset_txl,sweepSPL);
sweep_sigarray.SPL=sweepSPL; sweep_sigarray.SNR=NaN*sweepSPL;
end