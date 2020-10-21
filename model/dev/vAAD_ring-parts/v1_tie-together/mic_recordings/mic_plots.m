Fs = 48e3;

% load record_micPos_laminated
% load record_micPos_plate
% % load record_micPos_tempered
% t = (0:(length(v)-1))/Fs;
% plot(t, v-v(1))
% audiowrite('record_micPos_plate.wav', v-v(1), Fs);

% load record_diffamp_preroll_5xgain_plate
% % load record_diffamp_preroll_nogain_plate
% t = (0:(length(y)-1))/Fs;
% % plot(t, y(:,2))
% plot(t, y)
% audiowrite('record_diffamp_plate.wav', y(:,2)-y(1,2), Fs);

% % Test through IFX glass break engine
% bin = '../../../../release/asp_ias_gb_sim_v0.0.1/bin/ifx_ias_simulator_v0.3.1/ias_simulator_v031_20200716_08756ca';
% [e,m] = bashCall([bin ' record_diffamp_plate16k.wav'])
% %  ---- List of glassbreaks detected ----
% %  ---- glassbreak[0] at 3.49s ----
% %  ---- glassbreak[1] at 5.03s ----
% %  ---- glassbreak[2] at 6.82s ----
% [e,m] = bashCall([bin ' record_diffamp_plate16k.wav'])
% %  ---- List of glassbreaks detected ----
% %  ---- glassbreak[0] at 3.49s ----
% %  ---- glassbreak[1] at 5.03s ----
% %  ---- glassbreak[2] at 6.82s ----


% % load record_bpf1k_laminated
% % load record_bpf400_laminated
% load record_bpf4k_plate
% t = (0:(length(y)-1))/Fs;
% % plot(t, fliplr(y))
% plot(t, y(:,1))


% load record_rms1k_laminated
% % load record_rms400_laminated
% % load record_rms4k_plate
% t = (0:(length(y)-1))/Fs;
% plot(t, y(:,2))

% load record_rms400_log_wired
% % load record_rms4k_log_wired
% t = (0:(length(y)-1))/Fs;
% plot(t, y(:,2))

load record_nnShatter_tempered
% load record_nnThud_tempered

t = (0:(length(y)-1))/Fs;
plot(t, y(:,2))
