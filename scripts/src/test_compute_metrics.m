% Checks metric computation

% -------------------------------------------------------------------------
% No detections on a file with no labels
detections.LabelTimes=[]; detections.DetectTimes=[]; detections.Duration=1; acceptable_latency=[];
output=get_metrics(detections, acceptable_latency); % assert FAR = 0, FRR = 0, ...
assert(output.FAR == 0, 'FAR does not match for test case "No detections on a file with no labels"')
assert(output.FRR == 0, 'FRR does not match for test case "No detections on a file with no labels"')
% -------------------------------------------------------------------------
% Perfect match with one event/label
detections.LabelTimes=[1 1 2]; detections.DetectTimes=[1 1 2]; detections.Duration=3; acceptable_latency=[];
output=get_metrics(detections, acceptable_latency); % assert FAR = 0, FRR = 0, ...
assert(output.FAR == 0, 'FAR does not match for test case "Perfect match with one event/label"')
assert(output.FRR == 0, 'FRR does not match for test case "Perfect match with one event/label"')
% -------------------------------------------------------------------------
% Perfect match with multiple events/labels
detections.LabelTimes=[1 1 2; 1 3 4; 1 5 6]; detections.DetectTimes=[1 1 2; 1 3 4; 1 5 6]; detections.Duration=8; acceptable_latency=[];
output=get_metrics(detections, acceptable_latency); % assert FAR = 0, FRR = 0, ...
assert(output.FAR == 0, 'FAR does not match for test case "Perfect match with multiple events/labels"')
assert(output.FRR == 0, 'FRR does not match for test case "Perfect match with multiple events/labels"')
% -------------------------------------------------------------------------
% One false alarm with one label
detections.LabelTimes=[1 1 2]; detections.DetectTimes=[1 1 2; 1 3 4]; detections.Duration=6; acceptable_latency=[];
output=get_metrics(detections, acceptable_latency);
assert(output.FAR == 0.2, 'FAR does not match for test case "One false alarm with one label"')
assert(output.FRR == 0, 'FRR does not match for test case "One false alarm with one label"')
% -------------------------------------------------------------------------
% One false alarm with multiple labels
detections.LabelTimes=[1 1 2; 1 3 4]; detections.DetectTimes=[1 1 2; 1 3 4; 1 4.5 5]; detections.Duration=6; acceptable_latency=[];
output=get_metrics(detections, acceptable_latency);
assert(output.FAR == 0.125, 'FAR does not match for test case "One false alarm with multiple labels"')
assert(output.FRR == 0, 'FRR does not match for test case "One false alarm with multiple labels"')
% -------------------------------------------------------------------------
% One missed detection with one label
detections.LabelTimes=[1 1 2]; detections.DetectTimes=[]; detections.Duration=6; acceptable_latency=[];
output=get_metrics(detections, acceptable_latency);
assert(output.FAR == 0, 'FAR does not match for test case "One missed detection with one label"')
assert(output.FRR == 1, 'FRR does not match for test case "One missed detection with one label"')
% -------------------------------------------------------------------------
% One missed detection with multiple labels
detections.LabelTimes=[1 1 2; 1 3 4]; detections.DetectTimes=[1 1 2]; detections.Duration=6; acceptable_latency=[];
output=get_metrics(detections, acceptable_latency);
assert(output.FAR == 0, 'FAR does not match for test case "One missed detection with multiple labels"')
assert(output.FRR == 0.5, 'FRR does not match for test case "One missed detection with multiple labels"')
% -------------------------------------------------------------------------
% One missed detection and one false positive with multiple labels
detections.LabelTimes=[1 1 2; 1 3 4]; detections.DetectTimes=[1 1 2; 1 4 5]; detections.Duration=6; acceptable_latency=[];
output=get_metrics(detections, acceptable_latency);
assert(output.FAR == 0.25, 'FAR does not match for test case "One missed detection and one false positive with multiple labels"')
assert(output.FRR == 0.5, 'FRR does not match for test case "One missed detection and one false positive with multiple labels"')
% -------------------------------------------------------------------------
% One partial detection with one label
detections.LabelTimes=[1 1 2]; detections.DetectTimes=[1 1 1.5]; detections.Duration=3; acceptable_latency=[];
output=get_metrics(detections, acceptable_latency);
assert(output.FAR == 0, 'FAR does not match for test case "One partial detection with one label"')
assert(output.FRR == 0.5, 'FRR does not match for test case "One partial detection with one label"')
% -------------------------------------------------------------------------
% One partial detection, other perfect detections with multiple labels
detections.LabelTimes=[1 1 2; 1 3 4; 1 5 6]; detections.DetectTimes=[1 1 1.5; 1 3 4; 1 5 6]; detections.Duration=6; acceptable_latency=[];
output=get_metrics(detections, acceptable_latency);
assert(output.FAR == 0, 'FAR does not match for test case "One partial detection, other perfect detections with multiple labels"')
assert(output.FRR == 0.5/3, 'FRR does not match for test case "One partial detection, other perfect detections with multiple labels"')
% -------------------------------------------------------------------------
% One partial detection, one missed detection, one false detection with multiple labels
detections.LabelTimes=[1 1 2; 1 3 4]; detections.DetectTimes=[1 1 1.5; 1 5 6]; detections.Duration=6; acceptable_latency=[];
output=get_metrics(detections, acceptable_latency);
assert(output.FAR == 1/4, 'FAR does not match for test case "One partial detection, one missed detection, one false detection with multiple labels"')
assert(output.FRR == (1+0.5)/2, 'FRR does not match for test case "One partial detection, one missed detection, one false detection with multiple labels"')
% -------------------------------------------------------------------------
% Detection after acceptable_latency with one label
% Anything beyond acceptable latency is considered as non-event
detections.LabelTimes=[1 1 2]; detections.DetectTimes=[1 1.5 2]; detections.Duration=2; acceptable_latency=0.5;
output=get_metrics(detections, acceptable_latency);
assert(output.FAR == 0.5/(1+0.5), 'FAR does not match for test case "Detection after acceptable_latency with one label"')
assert(output.FRR == 1, 'FRR does not match for test case "Detection after acceptable_latency with one label"')
% To not consider event as a false positive after acceptable latency, FAR is computed
% with full label
output=get_metrics(detections, []);
assert(output.FAR == 0, 'FAR does not match for test case "Detection after acceptable_latency with one label"')
% -------------------------------------------------------------------------
% One detection after acceptable label, one within and a false positive
% Anything beyond acceptable latency is considered as non-event
detections.LabelTimes=[1 1 2; 1 3 4]; detections.DetectTimes=[1 1.5 2; 1 3 4; 1 5 6]; detections.Duration=6; acceptable_latency=0.5;
output=get_metrics(detections, acceptable_latency);
assert(output.FAR == (0.5+0.5+1)/(1+0.5+1+0.5+2), 'FAR does not match for test case "ne detection after acceptable label, one within and a false positive"')
assert(output.FRR == (0.5)/1, 'FRR does not match for test case "ne detection after acceptable label, one within and a false positive"')
% To not consider event as a false positive after acceptable latency, FAR is computed
% with full label
output=get_metrics(detections, []);
assert(output.FAR == 1/4, 'FRR does not match for test case "Detection after acceptable_latency with one label"')
% -------------------------------------------------------------------------
