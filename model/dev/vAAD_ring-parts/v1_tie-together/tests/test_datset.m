% % % Foreground events start at 0.5s
% % path_fg_tp = expandVarPath('%AspBox%\engr\sig_proc\Signal_Library\Audio_Signals\Acoustic_Events\Glass_Break\Dataset\Test_dataset_glassbreak');
% % path_fg_fp = expandVarPath('%AspBox%\engr\sig_proc\Signal_Library\Audio_Signals\Acoustic_Events\Glass_Break\Dataset\Test_dataset_disturbers');
% % path_bg    = expandVarPath('%AspBox%\engr\sig_proc\Signal_Library\Audio_Signals\Acoustic_Events\Glass_Break\Dataset\Test_dataset_background');

% ramp_operator_setup;
% ds_fg_tp = expandVarPath('%AspBox%\engr\sig_proc\Signal_Library\Audio_Signals\Acoustic_Events\Glass_Break\Dataset\test_dataset_glassbreak.json');
% ds_fg_fp = expandVarPath('%AspBox%\engr\sig_proc\Signal_Library\Audio_Signals\Acoustic_Events\Glass_Break\Dataset\test_dataset_disturbers.json');
% ds_bg    = expandVarPath('%AspBox%\engr\sig_proc\Signal_Library\Audio_Signals\Acoustic_Events\Glass_Break\Dataset\test_dataset_background.json');
% [t, x, l] = LoadDataset(ds_bg);

% dBspl = 64;
% scale = 10.^((dBspl - 94) / 20);
% Fs = 16e3;
% i = 43;
% x_in = x(i) * scale;
% sig_in = [x_in -x_in]+1.024;
% yHW = ADaoutIn(sig_in, 1:2, Fs, max(t(1)));


% % Find the cross-correlation peak that shows where they are aligned
% [xc, lag] = xcorr(x_in, yHW(:,1) - mean(yHW(:,1)));
% n = find(xc == max(xc));

% % This is the time shift between the signals
% t_shift_correction = lag(n(1)) / Fs;

% % Use this time vector for the shifted signal
% t_correct = t(i) + t_shift_correction;


% ax1 = subplot(2, 1, 1); plot(t(i), sig_in(:, 1), t_correct, yHW(:, 1));
% ax2 = subplot(2, 1, 2); plot(t(i), l(i)*2.8, t_correct, yHW(:, 2));
% linkaxes([ax1, ax2], 'x');


% create_netlist

full_time = tic;
id = a1em_read('ID');
% 34 minutes for two
test_datset_fg_tp
save(sprintf('test_dataset_fg_tp_shatter_declare_id%d_run1', id), 'dBspls', 'metrics');
test_datset_bg
save(sprintf('test_dataset_bg_shatter_declare_id%d_run1', id), 'dBspls', 'metrics');
% test_datset_fg_fp
% save(sprintf('test_dataset_fg_fp_shatter_declare_id%d_run1', id), 'dBspls', 'metrics');

toc(full_time)
