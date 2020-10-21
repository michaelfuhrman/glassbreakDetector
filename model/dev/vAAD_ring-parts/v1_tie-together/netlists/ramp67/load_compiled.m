%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load Compiled Netlist
%   Generated: 10/18/2020 15:56:44
%   PWD: C:\Users\Brandon\Desktop\glassbreak\model\dev\vAAD_ring-parts\v1_tie-together
%%%%%%%%%%%%%%%%%%%%%%%%%%


load('netlists/ramp67/compiled.mat');
a1em_write(compiled.bytestream.addr, compiled.bytestream.words);
a1em_ramp('load',1);