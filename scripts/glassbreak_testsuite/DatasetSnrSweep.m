function sweep_sigarray = DatasetSnrSweep(dataset_path,noise_path,SPL_event,SPL_noise,chain)
% Function to sweep through SPL levels for datasets
%   dataset_path: Path to the event dataset
%   noise_path: Path to the noise dataset
%   SPL_event: Array containing SPL levels to sweep through for event
%   dataset
%   SPL_noise: Array containing SPL levels to sweep through for noise
%   dataset
%  	chain: Signal chain used to evaluate the signal during the SNR sweep

sweep_sigarray=[];
% Load event dataset
% Depending on options, load from dropbox/cloud for given dataset
if dataset_path
    dataset_event=expandVarPath(dataset_path);
else
    %Fill up big query cloud part
end
if noise_path
    dataset_noise=expandVarPath(noise_path);
else
    %Fill up big query cloud part
end
jsonFile=json_read(dataset_event);
[t,x,l]=LoadDataset(dataset_event);
dataset1_txl.t=t; dataset1_txl.x=x; dataset1_txl.l=l; dataset1_txl.jsonFile=jsonFile;

jsonFile=json_read(dataset_noise);
[t,x,l]=LoadDataset(dataset_noise);
dataset2_txl.t=t; dataset2_txl.x=x; dataset2_txl.l=l; dataset2_txl.jsonFile=jsonFile;
% Run test
insert_event_time=0.5;%seconds
no_files=50;
targ_fs=16000;
[sweep_sigarray.t,sweep_sigarray.x,sweep_sigarray.l,sweep_sigarray.SPL,sweep_sigarray.SNR]=EvalChainMixDataSNR(chain,dataset1_txl,dataset2_txl,SPL_event,SPL_noise,insert_event_time,no_files,targ_fs);
end