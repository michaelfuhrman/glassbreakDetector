run nethw_mic_interface.m
des = ramp_compile(nethw, ramp_ic);
bytestream = des.bytestream.words;
addr = des.bytestream.addr;

% save release_ring_mic_interface_01 bytestream addr
