function acc = EvaluateAccuracy(t,y,l,threshold,latency)
  acc = DETECT_PERFORMANCE();
  [DetectTimes,LabelTimes,Durations]=ExtractDetections(t,y,l,threshold);
  %acc=ExtractDetectPerformance(DetectTimes,LabelTimes,Durations,latency,acc);
  acc=get_detection_performance(DetectTimes,latency,acc);
end

