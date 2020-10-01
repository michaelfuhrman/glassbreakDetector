
function lpfPulseTrain
close all
ramp_operator_setup
Cmp=ramp.ops.cmp('thresh',.8,'settleTime',.02,'printTimeStamp',1);
Lpf=ramp.ops.lpf('fc',100);
Fs=16000; t=0:1/Fs:.5; 
x=sin(100*t);
y = Cmp(t,x);

figure
plot(t,y,t,Lpf(t,y));

return