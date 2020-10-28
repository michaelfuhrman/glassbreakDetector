function detections=get_detections(t,y,l,threshold)

if iscell(t) || isa(t,'SIGNAL_ARRAY')
    for i=1:length(t)
        detections{i}=get_detection(t{i},y{i},l{i},threshold);
    end
else
    detections{1}=get_detection(t,y,l,threshold);
end
end

function detection=get_detection(t,y,l,threshold)
DetectTimes=Detection2List(t,y>threshold);
detection.DetectTimes=[ones(size(DetectTimes,1),1) DetectTimes];
LabelTimes=Detection2List(t,l);
detection.LabelTimes=[ones(size(LabelTimes,1),1) LabelTimes];
detection.Duration=t(end)-t(1);
end
