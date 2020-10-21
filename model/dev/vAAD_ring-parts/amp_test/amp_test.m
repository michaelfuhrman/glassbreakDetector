% Setup the amp and it was working
% Tried to use the microphone, but the negative pin is floating
%   Floats to ground when powered on
%   When powered off, resistance measures overload while the positive pin measured ~500k


addpath(expandVarPath('%AspBox%/engr/sig_proc/Script_Library/Octave/hellbender_trim/0.6/trim_library/'));
ramp_library;

chs = [2:5];
pin = 'A3';
inPos = 'inPos';
inNeg = 'inNeg';
out   = 'out';

net = [];
net{end+1} = lib.prim.Iref();

amp_pos = sprintf('%s_amp_pos', out);
amp_neg = sprintf('%s_amp_neg', out);
vmid = sprintf('%s_vmid', out);

% Positive side
net{end+1} = lib.prim.resi('kilo', inPos,   'mega', amp_pos,  'loc',  [0 chs(1)]);
net{end+1} = lib.prim.resi('kilo', amp_pos, 'mega', vmid,     'loc',  [0 chs(2)]);
net{end+1} = lib.prim.opamp('pos', 'mid', 'neg', vmid, 'out', vmid, 'bias', 50e-9, 'loc',[0 chs(2)]);

% Negative side
net{end+1} = lib.prim.resi('kilo', inNeg,   'mega', amp_neg,  'loc',  [0 chs(3)]);
net{end+1} = lib.prim.resi('kilo', amp_neg, 'mega', out,      'loc',  [0 chs(4)]);

% Amp
net{end+1} = lib.amp.pinamp('pos', amp_pos, 'neg', amp_neg, 'out', out, 'pin', pin);

% Pins
net{end+1} = lib.pin.A0('net', inPos, 'dir', 'in');
net{end+1} = lib.pin.A2('net', inNeg, 'dir', 'in');
net{end+1} = lib.pin.A1('net', inPos, 'dir', 'in');

ramp_compile(net, ramp_ic);

