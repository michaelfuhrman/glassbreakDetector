% Load Infineon glass breaks and Ring glass breaks
ring_glass_dataset=expandVarPath('%AspBox%/engr/sig_proc/Signal_Library/Audio_Signals/Acoustic_Events/Glass_Break/Glassbreak_data_folders/Ring-GBTD-Volume01/01-01-LP-F1-glass_break/dataset.json');
ifx_glass_dataset=expandVarPath('%AspBox%\engr\sig_proc\Signal_Library\Audio_Signals\Acoustic_Events\Glass_Break\mharish\gb_infineon_events\dataset.json');

glass_datasets={ifx_glass_dataset,ring_glass_dataset};

for i=1:length(glass_datasets)
	[t,x,l]=ExtractEventDataset(glass_datasets{i}, ... % Descriptor of the datset
															1, ... % Amount of preroll
															1, ... % Amount of postroll
															-36, ... % dBFS to normalize to
															1, ... % Channel to use from the audio files
															-1, ... % Use full event to extract gain
															expandVarPath('%AspBox%/engr/sig_proc/Projects/External/Infineon/IAS_glassbreak/bdr/aspinity_infineon_gb_bundle_2020.07.20/data/events') ...
														 );
end


addpath(expandVarPath('%AspBox%\engr\sw\proj\RAMPdev\RAMP_Operator_Examples\glass_break_examples\mharish'));

dataset_event=ifx_glass_dataset;
dataset_noise=expandVarPath('%AspBox%\engr\sig_proc\Signal_Library\Audio_Signals\Acoustic_Events\Glass_Break\mharish\noise_data\dataset.json');
dBFS_event=-36;
dBFS_noise=-36;
pre=1;
post=1;
no_files=50;
targ_fs=16000;
save_dir=expandVarPath('%AspBox%/engr/sig_proc/Projects/External/Infineon/IAS_glassbreak/bdr/aspinity_infineon_gb_bundle_2020.07.20/data/mixed');
[t,x,l]=CreateMixData(dataset_event,dataset_noise,dBFS_event,dBFS_noise,pre,post,no_files,targ_fs,save_dir);


% Go through the directories and resample to 16k
baseDir=expandVarPath('%AspBox%\engr\sig_proc\Projects\External\Infineon\IAS_glassbreak\bdr\aspinity_infineon_gb_bundle_2020.07.20\data');
dirs=dir(baseDir);
for d=1:length(dirs)
	if dirs(d).isdir
		cdir=[baseDir '/' dirs(d).name];
		files=dir([cdir '/*.wav']);
		for f=1:length(files)
			[x,Fs]=audioread([cdir '/' files(f).name]);
			if max(x)<1e-3
				delete([cdir '/' files(f).name]);
			elseif Fs~=16e3
				t=(0:(length(x)-1))/Fs; tI=0:1/16e3:t(end); xI=interp1(t,x,tI);
				audiowrite([cdir '/' files(f).name],xI,16e3);
			end
		end
		branchDir=pwd;
		cd(cdir);
		bashCall('rm *.json');
		cd(branchDir);
	end
end

