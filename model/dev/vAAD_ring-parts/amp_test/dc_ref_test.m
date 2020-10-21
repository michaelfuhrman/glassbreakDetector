a1em_write('dac_coarse_trim', [400 -340]);
% 400 - .10114
% 66 - 0.098624   0.097461   0.098623  -0.075846   0.098519   0.097845  -0.122335   0.097942
% 67 - 
% Use this to dial in the coarse trim - should see a unity slope as we sweep the bias

vrefs = [0.8 0.9 1];
chs = 0:7;
slopes = [];
T = 0.2; Fs = 50e3; t = 0:1/Fs:T;

for c = 1:length(chs)
	vread = [];
	for v = 1:length(vrefs)
		dc_ref = 'dc_ref';

		net = [];
		net{end+1} = lib.prim.Iref();
		net{end+1} = lib.pin.A3('net', dc_ref, 'dir', 'out');
		vmid = 1.024;
		posCharge = 1.6; % @ 25nA, positive side has a Vsg = 1.2V
		negCharge = posCharge - (vmid - vrefs(v)); % negative side has a Vsg of 1.2V + 0.124V to drop the voltage
		net{end+1} = lib.prim.fgota('pos', 'mid', 'neg', dc_ref, 'out', dc_ref, ...
																'gm', 250e-9, 'posCharge', posCharge, 'negCharge', negCharge, ...
																'loc', [4 chs(c)]);

		ramp_compile(net, ramp_ic);

		y = ADaoutIn(0*t, 1, Fs, T);
		vread(v) = mean( y(:,2) );
		subplot(2, 1, 1)
		plot(t, y(:,2), t, 0*t+vread(v));
		pause(.01);
	end
	subplot(2, 1, 2)
	plot(diff(vread));
	slopes(c) = mean(diff(vread));
end


net = [];
net{end+1} = lib.prim.Iref();
net{end+1} = lib.pin.A3('net', 'vcg', 'dir', 'out');

ramp_compile(net, ramp_ic);

y = ADaoutIn(0*t, 1, Fs, T);
mean( y(:,2) )
