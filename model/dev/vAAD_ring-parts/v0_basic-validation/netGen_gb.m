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
function [net]=netGen_gb(lib,ramp_ic,nn)
  net=struct('name',[],'in',[],'out',[],'sw',[],'hw',[],'sub',[],'trim',1);
  net.name = 'vad';

  % Input net
  net.in{end+1} = struct('net','inPos', 'pin','A0');
  net.in{end+1} = struct('net','inNeg', 'pin','A2');

	% net.sub{end+1}=ramp_again_3(lib,'in','in_3x',50e-9,[1 2 3]);

  features=[];

  buf = 50e-9;

  % Feature 0
	ch = 3;
  fc = 400; Q = 1.2; Av = 1; % Q = 4.3; Av = 1;
  net.sub{end+1} = ramp_abpf_Av(lib, 'inPos', 'bpf_0', fc, Q, Av, buf, ch, 1);

  [atk, dec] = PDbias(0.7, 0.05, 350);
	atk = atk * 2; dec = dec / 2;
  net.sub{end+1} = ramp_apeak_parasitic_local(lib, 'bpf_0', 'rms_0', atk, dec, buf, ch, 1);

  features{end+1} = struct('pos', 'rms_0', 'neg', 'mid', 'ch', ch);

  % Feature 1
	ch = 4;
  atk = 20; dec = 160;
  net.sub{end+1} = ramp_apeak_parasitic_local(lib, 'rms_0', 'rms_0_min', atk, dec, buf, ch, 1);

  features{end+1} = struct('pos', 'rms_0_min', 'neg', 'mid', 'ch', ch);

  % Feature 2
	ch = 5;
  fc = 4e3; Q = 1.2; Av = 1; % Q = 4.3; Av = 1;
  net.sub{end+1} = ramp_abpf_Av(lib, 'inPos', 'bpf_1', fc, Q, Av, buf, ch, 1);

  [atk, dec] = PDbias(0.7, 0.05, 3e3);
	atk = atk * 2; dec = dec / 2;
  net.sub{end+1} = ramp_apeak_parasitic_local(lib, 'bpf_1', 'rms_1', atk, dec, buf, ch, 1);

  features{end+1} = struct('pos', 'rms_1', 'neg', 'mid', 'ch', ch);

  % Feature 3
	ch = 6;
  atk = 20; dec = 160;
  net.sub{end+1} = ramp_apeak_parasitic_local(lib, 'rms_1', 'rms_1_min', atk, dec, buf, ch, 1);

  features{end+1} = struct('pos', 'rms_1_min', 'neg', 'mid', 'ch', ch);


  %% Neural Network
  if isempty(nn)
    % Features
    for i = 1 : length(features)
      net.out{end+1} = features{i}.pos;
      net.out{end+1} = features{i}.neg;
    end

  else
		% Create VDD net for comparators
		net.sub{end+1} = ramp_lreg(lib, 'vddLoc', 1, 8, 0);

    % Perform classification
    [~, net.sub{end+1}, ~] = nn_forward(nn, [], lib);
		% outputs on nn_thud (ch4) and nn_shatter (ch5)

		% Filter thud output
		fc = 50; ch = 4;
		net.sub{end+1} = ramp_alpf_ms(lib, 'nn_thud', 'thud_filt', fc, buf, ch, 7);

		% Filter shatter output
		fc = 50; ch = 5;
		net.sub{end+1} = ramp_alpf_ms(lib, 'nn_shatter', 'shatter_filt', fc, buf, ch, 7);

		% Thud Comparison
		ch		= 3;
		vth		= 0.005;
		vneg	= 1.5;
		gm		= 3e-6;
		ibuf	= 0.5e-6;
		net.sub{end+1} = ramp_mscmp2(lib, 'thud_filt', 'mid', 'thud_cmp', ...
																 vth, vneg, gm, ibuf, ch, 'vddLoc');

		% Shatter Comparison
		ch		= 6;
		vth		= 0.02;
		vneg	= 1.5;
		gm		= 3e-6;
		ibuf	= 0.5e-6;
		net.sub{end+1} = ramp_mscmp2(lib, 'shatter_filt', 'mid', 'shatter_cmp', ...
																 vth, vneg, gm, ibuf, ch, 'vddLoc');


		% Thud Overhang
		up		= 1e3;
		down	= 20;
		gm		= 700e-9;
		stage	= 7;
		ch		= 7;
		net.sub{end+1} = ramp_msoverhang(lib, 'thud_cmp', 'thud_hang', ...
																		 up, down, gm, stage, ch);

		% Shatter Overhang
		up		= 2e2;
		down	= 20;
		gm		= 700e-9;
		stage	= 7;
		ch		= 3;
		net.sub{end+1} = ramp_msoverhang(lib, 'shatter_cmp', 'shatter_hang', ...
																		 up, down, gm, stage, ch);

		% Glassbreak timing logic
		%   declare thud    = thud_cmp & !shatter_hang
		%   declare shatter = shatter_cmp & thud_hang & !shatter_hang
		ch = 3;
		net.sub{end+1} = gb_timing_logic_thud(lib, 'thud_cmp', 'shatter_hang', 'thud_declare', ch);
		ch = 6;
		net.sub{end+1} = gb_timing_logic_shatter(lib, 'shatter_cmp', 'thud_hang', 'shatter_hang', 'shatter_declare', ch);

		% Diff amp
		net.sub{end+1} = ramp_diffamp_pin(lib, 'inPos', 'inNeg', 'diff_amp', 'A3', [2:5]);

		% Preroll
		gain				= 1;
		chs					= [0 1];
		atk					= 15e3;
		dec					= 1e3;
		pk_ibuf			= 100e-9;
		vth					= +0.005;
		vneg				= 1.5;
		cmp_gm			= 3e-6;
		cmp_ibuf		= 0.5e-6;
		pulse_up		= 7500;
		pulse_down	= 7500;
		pulse_gm		= 1e-6;
		net.sub{end+1} = vad_preroll(lib, 'inPos', 'preroll_trig', 'vddLoc',...
																 gain, atk, dec, pk_ibuf, ...
																 vth, vneg, cmp_gm, cmp_ibuf, ...
																 pulse_up, pulse_down, pulse_gm, chs);

		% Set output nets
		net.out{end+1} = struct('net',  'thud_filt',        'pin',  'A1');
		% net.out{end+1} = struct('net',  'diff_amp',         'pin',  'A3');
		net.out{end+1} = struct('net',  'preroll_trig',     'pin',  'D0');
		net.out{end+1} = struct('net',  'thud_declare',     'pin',  'D1');
		net.out{end+1} = struct('net',  'shatter_declare',  'pin',  'D3');

	end
end

function [net]=vad_preroll(lib,in,out,vdd,...
                gain,atk,dec,pk_ibuf,...
                vth,vneg,cmp_gm,cmp_ibuf,...
                pulse_up, pulse_down, pulse_gm, chs)
  net=struct('name','vad_preroll','in',[],'out',[],'sw',[],'hw',[],'sub',[],'trim',1);
  net.in = {in,vdd}; net.out = {out};

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
  net.sub{end+1}=ramp_mscmp2(lib,pkpre,pktop,cmp_top,vth,vneg,cmp_gm,cmp_ibuf,chs(1),vdd);

  % CmpBot: pos=pkbot, neg=pkpre
  cmp_bot='CmpBot'; pkbot = sprintf('%s_pkbot', in);
  net.sub{end+1}=ramp_apeak_parasitic_local(lib,pkpre,pkbot,dec,atk,pk_ibuf,chs(2),2);
  net.sub{end+1}=ramp_mscmp2(lib,pkbot,pkpre,cmp_bot,vth,vneg,cmp_gm,cmp_ibuf,chs(2),vdd);

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

function net = ramp_diffamp_pin(lib, inPos, inNeg, out, pin, chs)
  net=struct('name','ramp_diffamp_pin','in',[],'out',[],'sw',[],'hw',[],'sub',[],'trim',0);
  net.in={inPos, inNeg}; net.out={out};

  net.sw{end+1}=sprintf('%% Diff amp');
  net.sw{end+1}=sprintf('Sub2 Pos=%s Neg=%s Out=%s Av=0.5', inPos, inNeg, out);

  if ~isempty(lib)
		amp_pos = sprintf('%s_amp_pos', out);
		amp_neg = sprintf('%s_amp_neg', out);
		vmid = sprintf('%s_vmid', out);

		% Positive side
		net.hw{end+1} = lib.prim.resi('kilo', inPos,		'mega', amp_pos,	'loc',	[0 chs(1)]);
		net.hw{end+1} = lib.prim.resi('kilo', amp_pos,	'mega', vmid,			'loc',	[0 chs(2)]);
		net.hw{end+1} = lib.prim.opamp('pos', 'mid', 'neg', vmid, 'out', vmid, 'bias', 50e-9, 'loc',[0 chs(2)]);

		% Negative side
		net.hw{end+1} = lib.prim.resi('kilo', inNeg,		'mega', amp_neg,	'loc',	[0 chs(3)]);
		net.hw{end+1} = lib.prim.resi('kilo', amp_neg,	'mega', out,			'loc',	[0 chs(4)]);

		% Amp
		net.hw{end+1} = lib.amp.pinamp('pos', amp_pos, 'neg', amp_neg, 'out', out, 'pin', pin);
  end
end

%   declare thud    = thud_cmp & !shatter_hang
function net = gb_timing_logic_thud(lib, thud_cmp, shatter_hang, thud_declare, ch)
  net=struct('name','gb_timing_logic_thud','in',[],'out',[],'sw',[],'hw',[],'sub',[],'trim',0);
  net.in={thud_cmp, shatter_hang}; net.out={thud_declare};

  net.sw{end+1}=sprintf('%% Thud timing logic');
	not_shatter_hang = sprintf('%s_not_shatter_hang', thud_declare);
	net.sw{end+1} = sprintf('Not0 In1=%s Out=%s', shatter_hang, not_shatter_hang);
  net.sw{end+1} = sprintf('And0 In1=%s In2=%s Out=%s', thud_cmp, not_shatter_hang, thud_declare);

  if ~isempty(lib)
    net.hw{end+1} = lib.prim.clb('a', thud_cmp, 'b', shatter_hang,  'outD', thud_declare, ...
                                 'lutIn', 'A & ~B', 'lutD', 'Local', 'loc', [9 ch 0]);
	end
end

%   declare shatter = shatter_cmp & thud_hang & !shatter_hang
function net = gb_timing_logic_shatter(lib, shatter_cmp, thud_hang, shatter_hang, shatter_declare, ch)
  net=struct('name','gb_timing_logic_shatter','in',[],'out',[],'sw',[],'hw',[],'sub',[],'trim',0);
  net.in={shatter_cmp, thud_hang, shatter_hang}; net.out={shatter_declare};

  net.sw{end+1}=sprintf('%% Shatter timing logic');
	not_shatter_hang = sprintf('%s_not_shatter_hang', shatter_declare);
	shatter_and_thud_hang = sprintf('%s_shatter_and_thud_hang', shatter_declare);
	net.sw{end+1} = sprintf('Not0 In1=%s Out=%s', shatter_hang, not_shatter_hang);
  net.sw{end+1} = sprintf('And0 In1=%s In2=%s Out=%s', shatter_cmp, thud_hang, shatter_and_thud_hang);
  net.sw{end+1} = sprintf('And0 In1=%s In2=%s Out=%s', shatter_and_thud_hang, not_shatter_hang, shatter_declare);

  if ~isempty(lib)
    net.hw{end+1} = lib.prim.clb('a', shatter_cmp, 'b',thud_hang , 'c', shatter_hang, 'outD', shatter_declare, ...
                                 'lutIn', 'A & B & ~C', 'lutD', 'Local', 'loc', [9 ch 0]);
	end
end
