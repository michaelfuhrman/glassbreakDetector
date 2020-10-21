function net = timing_logic_netlist(lib)
  net=struct('name',[],'in',[],'out',[],'sw',[],'hw',[],'sub',[],'trim',1);
  net.name = 'timing_logic';

  % Input net
  net.in{end+1} = struct('net','thud_cmp', 'pin','A0');
  net.in{end+1} = struct('net','shatter_cmp', 'pin','A2');

	% Output net
	net.out{end+1} = struct('net',  'thud_declare',  'pin',  'A1');
	net.out{end+1} = struct('net',  'shatter_declare',  'pin',  'A3');


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
