net = timing_logic_netlist(lib);

[testSW, testHW]=structure_parse(lib, net, [], [], [], [], []);

T = 1; Fs = 16e3; t = transpose(0:1/Fs:T);
times = {};
times{end+1} = struct('thud', [0.1 0.11], 'shatter', []);   % thud alone
times{end+1} = struct('thud', [0.2 0.21], 'shatter', [0.21 0.22]);  % thud, then shatter
times{end+1} = struct('thud', [0.3 0.31], 'shatter', [0.29 0.3; 0.31 0.32]);  % shatter - thud, then shatter

test_sig = zeros(length(t), 2);

for i=1:length(times)
	test_sig(:,1) = test_sig(:,1) + (t > times{i}.thud(1) & t < times{i}.thud(2));
	for j=1:size(times{i}.shatter, 1)
		test_sig(:,2) = test_sig(:,2) ...
										+(t > times{i}.shatter(j, 1) ...
											& t < times{i}.shatter(j, 2));
	end
end
test_sig = 3 * (test_sig > 0.5);

ySW = runNetlist(testSW, test_sig, Fs);
ramp_compile(testHW, ramp_ic);
yHW = ADaoutIn(test_sig, 1:2, Fs, T);

xl = [.05 .35];
subplot(3, 1, 1); plot(t, test_sig); xlim(xl);
xlabel('Time (s)'); ylabel('Inputs'); legend('thud cmp', 'shatter cmp');
subplot(3, 1, 2); plot(t, ySW); xlim(xl);
xlabel('Time (s)'); ylabel('ramp sim'); legend('thud declare', 'shatter declare');
subplot(3, 1, 3); plot(t, yHW); xlim(xl);
xlabel('Time (s)'); ylabel('ramp hw'); legend('thud declare', 'shatter declare');
