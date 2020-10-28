ramp_operator_setup;

% Parts summary
% - 68 - sent to Ring
% - 66 - sent to Ring
% - 64 - sent to Ring
% - 67 - sent to Ring

% 'test_dataset_fg_tp_thud_declare_id68_run0', ...
% 'test_dataset_fg_fp_shatter_declare_id68_run0', ...

results_files = { ...
  'test_dataset_bg_shatter_declare_id68_run0', ...
  'test_dataset_fg_tp_shatter_declare_id68_run0', ...
	...
  'test_dataset_bg_shatter_declare_id66_run1', ...
  'test_dataset_fg_tp_shatter_declare_id66_run1', ...
	...
  'test_dataset_bg_shatter_declare_id64_run1', ...
  'test_dataset_fg_tp_shatter_declare_id64_run1', ...
	...
  'test_dataset_bg_shatter_declare_id67_run1', ...
  'test_dataset_fg_tp_shatter_declare_id67_run1', ...
};

close all;

for r=1:length(results_files)
	load( results_files{r} );
	% Loads `metrics` & `dBspls`

	tokens      = regexp(results_files{r}, ...
											 'dataset_([_a-z]*)_([a-z]*)_declare_id([0-9]*)_run([0-9])', ...
											 'tokens');
	test_type   = tokens{1}{1};
	output_type = tokens{1}{2};
	ramp_id     = str2num( tokens{1}{3} );
	run         = str2num( tokens{1}{4} );

	% Load the test set
	base_dir = ['%AspBox%\engr\sig_proc\Signal_Library\' ...
								'Audio_Signals\Acoustic_Events\Glass_Break\Dataset'];

	switch test_type
		case 'bg'
			ds = expandVarPath([base_dir '/test_dataset_background.json']);
		case 'fg_fp'
			ds = expandVarPath([base_dir '/test_dataset_disturbers.json']);
		case 'fg_tp'
			ds = expandVarPath([base_dir '/test_dataset_glassbreak.json']);
	end

	[t, x, l] = LoadDataset(ds);

	results = [];
	for d = 1:length(dBspls)
		edges = struct('DetectTimes', [], 'LabelTimes', [], 'Duration', 0);
		for f = 1:size(metrics.labels, 1)
			all_detections   = metrics.detections{f, d};
			valid_detections = all_detections(all_detections(:, 2) > 0.6, :);
			edges.DetectTimes = [edges.DetectTimes; ...
													 edges.Duration + valid_detections];
			edges.LabelTimes = [edges.LabelTimes; ...
													edges.Duration + metrics.labels{f, d}];
			edges.Duration += max( t(f) );
		end
		res_metrics = get_metrics_local(edges, []);

		results.dBspl(d) = dBspls(d);
		results.event_tpr(d) = mean(res_metrics.EventDet(:, 1) > -1);
		results.event_latency(d) = mean(res_metrics.EventLatency( res_metrics.EventLatency<1 ));
		results.false_triggers_per_min(d) = res_metrics.FalseTriggers / edges.Duration * 60;
	end


	switch test_type
		case 'bg'
			subplot(3, 1, 3); plot(results.dBspl, results.false_triggers_per_min, 'o-'); hold on;
			xlabel('SPL (dB)'); ylabel('False Triggers Per Minute');
		case 'fg_tp'
			subplot(3, 1, 1); plot(results.dBspl, 100*results.event_tpr, 'o-'); hold on;
			xlabel('SPL (dB)'); ylabel('Events Detected');
			title(strrep(test_type, '_', ' '));
			subplot(3, 1, 2); plot(results.dBspl, results.event_latency, 'o-'); hold on;
			xlabel('SPL (dB)'); ylabel('Mean Latency');
	end
end
subplot(3, 1, 1); legend('68', '66', '64', '67', 'Location', 'SouthEast');

