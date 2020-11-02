function metrics=get_metrics(detections,acceptable_latency)

if isempty(detections.LabelTimes)
    LabelList = [0 0];
else
    LabelList=detections.LabelTimes(:,2:end);
end
if isempty(detections.DetectTimes)
    DetectionList = [0 0];
else
    DetectionList=detections.DetectTimes(:,2:end); 
end

if ~isempty(acceptable_latency)
    LabelList(:,2)=LabelList(:,1)+acceptable_latency;
end
T = detections.Duration;
% Associate detections with speech or noise
DetectionType=0*DetectionList(:,1);
% -1 means noise
%  positive numbers map to syllable numbers
metrics.EventDet=-1+0*LabelList;
% First column is latency
% Second column maps to detection

for i=1:size(DetectionList,1)
    
    % Ways it could be speech
    % Det starts before Label and ends after Label
    BefAft=find( ( DetectionList(i,1) <= LabelList(:,1) ) ...
        & ( DetectionList(i,2) >= LabelList(:,2) ) );
    % Det starts before Label and ends before Label
    BefBef=find( ( DetectionList(i,1) <= LabelList(:,1) ) ...
        & ( DetectionList(i,2) >= LabelList(:,1) ) ...
        & ( DetectionList(i,2) <= LabelList(:,2) ) );
    % Det starts after Label and ends after Label
    AftAft=find( ( DetectionList(i,1) >= LabelList(:,1) ) ...
        & ( DetectionList(i,1) <= LabelList(:,2) ) ...
        & ( DetectionList(i,2) >= LabelList(:,2) ) );
    % Det starts after Label and ends before Label
    AftBef=find( ( DetectionList(i,1) >= LabelList(:,1) ) ...
        & ( DetectionList(i,2) <= LabelList(:,2) ) );
    
    % Concatenate the detection maps
    event=[];
    if ~isempty(BefAft); event=[event; BefAft]; end
    if ~isempty(AftBef); event=[event; AftBef]; end
    if ~isempty(AftAft); event=[event; AftAft]; end
    if ~isempty(BefBef); event=[event; BefBef]; end
    
    % If detection map is empty, then it is noise
    if isempty(event)
        DetectionType(i)=-1;
        % Otherwise it is speech
    else
        % Map detection to syllable
        DetectionType(i)=event(1);
        
        % Loop through detected syllable and assign to detection and record latency
        for k=1:length(event)
            Latency=max(0,DetectionList(i,1)-LabelList(event(k),1));
            if Latency<metrics.EventDet(event(k),1) || metrics.EventDet(event(k),2)==-1
                metrics.EventDet(event(k),:)=[Latency i];
            end
        end
        
    end
end
%%% # of syllable hits
%SyllablePerc = sum(SyllableDet(:,2)>=0) / size(SyllableDet,1);
metrics.EventLatency = metrics.EventDet( metrics.EventDet(:,1)>=0 ,1);
if isempty(metrics.EventLatency)
    metrics.EventLatency=1;
end

%%% # of false triggers
%minSpeechDuration=1e-3;

%shortSegmentsToFilter=diff(DetectionList(DetectionType==-1)')<minSpeechDuration;
%Detections=DetectionList(1==(1-shortSegmentsToFilter),:);

%shortSegmentsToFilter = (Detections(2:end,1) - Detections(1:end-1,2)) < minSpeechDuration;
%Detections=Detections(1==(1-shortSegmentsToFilter),:);

metrics.FalseTriggers = sum( DetectionType==-1 );
%FalseTriggers = size(Detections,1);

%% percentage accuracy
tRef=0;
metrics.NoisePresent_NoiseDetected=0;
metrics.NoisePresent_EventDetected=0;
metrics.EventPresent_NoiseDetected=0;
metrics.EventPresent_EventDetected=0;
metrics.FAR=0;
metrics.FRR=0;
% Event types - 1 means detection on
%               2 means detection off
%               3 means label on
%               4 means label off

allEvents=[DetectionList(:,1) ones(size(DetectionList,1),1); ...
    DetectionList(:,2) 2*ones(size(DetectionList,1),1); ...
    LabelList(:,1) 3*ones(size(LabelList,1),1); ...
    LabelList(:,2) 4*ones(size(LabelList,1),1)];
eventsInOrder=sortrows(allEvents,1);

is_label=0;
is_detection=0;

for i=1:size(eventsInOrder,1)
    if eventsInOrder(i,2)==1 % started a detection
        if is_label==0
            metrics.NoisePresent_NoiseDetected = metrics.NoisePresent_NoiseDetected + eventsInOrder(i,1)-tRef;
        else
            metrics.EventPresent_NoiseDetected = metrics.EventPresent_NoiseDetected + eventsInOrder(i,1)-tRef;
        end
        is_detection=1;
    elseif eventsInOrder(i,2)==2 % ended a detection
        if is_label==0
            metrics.NoisePresent_EventDetected = metrics.NoisePresent_EventDetected + eventsInOrder(i,1)-tRef;
        else
            metrics.EventPresent_EventDetected = metrics.EventPresent_EventDetected + eventsInOrder(i,1)-tRef;
        end
        is_detection=0;
    elseif eventsInOrder(i,2)==3 % started a label
        if is_detection==0
            metrics.NoisePresent_NoiseDetected = metrics.NoisePresent_NoiseDetected + eventsInOrder(i,1)-tRef;
        else
            metrics.NoisePresent_EventDetected = metrics.NoisePresent_EventDetected + eventsInOrder(i,1)-tRef;
        end
        is_label=1;
    elseif eventsInOrder(i,2)==4 % ended a label
        if is_detection==0
            metrics.EventPresent_NoiseDetected = metrics.EventPresent_NoiseDetected + eventsInOrder(i,1)-tRef;
        else
            metrics.EventPresent_EventDetected = metrics.EventPresent_EventDetected + eventsInOrder(i,1)-tRef;
        end
        is_label=0;
    end
    tRef = eventsInOrder(i,1);
end

if is_label
    if is_detection
        metrics.EventPresent_EventDetected = metrics.EventPresent_EventDetected + T-tRef;
    else
        metrics.EventPresent_NoiseDetected = metrics.EventPresent_NoiseDetected + T-tRef;
    end
else
    if is_detection
        metrics.NoisePresent_EventDetected = metrics.NoisePresent_EventDetected + T-tRef;
    else
        metrics.NoisePresent_NoiseDetected = metrics.NoisePresent_NoiseDetected + T-tRef;
    end
end

if (metrics.NoisePresent_EventDetected+metrics.NoisePresent_NoiseDetected)
    metrics.FAR = metrics.NoisePresent_EventDetected / (metrics.NoisePresent_EventDetected+metrics.NoisePresent_NoiseDetected);
end
if (metrics.EventPresent_NoiseDetected+metrics.EventPresent_EventDetected)
    metrics.FRR = metrics.EventPresent_NoiseDetected / (metrics.EventPresent_NoiseDetected+metrics.EventPresent_EventDetected);
end
end
