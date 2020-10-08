%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load Compiled Netlist
%   Generated: 10/08/2020 09:48:55
%   PWD: C:\Users\Brandon\Desktop\glassbreak\model\dev\vAAD_ring-parts\v0_basic-validation
%%%%%%%%%%%%%%%%%%%%%%%%%%


load('netlists/ramp31/compiled.mat');
a1em_write(compiled.bytestream.addr, compiled.bytestream.words);
a1em_ramp('load',1);