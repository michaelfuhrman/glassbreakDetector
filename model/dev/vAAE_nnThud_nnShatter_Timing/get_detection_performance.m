function performance=get_detection_performance(detections,acceptable_latency,performance)
if nargin<3
    performance=DETECT_PERFORMANCE();
end
for i=1:length(detections)
    
    metrics_full_label=get_metrics(detections{i},[]);
    metrics_acceptable_label=get_metrics(detections{i},acceptable_latency);
    
    Performance = DETECT_PERFORMANCE;
    Performance.T_total              = detections{i}.Duration;
    Performance.T_Noise_LabeledNoise = metrics_full_label.NoisePresent_NoiseDetected;
    Performance.T_Noise_LabeledEvent = metrics_full_label.NoisePresent_EventDetected;
    Performance.T_Event_LabeledNoise = metrics_acceptable_label.EventPresent_NoiseDetected;
    Performance.T_Event_LabeledEvent = metrics_acceptable_label.EventPresent_EventDetected;
    Performance.FalseTriggers        = metrics_full_label.FalseTriggers;
    Performance.Events_Total         = size(metrics_acceptable_label.EventDet, 1);
    Performance.Events_Missed        = sum(metrics_acceptable_label.EventDet(:, 2) < 0);
    Performance.Events_Latency       = metrics_acceptable_label.EventLatency;
    
    performance=performance+Performance;
end
end