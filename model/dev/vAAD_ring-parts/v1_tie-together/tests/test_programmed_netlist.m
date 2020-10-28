run netlists/ramp66/nethw.m
ramp_compile(nethw, ramp_ic);

run ../setup_audio/setup_audio.m

yHW = ADaoutIn(sig_in + 1.024, 1:2, Fs, t(end));

subplot(1,1,1); plot(t, yHW(:,1:2), t, lab*2);
