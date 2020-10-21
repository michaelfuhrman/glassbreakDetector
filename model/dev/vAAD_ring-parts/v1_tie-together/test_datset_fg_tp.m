% Takes 20 minutes to run
test_time = tic;

more off;

ramp_operator_setup;
ds_fg_tp = expandVarPath('%AspBox%\engr\sig_proc\Signal_Library\Audio_Signals\Acoustic_Events\Glass_Break\Dataset\test_dataset_glassbreak.json');
[t, x, l] = LoadDataset(ds_fg_tp);

dBspls = [64 74 84 94 104 114];
dBspls = [74 84 94 104];
metrics.detections = [];
metrics.labels = [];

for i = 1:25 %length(t)
	for d = 1:length(dBspls)
		scale = 10.^((dBspls(d) - 94) / 20);
		Fs = 16e3;
		x_in = [zeros(8e3, 1); x(i)];
		l_in = [zeros(8e3, 1); l(i)];
		t_in = (0:(length(x_in)-1))/Fs; t_in = transpose(t_in);
		x_in = x_in * scale;
		x_in = dc_blocker(x_in - x_in(1), t_in, 20, 2);
		sig_in = [x_in -x_in]+1.024;
		yHW = ADaoutIn(sig_in, 1:2, Fs, max(t_in));


		% Find the cross-correlation peak that shows where they are aligned
		[xc, lag] = xcorr(x_in, yHW(:,1) - mean(yHW(:,1)));
		n = find(xc == max(xc));

		% This is the time shift between the signals
		t_shift_correction = lag(n(1)) / Fs;

		% Use this time vector for the shifted signal
		t_correct = t_in + t_shift_correction;

		detections = (yHW(:, 2)>1) .* (t_correct>0.5);

		ax1 = subplot(2, 1, 1); plot(t_in, sig_in(:, 1), t_correct, yHW(:, 1));
		title(sprintf('File %d:%d; SPL %d:%d', i, length(t), d, length(dBspls)));
		ax2 = subplot(2, 1, 2); plot(t_in, l_in*0.8, t_correct, detections);
		linkaxes([ax1, ax2], 'x');
		drawnow(); pause(.01);

		metrics.detections{i, d}	= Detection2List(t_correct, detections);
		metrics.labels{i, d}			= Detection2List(t_in, l_in);
		printf('*** File %d:%d; SPL %d:%d***\n', i, length(t), d, length(dBspls));
		printf('  Detections\n');
		for r=1:size(metrics.detections{i, d})
			printf('    %d - %d\n', metrics.detections{i, d}(r, 1), metrics.detections{i, d}(r, 2));
		end
		printf('  Labels\n');
		for r=1:size(metrics.labels{i, d})
			printf('    %d - %d\n', metrics.labels{i, d}(r, 1), metrics.labels{i, d}(r, 2));
		end
	end
end

% save test_dataset_fg_tp_shatter_declare_id68_run0 dBspls metrics; % A few hours after programming
%save test_dataset_fg_tp_shatter_declare_id67_run0 dBspls metrics; % Recently programmed
% save test_dataset_fg_tp_thud_declare_id68_run0 dBspls metrics; % Recently programmed

toc(test_time)
