global ramp_ic;
if isempty(ramp_ic)
	ramp_ic.serverInfo=[];
	pkg load ramp_sdk
	chipVersion=1;
	connectionType=1;
	ramp_setup;
end
pkg load analog_discovery
ADopen;
setup;
trim_restore;
for i = 2:4; figure(i); end
