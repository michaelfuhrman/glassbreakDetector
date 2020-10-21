% Inputs
%  - cmp_top
%  - cmp_bot
% Outputs
%  - preroll_trigger
% Function
%  - strobe preroll_trigger on each falling edge of cmp_top or cmp_bot
% Logic table
%  | cmp_top[n-1] | cmp_bot[n-1] | cmp_top[n] | cmp_bot[n] | out[n-1] | out[n] |
%  | 0            | 0            | 0          | 0          | 0
%
% | cmp_top[n-1] | cmp_top[n] |

%
