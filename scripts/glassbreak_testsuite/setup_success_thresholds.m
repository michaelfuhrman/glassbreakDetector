function success_thresholds=setup_success_thresholds(datapath)
% Function to setup default success thresholds in struture that
% GB_Test_Suite_Results() understands
%   datapath: Structure containing path to data as well as SPL and SNR
%             levels which have been used to test the data. The SPL and SNR
%             levels are used to define the struture that sets default 
%             thresholds

% Setting default SPL sweep success thresholds
success_thresholds.spl_sweep.spl=datapath.event_spl_array;
success_thresholds.spl_sweep.eventRequirement=0*datapath.event_spl_array+100;%percent
success_thresholds.spl_sweep.latencyRequirement=0*datapath.event_spl_array+0.1;%s
success_thresholds.spl_sweep.interferer_spl=datapath.event_spl_array;
success_thresholds.spl_sweep.interfererRequirement=0*datapath.event_spl_array+0;%percent
success_thresholds.spl_sweep.interferer_latencyRequirement=0*datapath.event_spl_array+0.1;%s

% Setting default SNR sweep success thresholds
success_thresholds.snr_sweep.snr=datapath.snr_array;
success_thresholds.snr_sweep.eventRequirement=0*datapath.snr_array+100;%percent
success_thresholds.snr_sweep.latencyRequirement=0*datapath.snr_array+0.1;%s

% Setting default FAR sweep thresholds
success_thresholds.far_sweep.spl=datapath.noise_spl_array;
success_thresholds.far_sweep.fonRequirement=0*datapath.noise_spl_array+10;%seconds
success_thresholds.far_sweep.fcountRequirement=0*datapath.noise_spl_array+100;%triggers
end