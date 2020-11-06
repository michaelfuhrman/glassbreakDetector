function [declareThud, declareShatter] = applyTimingLogic_v4(ramp, t,l,ynnThud, ynnShatter)

% What do we see:
%    1) Would like to keep last Thud in a series, but that's not possible since
%       we don't know when it will occur
%    2) Only want to keep first Shatter within a series of pulses after the
%       last Thud. Basically debounce shatter until the next Thud.
%    3) Thud less than Xmsec after shatter should be suppressed
%    4) This becomes version _v3 with the following concept: if a shatter
%       pulse and a thud pulse are very close to overlapping we would like
%       to keep the detection. This is done in this version by delaying the
%       shatter pulse by 50msec.

% Thresholds specific to Thud and Shatter
THUDTHRESH = ramp.ops.cmp('thresh',.5);
SHATTERTHRESH = ramp.ops.cmp('thresh',.3);
% Other operators
CMPpt5 = ramp.ops.cmp('thresh',.5);
PULSE0001=ramp.ops.pulse('time',1e-6);
NOT = ramp.logic.gate('type','not');
AND = ramp.logic.gate('type','and');
AMPpt4=ramp.ideal.amp('Av',.4);

%%% The inputs to this chain are [ynnThud and ynnShatter
%%% So this is where the thresholding of the neural net outputs occurs
%   and is the place to change the threshold
%
% 1) Numerator is a narrow pulse which is applied to the Thud
% 2) Demoninator is the same narrow Shatter pulse which is inverted
%    and followed by a 200msec wide pulse which is inverted.
% 3) A thud which came more than 200 msec after Shatter survives to
%    be the source of a 150msec pulse, i.e, a wide valid pulse.
% 4) Inserted a 50msec delay to the shatter pulse here so it would not suppress
%    the thud if it occurs at about the same time. The delay makes this
%    _V3

wideValidThudPulseChain = [THUDTHRESH > PULSE0001;
    SHATTERTHRESH > ramp.ops.pulse('time',.2) > ramp.ops.delay('delay',.05) > NOT] > ...
    AND > NOT > ramp.ops.pulse('time',.15);



%% This is to generate a short declareShatter pulse from the incoming  
%  shatter Neural Network. The incoming signal has to be wide enough, hence
%  the long UpTime and DownTime
% If shatter occurs late, or the NN output is weak to start and the pulse is
% generated too late we can miss it
%UpTime=.08;
UpTime=.1; %.1
DownTime=.1; %.1

% Threshold before overhang?
ShatterPulseChain = SHATTERTHRESH > ramp.ops.overhang('up',1.25/UpTime, 'down',1.25/DownTime) > CMPpt5 > PULSE0001;


% Generate a valid Thud pulse
% The input is [ynnThud ynnShatter]
% 1) Generate narrow Thud and Shatter pulses
% 2) Suppress a Thud that occurs within 200msec after Shatter
% 2a) How to keep a pulse that occurs at almost the same time as shatter?
% 3) ### Need the NOT?
    
validThudPulseChain = [THUDTHRESH > PULSE0001;
    SHATTERTHRESH > ramp.ops.pulse('time',.2)> NOT] > AND > AMPpt4;
    
% Apply the wideValidThudPulseChain; Available for plotting
wideValidThudPulse = wideValidThudPulseChain(t,[ynnThud ynnShatter]); % <-- Needed to declare Shatter
shatterPulse = ShatterPulseChain(t,ynnShatter); % <-- Needed to declare Shatter

validThudPulse = validThudPulseChain(t,[ynnThud ynnShatter]); % <-- The Thud declaration
declareThud = validThudPulse;

declareShatter = AMPpt4(t,AND(t,[wideValidThudPulse shatterPulse]));

if 0
    % Look at the intermediate outputs efore returning
    figure;
    subplot(311)
    plot(t,ynnThud,'b',t,ynnShatter,'r',t,l,'k')
    ax(1)=gca;
    subplot(312)
    H = ramp.ops.overhang('up',1.25/UpTime, 'down',1.25/DownTime);
    plot(t,H(t,ynnShatter),t,l,'k')
    title('Overhang Applied to ynnShatter')
    ax(2) = gca;
    subplot(313)
    plot(t, .42*wideValidThudPulse,'b', t,.42*shatterPulse,'r',t,l,'k')
    ax(3) = gca;
    linkaxes(ax)
    
    figure;plot(t,1.1*declareShatter,'r', t,l,'k')
end

return
