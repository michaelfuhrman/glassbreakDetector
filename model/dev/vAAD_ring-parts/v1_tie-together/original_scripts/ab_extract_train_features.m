addpath ../setup_audio
num_files = 100;

% Create netlist
[net_train, features_list] = netGen_gb(lib, ramp_ic, []);
[testSW, testHW]=structure_parse(lib, net_train, [], [], [], [], []);

% % Loop over files
% tstep = 80;
% feat = []; lab = [];
% stat = struct('in', struct('max', [], 'mean', [], 'std', []), ...
% 						  'feat', struct('max', [], 'mean', [], 'std', []));
% for f = 1 : num_files
% 	[t, x, l_list] = training_mix();
% 	stat.in.max(end+1) = max(x);
% 	stat.in.mean(end+1) = mean(x);
% 	stat.in.std(end+1) = std(x);
% 	l = List2Detections(transpose(t), l_list);
% 	Fs = 1 / diff(t(1:2));
% 	y = runNetlist(testSW, x, Fs);
% 	yf = y(:, 1:2:end) - y(:, 2:2:end);
% 	stat.feat.max(end+1, :)		= max(yf);
% 	stat.feat.mean(end+1, :)	= mean(yf);
% 	stat.feat.std(end+1, :)		= std(yf);

% 	n = find(t > 1);
% 	n = 1 : tstep : length(t);
% 	feat = [feat; yf(n, :)];
% 	lab = [lab; l(n)];

% 	subplot(2, 1, 1);
% 	plot(t(1:50:end), x(1:50:end), ...
% 			 t(1:50:end), l(1:50:end) * max(x));
% 	title(sprintf('%d of %d', f, num_files));
% 	subplot(2, 1, 2);
% 	% bot = max(x);
% 	% for p = 1:size(yf, 2)
% 	% 	plot(t(1:50:end), yf(1:50:end,p) + bot);
% 	% 	hold on;
% 	% 	bot = bot + max(yf(t>2, p));
% 	% end
% 	% hold off;
% 	plot(t(1:50:end), yf(1:50:end, :), ...
% 			 t(1:50:end), l(1:50:end) * max(yf(:)));
% 	drawnow; pause(.05);
% end


%% Simple audio file for features
run ../setup_audio/setup_mixed_audio
y = runNetlist(testSW, [x -x], Fs);
yf = y(:, 1:2:end) - y(:, 2:2:end);
tstep = 20;
n = find(t > 1);
n = 1 : tstep : length(t);
feat = [yf(n, :)];
lab = [lab(n)];

FsFeat = 1 / (diff( t(1:2) ) * tstep);
t = (0 : size(feat, 1) - 1) / FsFeat;




%% Save
save -binary train_features feat FsFeat t lab
% save train_features_stat stat
