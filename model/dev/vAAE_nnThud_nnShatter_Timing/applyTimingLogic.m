function [declareThud,declareShatter] = applyTimingLogic(t,x,l,ynnThud, ynnShatter, declareThud,declareShatter,SUBTRACTNNS)

% ThudChain and Shatter chain generate the declarations
%Thud = ThudChain(t,x);
%Shatter = ShatterChain(t,x);

%Thud = 2.5*Thud;
%Shatter = 2.5*Shatter;

%% Chains should do the following 
% ynnThud -> Pulse -> (thudPulse) -> 50msec wide thud pulse (wideThudPulse)
% ynnShatter -> Pulse -> (shatterPulse) -> 200msec wide shatter pulse (wideShatterPulse)

% Suppress thudPulse under the wide shatter pulse (AND with inverted wideShatterPulse); call the remainder validThudPulses
% Suppress shatterPulse that are NOT under 50msec wide validThudPulses (validShatterPulse)

% How close can two Thud/Shatter combinations be before we merge them?
% 200msec?

figure(100);
subplot(211)
plot(t,1.1*declareThud,'b','linewidth',1);hold on;plot(t,1.1*declareShatter,'r','linewidth',.5);plot(t,.9*l,'k');
title({'Thud without Shatter is OK: Thud Should Trigger Infineon Detector', 'Shatter Occurs only after Thud', 'Shatter before Thud Suppresses Thud','Shatter before Shatter Suppresses Later Shatter'})
xlabel('Time (seconds)')
legend('Thud','Shatter','Labels')
v=axis;v(4)=1.1;axis(v)
ax(1) = gca;
    

% What do we see:
%    1) Would like to keep last Thud in a series, but that's not possible since
%       we don't know when it will occur
%    2) Only want to keep first Shatter within a series of pulses after the
%       last Thud. Basically debounce shatter until the next Thud.
%    3) Thud less than Xmsec after shatter should be suppressed


%%
ramp_operator_setup;

% Additions to the original chain
AND = ramp.logic.gate('type','and');

Cmp = ramp.ops.cmp('thresh',.5);
CMPpt5 = ramp.ops.cmp('thresh',.5);

% Pulse name defines width in seconds; triggers on rising edge
PULSE100=ramp.ops.pulse('time',.1);
PULSE50=ramp.ops.pulse('time',.05);
PULSE10=ramp.ops.pulse('time',1e-2);
PULSE1=ramp.ops.pulse('time',1e-3);
PULSE01=ramp.ops.pulse('time',1e-4);
PULSE001=ramp.ops.pulse('time',1e-5);
PULSE0001=ramp.ops.pulse('time',1e-6);
NOT = ramp.logic.gate('type','not');

OVERHANG = ramp.ops.overhang('up',1e3, 'down',10) > ramp.ops.cmp('thresh',.2);

% figure;plot(t,Thud,'b',t,Shatter,'r',t,l,'k')
% axis([1.3895    2.5815    0.3560    2.5506])
% title('Thud and Shatter')



if 0 % Not used
    % Delay the onset for declaring shatter
    DELAY5=ramp.ops.delay('delay',.005);
    % Shatter declaration comes into the subroutine; now we delay it
    %delayedShatter = PULSE1(t,NOT(t,DELAY5(t,Shatter)));
    DELAYEDSHATTER = DELAY5 > NOT > PULSE1;
    delayedShatter = DELAYEDSHATTER(t,declareShatter);
end

% This is for a window extending from Thud over Shatter
Chain50 = CMPpt5 > PULSE1> NOT > ramp.ops.pulse('time',.05);
Chain200 = CMPpt5 > PULSE1> NOT > ramp.ops.pulse('time',.2);
Chain200NOT = CMPpt5 > PULSE1> NOT > ramp.ops.pulse('time',.2)>NOT;

% This is for a short declareShatter pulse
ShatterChain = CMPpt5 > PULSE0001;

if SUBTRACTNNS==true
    ynnThudTemp = ynnThud-10*ynnShatter;
    ynnShatterTemp = ynnShatter-10*ynnThud;
    ynnThud=ynnThudTemp;
    ynnShatter=ynnShatterTemp;
end

% The ynnThud generate a single pulse
ThudChain = CMPpt5 > PULSE0001;
thudPulse = ThudChain(t,ynnThud);

% A valid thud is one that has not been immediately preceded by shatter
shatterPulse = ShatterChain(t,ynnShatter);

%% OK to here
if 0
    figure;plot(t,thudPulse,'b',t,shatterPulse,'r', t,l,'k')
    title('thudPulse and shatterPulse')
end

% The 50msec wide Thud pulse begins at the end of the inverted Thud
wideThudPulseChain = CMPpt5 > PULSE0001 > NOT > ramp.ops.pulse('time',.1);

%% The wide pulses
% Wait for valid pulses
wideThudPulse = wideThudPulseChain(t,thudPulse);

% The 200msec wide Shatter pulse begins at the end of the inverted Shatter
wideShatterPulseChain = CMPpt5 > PULSE0001 > NOT > ramp.ops.pulse('time',.2);
wideShatterPulse = wideShatterPulseChain(t,shatterPulse);

% ... except it's inverted to suppress any thuds which occur (same 200msec
% pulse width ### How much time should we give shatter to die down?
wideShatterPulseChainNOT = CMPpt5 > PULSE0001 > NOT > ramp.ops.pulse('time',.2)> NOT;
extraWideShatterPulseChainNOT = NOT > ramp.ops.pulse('time',1)> NOT;

wideShatterPulseNOT = wideShatterPulseChainNOT(t,ynnShatter);

%% Test
% Check wideShatterPulseNOT
if 0
    figure;
    plot(t,.16*thudPulse .* wideShatterPulseNOT,'b',t,.9*l,'k')
    title('thudPulse .* wideShatterPulseNOT')
end

%%
% Valid Thuds occur long after shatter
validThudPulseChain = [ThudChain;
                    wideShatterPulseChainNOT] > AND;
                
validThudPulse = validThudPulseChain(t,[transpose(ynnThud), transpose(ynnShatter)]);

if 0
    figure;plot(t,validThudPulse,'b',t,l,'k')
    title('validThudPulse')
end

% Grab shatter close to the Valid thud
wideValidThudPulse = wideThudPulseChain(t,validThudPulse);

debouncedValidThudPulse = PULSE0001(t,wideValidThudPulse);

% validShatterPulseChain = [wideThudPulseChain;
%                                 ShatterChain] > AND;
    
validShatterPulse = AND(t,[wideValidThudPulse, shatterPulse]);
if 0
    figure(100);
    subplot(212)
    plot(t,.44*validThudPulse,'b','linewidth',1);hold on;plot(t,.44*validShatterPulse,'r',t,.9*l,'k')
    title({'Not Using Overhang: Valid Thud Followed by Valid Shatter','Every Shatter Has a Thud Associated With It'})
    ax(2) = gca;
    linkaxes(ax);
end

% Try debouncing
if 0
AND = ramp.logic.gate('type','and');
OVERHANG = ramp.ops.overhang('up',1e3, 'down',10) > ramp.ops.cmp('thresh',.2);
OVERHANGandPULSE = ramp.ops.overhang('up',1e3, 'down',10) > ramp.ops.cmp('thresh',.6) > ramp.ops.pulse('time',1e-3);

declareShatter=.4*AND(t,[OVERHANG(t,validThudPulse) validShatterPulse]);
%declareShatter=(.4*OVERHANG(t,2.5*declareShatter));

declareThud=(.4*OVERHANGandPULSE(t,validShatterPulse));
end
return

%% Debounce, i.e., merge closely spaced thuds and shatter?
wideValidShatterPulse = wideShatterPulseChainNOT(t,validShatterPulse);
extraWideValidShatterPulse = extraWideShatterPulseChainNOT(t,validShatterPulse);

debouncedValidShatterPulse = PULSE0001(t,wideValidShatterPulse);

figure;plot(t,debouncedValidThudPulse,'b','linewidth',1);hold on;plot(t,debouncedValidShatterPulse,'r',t,l,'k')
title({'Debounced Valid Thud Followed by Valid Shatter','Every Shatter Has a Thud Associated With It'})

return
%validThudPulse = AND(t,[thudPulse, wideShatterPulseNOT]);


wideShatterPulseNOT = wideShatterPulseChainNOT(t,ynnShatter);

figure;plot(t,thudPulse,'g',t,AND(t,[thudPulse, wideShatterPulseNOT]),'r');
title('Thud Not Immediately Preceded by Shatter')


wideThudPulse = wideThudPulseChain(t, ynnThud);

% validWideThudPulse has to start with a valid Thud pulse which is not too
% close to shatter
validWideThudPulse = wideThudPulseChain(t, ynnThud);

shatterPulseUnderWideThudPulse = AND(shatterPulse,wideThudPulse);
figure;plot(t,thudPulse,'b', t,shatterPulseUnderWideThudPulse,'r',t,l,'k')
title('Thud Followed by Shatter within 50msec')



THUDSHATTER = [ThudChain > Chain50;ShatterChain]>AND;


thudshatter = THUDSHATTER(t,[ynnThud ynnShatter]);

NOTSHATTER = ShatterChain > NOT; 

figure;plot(t,Chain50(t,declareThud),'b',t,ShatterChain(t,ynnShatter),'r', t,l,'k')
title('Thud OverHanging Shatter by 50msec')

figure;plot(t,Chain200(t,declareShatter),'r',t,2.5*declareThud,'b', t,l,'k')
title('Shatter OverHanging Thud by 200msec')


figure;plot(t,Chain200(t,declareShatter),'r',t,Chain200NOT(t,declareShatter).*declareThud,'b', t,l,'k')
title('Surviving Thuds')



% figure;plot(t,Thud,'b',t,delayedShatter,'r',t,l,'k');
% axis([1.3895    2.5815    0.3560    2.5506])

NOTShatter = NOT(t,PULSE1(t,NOT(t,DELAY5(t,declareShatter))));
%NOTSHATTER = DELAY5 > NOT > PULSE1 > NOT > ShatterChain;

%NOTShatter = NOTSHATTER(t,x);

% Gather shatter within 50 msec
%wideThud = PULSE50(t,NOT(t,Thud));
WIDETHUD = NOT > PULSE50 > ThudChain;
wideThud = WIDETHUD(t,x);
% figure;plot(t,wideThud,'b',t,delayedShatter,'r',t,l,'k');
% axis([1.3895    2.5815    0.3560    2.5506])

% Suppress thuds in the midst of shatter leaving valid thuds
%validThud = AND(t,[wideThud NOTShatter]);
VALIDTHUD = [WIDETHUD;NOTSHATTER] > AND;
validThud = VALIDTHUD(t,[wideThud NOTShatter]);
declareThud = PULSE1(t,validThud);

% figure;plot(t,wideThud,'b',t,AND(t,[wideThud delayedShatter]),'r',t,l,'k');
% axis([1.3895    2.5815    0.3560    2.5506])

declareShatter = AND(t,[wideThud delayedShatter]);
figure;plot(t,declareThud,'b',t,declareShatter,'r',t,l,'k');
return
