%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load Compiled Netlist
%   Generated: 10/19/2020 11:34:19
%   PWD: C:\Users\Brandon\Desktop\glassbreak\model\dev\vAAD_ring-parts\v1_tie-together
%%%%%%%%%%%%%%%%%%%%%%%%%%


load('netlists/ramp64/compiled.mat');
a1em_write(compiled.bytestream.addr, compiled.bytestream.words);
a1em_ramp('load',1);