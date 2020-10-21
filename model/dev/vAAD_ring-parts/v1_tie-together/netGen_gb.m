%
% Generate GB netlist
%
% Params
%   lib     - ramp_library output
%   ramp_ic - ramp_setup output
%   nn      - Optional neural net model
%
% Return
%   net     - netlist structure
%
function [net, features]=netGen_gb(lib,ramp_ic,nn)

	%% Changes from v0
	% [x] inverter before CLB
	% [x] Remove vddLoc
	% [x] Increase attack on 1k and 400 peak detector
	% [x] Reduce peak detector decays
	% [x] Gain before 1k and 400Hz - combine with preroll gain - not resistor based?
	% [x] Add blinky

	%% Changes from v1
	% [x] Replace pfets w/ pseudos in detection chain comparators
	% [x] Remove bias point for audio output: just use 1.024V
	% [x] Get rid of extra vdd/gnd registers in the generated netlist
	% [x] Option to detect increase in NN output rather than given level
	% [x] Peak detector attacks/decays: back off 4k/1k attack (or better way to trim or no trim), increase all decays

  net=struct('name',[],'in',[],'out',[],'sw',[],'hw',[],'sub',[],'trim',1);
  net.name = 'gb';

  % Input net
  net.in{end+1} = struct('net','inPos', 'pin','A0');
  net.in{end+1} = struct('net','inNeg', 'pin','A2');

	% Gain for preroll and 400Hz and 1kHz
	preroll_gain = 3;
	ch = 1;
	net.sub{end+1} = ramp_again(lib, 'inPos', 'in_gain', preroll_gain, ch);

	% Features
  features=[];
	Q = 1.2; Av = 1; gm = 1.5e-6; ioff = 5e-9; fbase = 4; buf = 50e-9;
	Q = 3; Av = 2; atkNoise = 20; decNoise = 160;

	ch = 6;
	net.sub{end+1} = ramp_abpf_Av(lib, 'inPos', 'bpf_4k', 4e3, Q, Av, buf, ch, 1);
	[atk, dec] = PDbias(0.7, 0.05, 3e3); atk = atk * 2; dec = dec / 2;
	net.sub{end+1} = ramp_apeak_parasitic_local(lib, 'bpf_4k', 'rms_4k', atk, dec, buf, ch, 1);

	features{end+1} = struct('pos', 'rms_4k', 'neg', 'mid', 'ch', ch);

	ch = 5;
  net.sub{end+1} = ramp_alogshift(lib, 'rms_4k', 'rms_4k_log', gm, ioff, ch);
	net.sub{end+1} = ramp_alpf_ms(lib, 'rms_4k_log', 'noise_4k_log', fbase, buf, ch, 6);

	features{end+1} = struct('pos', 'rms_4k_log', 'neg', 'noise_4k_log', 'ch', ch);

	ch = 4;
	net.sub{end+1} = ramp_abpf_Av(lib, 'in_gain', 'bpf_1k', 1e3, Q, Av, buf, ch, 1);
	[atk, dec] = PDbias(0.7, 0.05, 800); atk = atk * 3; dec = dec / 2;
	net.sub{end+1} = ramp_apeak_parasitic_local(lib, 'bpf_1k', 'rms_1k', atk, dec, buf, ch, 1);

	features{end+1} = struct('pos', 'rms_1k', 'neg', 'mid', 'ch', ch);

	ch = 3;
	net.sub{end+1} = ramp_abpf_Av(lib, 'in_gain', 'bpf_400', 4e2, Q, Av, buf, ch, 1);
	[atk, dec] = PDbias(0.7, 0.05, 350); atk = atk * 3; dec = dec / 2;
	net.sub{end+1} = ramp_apeak_parasitic_local(lib, 'bpf_400', 'rms_400', atk, dec, buf, ch, 1);

	features{end+1} = struct('pos', 'rms_400', 'neg', 'mid', 'ch', ch);

	ch = 2;
  net.sub{end+1} = ramp_alogshift(lib, 'rms_400', 'rms_400_log', gm, ioff, ch);
	net.sub{end+1} = ramp_alpf_ms(lib, 'rms_400_log', 'noise_400_log', fbase, buf, ch, 6);

	features{end+1} = struct('pos', 'rms_400_log', 'neg', 'noise_400_log', 'ch', ch);


  %% Neural Network
  if isempty(nn)
    % Features
    for i = 1 : length(features)
      net.out{end+1} = features{i}.pos;
      net.out{end+1} = features{i}.neg;
    end

  else
		% % Create VDD net for comparators
		net.sub{end+1} = ramp_lreg(lib, 'vddLoc', 1, 8, 0);

    % Perform classification
    [~, net.sub{end+1}, ~] = nn_forward(nn, [], lib);
		% outputs on nn_thud (ch4) and nn_shatter (ch5)

		% Filter thud output
		fc = 20; ch = 4;
		net.sub{end+1} = ramp_alpf_ms(lib, 'nn_thud', 'thud_filt', fc, buf, ch, 7);
		% fc = 15; ch = 3;
		% net.sub{end+1} = ramp_alpf_ms(lib, 'thud_filt', 'thud_baseline', fc, buf, ch, 6);

		% Filter shatter output
		fc = 10; ch = 5;
		net.sub{end+1} = ramp_alpf_ms(lib, 'nn_shatter', 'shatter_filt', fc, buf, ch, 7);
		% fc = 5; ch = 6;
		% net.sub{end+1} = ramp_alpf_ms(lib, 'shatter_filt', 'shatter_baseline', fc, buf, ch, 6);

		% Thud Comparison
		ch		= 4;
		vth		= 0.015;
		vneg	= 1.5;
		gm		= 3e-6;
		ibuf	= 0.5e-6;
		net.sub{end+1} = ramp_mscmp2_pseudo(lib, 'thud_filt', 'mid', 'thud_cmp', ...
																 vth, vneg, gm, ibuf, ch, 'vddLoc');

		% Shatter Comparison
		ch		= 5;
		vth		= 0.015;
		vneg	= 1.5;
		gm		= 3e-6;
		ibuf	= 0.5e-6;
		net.sub{end+1} = ramp_mscmp2_pseudo(lib, 'shatter_filt', 'mid', 'shatter_cmp', ...
																 vth, vneg, gm, ibuf, ch, 'vddLoc');


		% Thud Overhang
		up		= 1e3;
		down	= 10;
		gm		= 700e-9;
		stage	= 7;
		ch		= 7;
		net.sub{end+1} = ramp_msoverhang(lib, 'thud_cmp', 'thud_hang', ...
																		 up, down, gm, stage, ch);

		net.sub{end+1} = ramp_commonSource_pseudo(lib, 'thud_hang', 'thud_hang_inv', ch, 'vddLoc');

		% Shatter Overhang
		up		= 1.8e2;
		down	= 10;
		gm		= 700e-9;
		stage	= 7;
		ch		= 3;
		net.sub{end+1} = ramp_msoverhang(lib, 'shatter_cmp', 'shatter_hang', ...
																		 up, down, gm, stage, ch);

		net.sub{end+1} = ramp_commonSource_pseudo(lib, 'shatter_hang', 'shatter_hang_inv', ch, 'vddLoc');

		% Glassbreak timing logic
		%   declare thud    = thud_cmp & !shatter_hang
		%   declare shatter = shatter_cmp & thud_hang & !shatter_hang
		ch = 3;
		net.sub{end+1} = gb_timing_logic_thud(lib, 'thud_cmp', 'shatter_hang_inv', 'thud_declare', ch);
		ch = 6;
		net.sub{end+1} = gb_timing_logic_shatter(lib, 'shatter_cmp', 'thud_hang_inv', 'shatter_hang_inv', 'shatter_declare', ch);

		% Invert and put on D2 for blinky
		net.sub{end+1} = ramp_linv(lib, 'shatter_declare', 'blinky', 9, 5, 0);

		% Preroll
		gain				= 1;
		chs					= [0 1];
		atk					= 15e3;
		dec					= 1e3;
		pk_ibuf			= 100e-9;
		vth					= +0.010;
		vneg				= 1.5;
		cmp_gm			= 3e-6;
		cmp_ibuf		= 0.5e-6;
		pulse_up		= 7500;
		pulse_down	= 7500;
		pulse_gm		= 1e-6;
		net.sub{end+1} = vad_preroll(lib, 'in_gain', 'preroll_trig', 'vddLoc',...
																 gain, atk, dec, pk_ibuf, ...
																 vth, vneg, cmp_gm, cmp_ibuf, ...
																 pulse_up, pulse_down, pulse_gm, chs);

		% % Pulse integrator
		% ch = 2; VperKHz = .2/20e3; ffilt = 50;
		% net.sub{end+1} = ramp_pulseIntegrator(lib, 'preroll_trig', 'zcr_pre', VperKHz, ch);
		% net.sub{end+1} = ramp_alpf_ms(lib, 'zcr_pre', 'zcr', ffilt, buf, ch+1, 7);

		% features{end+1} = struct('pos', 'zcr', 'neg', 'mid', 'ch', ch);


		% Diff amp
		net.sub{end+1} = ramp_diffamp_pin(lib, 'inPos', 'inNeg', 'diff_amp', 'A3', []);

		% Set output nets
		net.out{end+1} = struct('net',		'inPos',						'pin',  'A1');
		% net.out{end+1} = struct('net',  'diff_amp',         'pin',  'A3'); % This pin gets added by the amp itself
		net.out{end+1} = struct('net',		'preroll_trig',     'pin',  'D0');
		net.out{end+1} = struct('net',		'thud_declare',     'pin',  'D1');
		net.out{end+1} = struct('net',		'blinky',						'pin',  'D2');
		net.out{end+1} = struct('net',		'shatter_declare',  'pin',  'D3');
		net.out{end+1} = struct('net',		'thud_filt');
		net.out{end+1} = struct('net',		'shatter_filt');

	end
end

function [net]=vad_preroll(lib,in,out,vdd,...
                gain,atk,dec,pk_ibuf,...
                vth,vneg,cmp_gm,cmp_ibuf,...
                pulse_up, pulse_down, pulse_gm, chs)
  net=struct('name','vad_preroll','in',[],'out',[],'sw',[],'hw',[],'sub',[],'trim',1);
  net.in = {in, vdd}; net.out = {out};

  net.sw{end+1}='';
  net.sw{end+1}=sprintf('%% Preroll');

  % amp_out = sprintf('%s_ampout', in);
  % net.sub{end+1}=ramp_again11_noninvert(lib,in,amp_out,50e-9,chs(1));

  %pkpre = sprintf('%s_pkpre', in);
  pkpre = in;
  %net.sub{end+1}=ramp_apeak_parasitic_local(lib,amp_out,pkpre,atk/5,atk/5,pk_ibuf,chs(1),1);

  % CmpTop: pos=pkpre, neg=pktop
  cmp_top='CmpTop'; pktop = sprintf('%s_pktop', in);
  net.sub{end+1}=ramp_apeak_parasitic_local(lib,pkpre,pktop,atk,dec,pk_ibuf,chs(1),2);
  net.sub{end+1}=ramp_mscmp2_pseudo(lib,pkpre,pktop,cmp_top,vth,vneg,cmp_gm,cmp_ibuf,chs(1), vdd);

  % CmpBot: pos=pkbot, neg=pkpre
  cmp_bot='CmpBot'; pkbot = sprintf('%s_pkbot', in);
  net.sub{end+1}=ramp_apeak_parasitic_local(lib,pkpre,pkbot,dec,atk,pk_ibuf,chs(2),2);
  net.sub{end+1}=ramp_mscmp2_pseudo(lib,pkbot,pkpre,cmp_bot,vth,vneg,cmp_gm,cmp_ibuf,chs(2), vdd);

  % Notes about ramp_mscmp2
	% In the final FGOTA
	%
	%  posCharge = vneg - vth
	%  negCharge = vneg

  % Combine top and bot triggers
  net.sub{end+1}=vad_preroll_logic(lib,cmp_top,cmp_bot,out,pulse_up,pulse_down,pulse_gm,chs);
  % net.sub{end+1}=vad_preroll_logic_small(lib,cmp_top,cmp_bot,out,pulse_up,pulse_down,pulse_gm,chs);
end

function [net]=vad_preroll_logic_small(lib,top,bot,out,up,down,gm,chs)
  net=struct('name','vad_preroll_logic_small','in',[],'out',[],'sw',[],'hw',[],'sub',[],'trim',0);
  net.in = {top,bot}; net.out = {out};

  net.sub{end+1}=ramp_lor2(lib,top,bot,out,8,chs(2),1);
end

function [net]=vad_preroll_logic(lib,top,bot,out,up,down,gm,chs)
  net=struct('name','vad_preroll_logic','in',[],'out',[],'sw',[],'hw',[],'sub',[],'trim',0);
  net.in = {top,bot}; net.out = {out};

  trig_top = sprintf('%s_trig', top);
  rst_top  = sprintf('%s_rst', top);
  net.sub{end+1}=vad_preroll_ldff(lib,top,rst_top,trig_top,8,chs(1),0);
  net.sub{end+1}=ramp_msoverhang_cap(lib,trig_top,rst_top,up,down,gm,0,7,chs(1));

  trig_bot = sprintf('%s_trig', bot);
  rst_bot  = sprintf('%s_rst', bot);
  net.sub{end+1}=vad_preroll_ldff(lib,bot,rst_bot,trig_bot,8,chs(2),0);
  net.sub{end+1}=ramp_msoverhang_cap(lib,trig_bot,rst_bot,up,down,gm,0,7,chs(2));

  net.sub{end+1}=ramp_lor2(lib,trig_top,trig_bot,out,8,chs(2),1);
end

function [net]=vad_preroll_ldff(lib, clk, rst, out, stage, ch, num)
  net=struct('name','vad_preroll_ldff','in',[],'out',[],'sw',[],'hw',[],'sub',[],'trim',0);
  net.in={clk,rst}; net.out={out};

  % Flip flop with clear
  net.sw{end+1}=sprintf('%% DFF ');
  net.sw{end+1}=sprintf('Not0 In1=%s Out=%sb', clk,clk);
  net.sw{end+1}=sprintf('Vsrc Pos=%s_tiehi Neg=Gnd WavChan=-1 Vdc=2.5',out);
  net.sw{end+1}=sprintf('DFF0 D=%s_tiehi Clk=%sb R=%s Q=%s',out,clk,rst,out);

  if ~isempty(lib)
    net.hw{end+1}=lib.prim.clb('a',clk, 'c',rst, 'outQ',out, ...
                            'lutIn','1', 'lutClk','~A', 'lutRst','~C', ...
                            'loc',[stage ch num]);
  end
end

function net=ramp_apeak_parasitic_local(lib,in,out,atk,dec,buff,ch,num)
  net=struct('name','ramp_apeak_hwscale','in',[],'out',[],'sw',[],'hw',[],'sub',[],'trim',2);
  net.in={in}; net.out={out};

	% Added during glassbreak retrim to handle mins properly
	if atk>dec
		atk = atk * 2;
		atk_hw = atk;
		dec_hw = dec / 2;
	else
		dec = dec * 2;
		dec_hw = dec;
		atk_hw = atk / 2;
	end

  net.sw{end+1}=sprintf('%% Peak');
  net.sw{end+1}=sprintf('PkDD In=%s Out=%s Saturate=1 a=%d d=%d Par=.4', ...
                        in,out,atk,dec);

  if ~isempty(lib)
    net.hw{end+1}=lib.prim.peak('in',in, 'out',out, 'atk',atk_hw, 'dec',dec_hw, ...
																			 'buff',buff, 'loc',[1 ch num]);
  end
end

function net=ramp_again_3(lib,in,out,buff,chs)
  net=struct('name','ramp_again_3','in',[],'out',[],'sw',[],'hw',[],'sub',[],'trim',0);
  net.in={in}; net.out={out};

  net.sw{end+1}=sprintf('%% 3x gain');
  net.sw{end+1}=sprintf('AmpX In=%s Out=%s Av=3', in,out);

  if ~isempty(lib)
		vfb = sprintf('%s_3x_vfb', out);
		vmid = sprintf('%s_3x_vmid', out);
		net.hw{end+1} = lib.prim.resi('kilo', in, 'mega', vfb, 'loc', [0 chs(1)]);
		net.hw{end+1} = lib.prim.resi('kilo', vfb, 'mega', vmid, 'loc', [0 chs(2)]);
		net.hw{end+1} = lib.prim.resi('kilo', vmid, 'mega', out, 'loc', [0 chs(3)]);
    net.hw{end+1}=lib.prim.opamp('pos','mid', 'neg',vfb, 'out',out, 'bias',buff, 'loc', [0 chs(1)]);
  end
end

function net=ramp_again_10(lib,in,out,buff,ch)
  net=struct('name','ramp_again_10','in',[],'out',[],'sw',[],'hw',[],'sub',[],'trim',0);
  net.in={in}; net.out={out};

  net.sw{end+1}=sprintf('%% 10x gain');
  net.sw{end+1}=sprintf('AmpX In=%s Out=%s Av=10', in,out);

  if ~isempty(lib)
		vfb = sprintf('%s_10x_vfb', out);
		vmid = sprintf('%s_10x_vmid', out);
		net.hw{end+1} = lib.prim.resi('kilo', in, 'tap', vfb, 'mega', out, 'loc', [0 ch]);
    net.hw{end+1}=lib.prim.opamp('pos','mid', 'neg',vfb, 'out',out, 'bias',buff, 'loc', [0 ch]);
  end
end

function net = ramp_diffamp_pin(lib, inPos, inNeg, out, pin, chs)
  net=struct('name','ramp_diffamp_pin','in',[],'out',[],'sw',[],'hw',[],'sub',[],'trim',0);
  net.in={inPos, inNeg}; net.out={out};

  net.sw{end+1}=sprintf('%% Diff amp');
  net.sw{end+1}=sprintf('Sub2 Pos=%s Neg=%s Out=%s Av=0.5', inPos, inNeg, out);

  if ~isempty(lib)
		amp_pos = sprintf('%s_amp_pos', out);
		tap_pos = sprintf('%s_tap_pos', out);
		amp_neg = sprintf('%s_amp_neg', out);
		tap_neg = sprintf('%s_tap_neg', out);
		mid_buff = sprintf('%s_mid_buff', out);
		dc_ref = sprintf('%s_dc_ref',out);
		dc_ref = 'mid';

		% dc reference
		vref = 0.9; vmid = 1.024;
		posCharge = 1.6; % @ 25nA, positive side has a Vsg = 1.4V
		negCharge = posCharge - (vmid - vref); % negative side has a Vsg of 1.4V + 0.124V to drop the voltage
		% net.hw{end+1} = lib.prim.fgota('pos', 'mid', 'neg', dc_ref, 'out', dc_ref, ...
		% 															 'gm', 250e-9, 'posCharge', posCharge, 'negCharge', negCharge, ...
		% 															 'loc', [4 2]);

		% Positive side
		% net.hw{end+1} = lib.prim.resi('kilo', inPos,		'mega', tap_pos,	'loc',	[0 2]);
		net.hw{end+1} = lib.prim.resi('kilo', inPos,	'mega', amp_pos,	'loc',	[0 3]);
		net.hw{end+1} = lib.prim.resi('kilo', amp_pos,	'mega', mid_buff,	'loc',	[0 4]);
		net.hw{end+1} = lib.prim.opamp('pos', dc_ref, 'neg', mid_buff, 'out', mid_buff, 'bias', 50e-9, 'loc',[0 4]);

		% Negative side
		% net.hw{end+1} = lib.prim.resi('kilo', inNeg,		'mega', tap_neg,	'loc',	[0 7]);
		net.hw{end+1} = lib.prim.resi('kilo', inNeg,	'mega', amp_neg,	'loc',	[0 6]);
		net.hw{end+1} = lib.prim.resi('kilo', amp_neg,	'mega', out,			'loc',	[0 7]);

		% Amp
		net.hw{end+1} = lib.amp.pinamp('pos', amp_pos, 'neg', amp_neg, 'out', out, 'pin', pin);
  end
end

%   declare thud    = thud_cmp & shatter_hang_inv
function net = gb_timing_logic_thud(lib, thud_cmp, shatter_hang_inv, thud_declare, ch)
  net=struct('name','gb_timing_logic_thud','in',[],'out',[],'sw',[],'hw',[],'sub',[],'trim',0);
  net.in={thud_cmp, shatter_hang_inv}; net.out={thud_declare};

  net.sw{end+1}=sprintf('%% Thud timing logic');
  net.sw{end+1} = sprintf('And0 In1=%s In2=%s Out=%s', thud_cmp, shatter_hang_inv, thud_declare);

  if ~isempty(lib)
    net.hw{end+1} = lib.prim.clb('a', thud_cmp, 'b', shatter_hang_inv,  'outD', thud_declare, ...
                                 'lutIn', 'A & B', 'lutD', 'Local', 'loc', [9 ch 0]);
	end
end

%   declare shatter = shatter_cmp & !thud_hang_inv & shatter_hang_inv
function net = gb_timing_logic_shatter(lib, shatter_cmp, thud_hang_inv, shatter_hang_inv, shatter_declare, ch)
  net=struct('name','gb_timing_logic_shatter','in',[],'out',[],'sw',[],'hw',[],'sub',[],'trim',0);
  net.in={shatter_cmp, thud_hang_inv, shatter_hang_inv}; net.out={shatter_declare};

  net.sw{end+1}=sprintf('%% Shatter timing logic');
	not_thud_hang_inv = sprintf('%s_not_thud_hang_inv', shatter_declare);
	shatter_and_thud_hang = sprintf('%s_shatter_and_thud_hang', shatter_declare);
	net.sw{end+1} = sprintf('Not0 In1=%s Out=%s', thud_hang_inv, not_thud_hang_inv);
  net.sw{end+1} = sprintf('And0 In1=%s In2=%s Out=%s', shatter_cmp, not_thud_hang_inv, shatter_and_thud_hang);
  net.sw{end+1} = sprintf('And0 In1=%s In2=%s Out=%s', shatter_and_thud_hang, shatter_hang_inv, shatter_declare);

  if ~isempty(lib)
    net.hw{end+1} = lib.prim.clb('a', shatter_cmp, 'b',thud_hang_inv , 'c', shatter_hang_inv, 'outD', shatter_declare, ...
                                 'lutIn', 'A & ~B & C', 'lutD', 'Local', 'loc', [9 ch 0]);
	end
end

%% Pulse integrator
function [net] = ramp_pulseIntegrator(lib, In, Out, VperKHz, chan)

  net=struct('name','pulseIntegrator',  'in',[],  'out',[], 'sw',[], 'hw',[], 'sub',[], 'trim', 1);
  net.in={In}; net.out={Out};

  C=(787.71+2*396.315)*1e-15;
	Duration=0.1e-3; % Fixed at a value that worked well in hardware. Isn't trimmable in
                   % through the analog output pins because of finite slew rate
	GmDecay=2e-9; % Fixed value based on HW, not made trimmable yet
  IavgPerKHz=VperKHz*GmDecay; Icharge=IavgPerKHz/Duration;

  net.sw{end+1}=sprintf('Puls In=%s Out=%s_puls Time=%d',In,Out,Duration);
  net.sw{end+1}=sprintf('AmpX In=%s_puls Out=%s_pulsI Av=%d',Out,Out,Icharge);
  net.sw{end+1}=sprintf('Sub2 Pos=%s_pulsI Neg=%s_fb Out=%s_intIn Av=1',Out,Out,Out);
  net.sw{end+1}=sprintf('LInt In=%s_intIn Out=%s_inv rateUp=%d rateDown=%d zeroRes=0',Out,Out,1/C,1/C);
  net.sw{end+1}=sprintf('AmpX In=%s_inv Out=%s_fb Av=%d',Out,Out,GmDecay);
  net.sw{end+1}=sprintf('AmpX In=%s_inv Out=%s Av=-1',Out,Out);

  if ~isempty(lib)
    net.hw{end+1}=lib.mixsig.pulse_integrator('in',In, 'out',Out, ...
        'VperKHz',VperKHz, 'ch',chan);
  end
end

%% Common-source after overhang to edgify
function net = ramp_commonSource_pseudo(lib, In, Out, chan, vdd)
  net=struct('name','commonSource_pseudo',  'in',[],  'out',[], 'sw',[], 'hw',[], 'sub',[], 'trim', 0);
  net.in={In, vdd}; net.out={Out};

  net.sw{end+1}=sprintf('Not0 In1=%s Out=%s',In,Out);

  if ~isempty(lib)
    net.hw{end+1}=lib.prim.mifg('source', vdd, 'gate1', In, 'gate2', In, 'drain', Out, ...
																'drainCur', 0.3e-6, ...
																'pseudo', 1, 'loc', [5 chan]);
	end
end

%% Differential comparator
function net=ramp_mscmp2_pseudo(lib,pos,neg,out,vth,vneg,gm,ibuf,ch,vdd)
  net=struct('name','ramp_mscmp2','in',[],'out',[],'sw',[],'hw',[],'sub',[],'trim',2);
  net.in={pos,neg, vdd}; net.out={out};

  % Check if VDD is specified
  if ~exist('vdd','var') || strcmp(vdd, 'n/c')
    vdd = 'n/c';
  else
    % When specified, add to input list
    net.in{end+1} = vdd;
  end

  % Check if ch specified
  if ~exist('ch','var')
    ch = [];
  end

  vos = sprintf('vos_%s',out);
  neg_vos = sprintf('%s_vos_%s',neg, out);

  net.sw{end+1}=sprintf('%% Diff Comp');
  net.sw{end+1}=sprintf('Vsrc Pos=%s Neg=Gnd WavChan=-1 Vdc=%d',vos,vth);
  net.sw{end+1}=sprintf('Add2 In1=%s In2=%s Out=%s Av=1',vos,neg,neg_vos);
  net.sw{end+1}=sprintf('CmpX Pos=%s Neg=%s Out=%s',pos,neg_vos,out);

  if ~isempty(lib)
		% pfet_in = sprintf('%s_cmp2int', out);

		% % Need to swap inputs and invert threshold
		% net.hw{end+1} = lib.mixsig.cmp2_nobuf('pos',neg,'neg',pos,'out',pfet_in,...
		% 																			'vth',-vth, 'vneg',vneg-vth, 'gm',gm, 'loc',[4 ch]);

		% % Add inversion and buffing with pfet
		% net.hw{end+1} = lib.prim.mifg('source',vdd, 'gate1',pfet_in, 'gate2',pfet_in, 'drain',out,...
		% 															'pseudo',1, 'drainCur',ibuf, 'loc',[5 ch]);
    net.hw{end+1}=lib.mixsig.cmp2_pseudo('pos',pos,'neg',neg,'out',out,'vdd',vdd,...
																	'vth',vth,'vneg',vneg,'gm',gm,'ibuf',ibuf,'ch',ch);
  end
end
