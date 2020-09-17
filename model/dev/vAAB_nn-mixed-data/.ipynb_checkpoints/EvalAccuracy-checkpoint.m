% Helper functions for extraction FAR, etc.
function acc = EvalAccuracy(t, y, l)
    DetectTimes = Detection2List(t, y>0.5);
    DetectTimes = [ones(size(DetectTimes,1),1) DetectTimes];
    
    LabelTimes = Detection2List(t, l);
    LabelTimes = [ones(size(LabelTimes, 1), 1) LabelTimes];

    Durations = t(end);
    
    acc = DetectPerformance( DetectTimes(:, 2:end), ...
                             LabelTimes(:, 2:end), ...
                             Durations);
end