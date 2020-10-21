addpath('~/Desktop/brandon-scratch/sw/ml/vAAA_weight_scaling/ramp_nn');
import_audio;
% run ../setup_audio/setup_mixed_audio

nn = nnF;
% nn.macs{end}.b = nn.macs{end}.b - 0.01;
nn.out_scale.W = 2;
nn.out_scale.b = 0;
for i = 1:length(nn.macs)
	nn.W{i} = nn.macs{i}.W;
	nn.b{i} = nn.macs{i}.b;
	switch nn.act{i}.type
		case 'tanh'
			nn.activation_functions(i) = 2;
		case 'sigd'
			nn.activation_functions(i) = 1;
	end
end
nn.num_inputs = size(nn.W{1},2);
nn.num_outputs = size(nn.W{end},1);
nn.hw.W = nn.W;
nn.hw.b = nn.b;

% Run trained setup
% x = speaker_response(t, x);
net_train = netGen_gb(lib, ramp_ic, nn);
net_train_tmp = net_train;
net_train_tmp.out{end+1} = struct('net', 'shatter_filt', 'pin', 'A3');
[testSW, testHW]=structure_parse(lib, net_train_tmp, [], [], [], [], []);
Out=runNetlist(testSW, sig_in, Fs);

nD = 1:50:length(t);

a1=subplot(3, 1, 1); plot(t(nD), x(nD),  t(nD), Out(nD,1), t(nD), lab(nD)*max(x(nD)));
a2=subplot(3, 1, 2); plot(t(nD), Out(nD, [3 5]), t(nD), lab(nD)*2.6); ylim([-.1 2.7])
legend('Trig', 'Label')
% a3=subplot(3, 1, 3); plot(t(nD), Out(nD, [6 7]), t(nD), lab(nD)/10);
a3=subplot(3, 1, 3); plot(t(nD), Out(nD, [6 7]), t(nD), lab(nD)/10);
% a4=subplot(4, 1, 4); plot(t(nD), Out(nD, [6 7]) - Out(nD, [8 9]), t(nD), lab(nD)/10);
% legend('Thud Filt', 'Shatter Filt')
% ONod 0=thud_filt 1=diff_amp 2=preroll_trig 3=thud_declare 4=shatter_declare
linkaxes([a1, a2, a3], 'x')


selection=input('Would you like to overwrite existing NN with this one (y/n)? ','s');
if selection=='y'
	nn_save(nn, 'gb_nn_structure');
end
