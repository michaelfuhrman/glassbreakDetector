%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load Compiled Netlist
%   Generated: 10/18/2020 10:36:16
%   PWD: C:\Users\Brandon\Desktop\glassbreak\model\dev\vAAD_ring-parts\v1_tie-together
%%%%%%%%%%%%%%%%%%%%%%%%%%


load('netlists/ramp68/compiled.mat');
a1em_write(compiled.bytestream.addr, compiled.bytestream.words);
a1em_ramp('load',1);