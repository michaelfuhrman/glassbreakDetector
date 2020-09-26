function [DetectTimes,LabelTimes,Durations]=ExtractDetections(t,y,l,threshold,latency)
	if nargin<5
		latency=[];
	end
	DetectTimes=[]; LabelTimes=[]; Durations=[];

	if iscell(t) || isa(t,'SIGNAL_ARRAY')
		for i=1:length(t)
            [DetectTimes{i},LabelTimes{i},Durations(i)]=ExtractSingle(t{i},y{i},l{i},threshold,latency);
		end
	else
		[DetectTimes{1},LabelTimes{1},Durations(1)]=ExtractSingle(t,y,l,threshold,latency);
	end
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

