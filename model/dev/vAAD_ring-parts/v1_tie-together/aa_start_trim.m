global ramp_ic;
ramp_ic.serverInfo=[];
pkg load ramp_sdk
pkg load analog_discovery
ADopen;
chipVersion=1;
connectionType=1;
ramp_setup;
setup;
trim_restore;
for i = 2:4; figure(i); end
