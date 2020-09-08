function FullChain=glassbreak_chain(ramp,gain,prerollOn)

	% Filter bank with log energies
	Fb=[ramp.ops.bpf('fc',4e3, 'Av',gain) > ramp.ops.peak('atk',.5*20e3, 'dec',.5*1.358e3); ...
			ramp.ops.bpf('fc',300, 'Av',gain) > ramp.ops.peak('atk',.5*1200, 'dec',.5*81)] > ramp.ideal.log('in_offset',6e-3);

	% Onset detection
	ChainOnset=Fb > ramp.ideal.minus() > [ramp.ideal.pass; ...
																				ramp.ops.peak('atk',35, 'dec',80)] > ramp.ideal.minus();

	% Check that sufficient volume is achieved
	ChainVolume=ramp.ops.bpf('fc',3e3, 'Av',gain) > ramp.ops.peak('atk',8e3, 'dec',300) > ramp.ideal.log('in_offset',6e-3);
	ChainVolume=ChainVolume > [ramp.ideal.pass; ...
														 ramp.ops.peak('atk',50, 'dec',100)] > ramp.ideal.minus();

	% Linear combination of onset and volume rules
	Chain=[ChainOnset; ChainVolume] > ramp.learn.lin('W',[4 1.5]);

	% Detection and pulse filtering
	thresh=.1;
	ChainDetect=Chain > ramp.ops.cmp('thresh',thresh,'settleTime',.2) > ramp.ops.overhang('up',150,'down',120);
	ChainDetect=ChainDetect > ramp.ops.cmp('thresh',thresh) > ramp.ops.overhang('up',4e3,'down',3);

	if ~prerollOn
		FullChain=ChainDetect > ramp.ops.cmp('thresh',.3,'printTimeStamp',1) > ramp.pin.A3();
	else
		% Preroll compression and decompression
		Preroll=ramp.app.prerollrecongb('enable',1);

		% Full signal chain that we will build
		FullChain=[ramp.ideal.pass(); ...
							 ChainDetect>ramp.ops.cmp('thresh',.3,'printTimeStamp',1)] > Preroll > ramp.pin.A3();
	end
end
