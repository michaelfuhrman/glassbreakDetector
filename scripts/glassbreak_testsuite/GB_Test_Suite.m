function res=GB_Test_Suite(ramp, test_name, chain, speed, post_process, datapath)
  % Standardized test battery for glass break testing
  %   ramp: ramp operator used to evaluate performance (in the function
  %   PerfEval())
  %   test_name: A string that identifies this test.
  %   chain: A RAMPdev signal chain to evaluate. The signal chain should take
  %          a single input and should produce a single output. If post_process==1,
  %          the function will sweep over thresholds and overhang integration rates
  %          to generate ROC-type curves, so the input signal chain should not
  %          provide such post-processing; additionally, the function will scale
  %          and center the output as it needs, so you don't need to worry about
  %          the output range. Otherwise, the function will call any value over
  %          0.5 a trigger.
  %   speed: Parameter to shorten the test. When set to 1, the full test is run.
  %          When set to 5, then only a fifth of the test is run.
  %   post_process: 1 to apply sweeps over thresholds and integration rates (for
  %          evaluating signal chains). 0 to simply compare the chain's output
  %          with 0.5 (for final tests).
  %   datapath: Contains paths for test sets for events, interferers and
  %          noise as well as the SPL and SNR levels to test the data

  time=tic;
  numPoints=30;
  sigArrays=[];

  %% Run event SPL sweep
  sigArrays.eventSPL = DatasetSplSweep(datapath.eventset, datapath.event_spl_array, chain);

  %% Run interferer SPL sweep
  sigArrays.interfererSPL = DatasetSplSweep(datapath.interfererset, datapath.event_spl_array, chain);

  %% Run SNR sweep
  SPL_event=94; %Event SPL at 94dB
  SPL_noise=sort(SPL_event-datapath.snr_array);

  % Run test
  sigArrays.snrSPL = DatasetSnrSweep(datapath.eventset,datapath.noiseset, SPL_event,SPL_noise,chain);

  %% Run FAR sweep
  sigArrays.powerFAR= DatasetSplSweep(datapath.noiseset, datapath.noise_spl_array, chain);

  %% Evaluate results
  decFactor=10;
  sigArraysDec=decimateArrays(sigArrays,decFactor);
  if post_process==0
    % The user doesn't want post-processing
    thresh=0.5; % Default threshold level, assume the user has set a digital output
    overhang=[10e3 10e3]; % High overhang rates to not affect the latency, assume the user has already added any decision integration

  else
    % The user wants us to sweep over a range of post-processing options
    [thresh,overhang] = sweepRangeSetup(sigArrays,numPoints);
  end

  res = PerfEval(ramp,sigArraysDec,thresh,overhang);
end


function sig=decimateArrays(sig,decFactor)
  tests=fieldnames(sig);
  for testNum=1:length(tests)
    thisTest=getfield(sig,tests{testNum});

    for s=1:length(thisTest.x)
      ts=thisTest.t{s}; xs=thisTest.x{s}; ls=thisTest.l{s};
      for n=1:length(xs)
        t=ts(n); x=xs(n); l=ls(n);
        tI=decimate(t,decFactor,'fir');
        xI=decimate(x,decFactor,'fir');
        lI=decimate(l,decFactor,'fir')>0.5;
        % subplot(2,1,1); plot(tI,xI); subplot(2,1,2); plot(tI,lI); drawnow;
        ts(n)=tI; xs(n)=xI; ls(n)=lI;
      end
      thisTest.t{s}=ts; thisTest.x{s}=xs; thisTest.l{s}=ls;
    end
    sig=setfield(sig,tests{testNum},thisTest);
  end
end
