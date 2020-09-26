function res = PerfEval(ramp,sigArrays,thresh,overhang)
  % Evaluate performance over all tests in sigArray for all rows in threshold/overhang
  % res = PerfEval(sigArrays,thresh,overhang)
  % Inputs
  %    - ramp: Use ramp operators as part of performance evaluation
  %    - sigArrays: struct of tests with sig arrays for each test, should have the form
  %         sigArrays.test1.t, sigArrays.test1.x, sigArrays.test1.l, sigArrays.test1.SPL, sigArrays.test1.SNR
  %         sigArrays.test2.t, sigArrays.test2.x, sigArrays.test2.l, sigArrays.test2.SPL, sigArrays.test2.SNR
  %         ...
  %         where t,x,l are cell arrays of time, output, and label SIGNAL_ARRAYs and SPL/SNR are the SPL and SNR for that test
  %    - thresh: column vector of thresholds to evaluate
  %    - overhang: two-column vector of overhangs to evaluate
  %      note: does not evaluate for all combinations of thresh/overhang, so use something like sweepRangeSetup to generate a set
  % Outputs
  %    - res: struct of results for each test, while have the form
  %      res.test1.thresh,  res.test1.overhang, res.test1.spl,        res.test1.snr,            res.test1.labels, res.test1.triggers,
  %      res.test1.latency, res.test1.detect,   res.test1.false_trig, res.test1.false_on_time,  res.test1.noise_time
  %      res.test2.thresh,  res.test2.overhang, res.test2.spl,        res.test2.snr,            res.test2.labels, res.test2.triggers,
  %      res.test2.latency, res.test2.detect,   res.test2.false_trig, res.test2.false_on_time,  res.test2.noise_time
  %      res.summary.*

  res=[];
  res.settings.thresh=thresh;
  res.settings.overhang=overhang;

  tests=fieldnames(sigArrays);

  for testNum=1:length(tests)
    thisTest=getfield(sigArrays,tests{testNum});

    resTest=[];
    resTest.thresh=[]; resTest.overhang=[]; resTest.spl=[]; resTest.snr=[]; resTest.labels={};
    resTest.triggers={}; resTest.latency=[]; resTest.detect=[]; resTest.false_trig=[];
    resTest.false_on_time=[]; resTest.noise_time=[];

    % Sweep over thresh/overhang
    for to=1:length(thresh)
      fprintf('%s; %d of %d\n',tests{testNum},to,length(thresh));
      PostChain = ramp.ops.cmp('thresh',thresh(to)) > ramp.ops.overhang('up',overhang(1), 'down',overhang(2));

      % Sweep through each setting
      performance=[];
      for s=1:length(thisTest.t)
        jsonFile=struct('source','Aspinity', 'dataset','PerfEval');
        dataset_txl=struct('t',thisTest.t{s}, 'x',thisTest.x{s}, 'l',thisTest.l{s}, 'jsonFile',jsonFile);
        [t,y,l]=EvalChainSet(PostChain,dataset_txl,1);
        [DetectTimes,LabelTimes,Durations]=ExtractDetections(t,y,l,0.5);
        performance{s}=ExtractDetectPerformance(DetectTimes,LabelTimes,Durations);

        resTest.thresh(end+1)=thresh(to);
        resTest.overhang(end+1,:)=overhang(to,:);
        resTest.spl(end+1)=thisTest.SPL(s);
        resTest.snr(end+1)=thisTest.SNR(s);
        for lt=1:length(LabelTimes)
          resTest.labels{length(resTest.snr),lt}=LabelTimes{lt};
          resTest.triggers{length(resTest.snr),lt}=DetectTimes{lt};
        end
        resTest.latency(end+1,:)=performance{s}.Events_Latency';
        resTest.detect(end+1,:)=performance{s}.Events_Latency'<1;
        resTest.false_trig(end+1)=performance{s}.FalseTriggers;
        resTest.false_on_time(end+1)=performance{s}.T_Noise_LabeledEvent;
        resTest.noise_time(end+1)=performance{s}.T_Noise_LabeledEvent+performance{s}.T_Noise_LabeledNoise;
      end

    end

    res=setfield(res,tests{testNum},resTest);
  end
end
