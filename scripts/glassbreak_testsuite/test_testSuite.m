% Test suite example program
ramp_operator_setup;
base = 'PATH/TO/glassbreak/scripts/';
addpath([base '/src']);
addpath([base '/glassbreak_testsuite']);

% Create the chain
Chain=ramp.ops.peak();

% Pass the chain through the test bench to get results in the 'res'
% variable. Paths to the test bench needs to be given in 'datapath'
% Either relative path given, or dropbox path or big query
datapath.eventset='%AspBox%\engr\sig_proc\Signal_Library\Audio_Signals\Acoustic_Events\Glass_Break\Dataset\test_dataset_glassbreak.json';
datapath.interfererset='%AspBox%\engr\sig_proc\Signal_Library\Audio_Signals\Acoustic_Events\Glass_Break\Dataset\test_dataset_disturbers.json';
datapath.noiseset='%AspBox%\engr\sig_proc\Signal_Library\Audio_Signals\Acoustic_Events\Glass_Break\Dataset\test_dataset_background.json';
datapath.event_spl_array=[85:5:110];
datapath.snr_array=[-5,0,5,10];
datapath.noise_spl_array=[65:5:95];

res=GB_Test_Suite(ramp, 'test', Chain, 1, 1, datapath); %save result mat file if required

% Plot results in both tabular and graphical form
% The first 1 in the arguments is to plot graphical results and the second
% for tabular results
table=GB_Test_Suite_Results(res,1,1);

set_sucess_thresh=0;
% Plot the results along with success thresholds (should be set) to compare the performance
% of the model to our vision for the model
if set_sucess_thresh
    
    success_thresholds=setup_success_thresholds(datapath);

    table=GB_Test_Suite_Results(res,1,1,success_thresholds);
end