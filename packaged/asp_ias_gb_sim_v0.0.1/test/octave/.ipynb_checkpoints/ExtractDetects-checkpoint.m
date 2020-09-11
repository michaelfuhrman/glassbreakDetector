function [DetectTimes,LabelTimes,Durations]=ExtractDetects(t,y,l,threshold,latency)
    if nargin<5
        latency=[];
    end
    DetectTimes=[]; LabelTimes=[]; Durations=[];

    [DetectTimes{1},LabelTimes{1},Durations(1)]=ExtractSingle(t,y,l,threshold,latency);
end

function [DetectTimes,LabelTimes,Duration]=ExtractSingle(t,y,l,threshold,latency)
    DetectTimes=Detection2List(t,y>threshold);
    DetectTimes=[ones(size(DetectTimes,1),1) DetectTimes];
    LabelTimes=Detection2List(t,l);
    LabelTimes=[ones(size(LabelTimes,1),1) LabelTimes];
    if ~isempty(latency)
        LabelTimes(:,3)=LabelTimes(:,2)+latency;
    end
    Duration=t(end);
end

