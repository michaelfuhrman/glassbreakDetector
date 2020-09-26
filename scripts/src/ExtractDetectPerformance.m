function performance=ExtractDetectPerformance(DetectTimes,LabelTimes,Durations,performance)
  if nargin<4
    performance=DETECT_PERFORMANCE();
  end
  for i=1:length(DetectTimes)
    performance=performance+DetectPerformance(DetectTimes{i}(:,2:end),LabelTimes{i}(:,2:end),Durations(i));
  end
end
