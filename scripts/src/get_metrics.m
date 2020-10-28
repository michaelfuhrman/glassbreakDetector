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
metrics.FalseTriggers = sum( DetectionType==-1 );

%% percentage accuracy
tRef=0;
metrics.noise_detected.correctly.duration=0; %NoisePresent_NoiseDetected
metrics.event_detected.incorrectly.duration=0; %NoisePresent_EventDetected
metrics.noise_detected.incorrectly.duration=0; %EventPresent_NoiseDetected
metrics.event_detected.correctly.duration=0; %EventPresent_EventDetected
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

is_label=false;
is_detection=false;

for i=1:size(eventsInOrder,1)
    eventsInOrder1=eventsInOrder(i,1);
    eventsInOrder2=eventsInOrder(i,2);
    if ((eventsInOrder2 == 1 && ~is_label) || (eventsInOrder2 == 3 && ~is_detection))
        metrics.noise_detected.correctly.duration = metrics.noise_detected.correctly.duration + eventsInOrder1-tRef;
    elseif ((eventsInOrder2 == 1 && is_label) || (eventsInOrder2 == 4 && ~is_detection))
        metrics.noise_detected.incorrectly.duration = metrics.noise_detected.incorrectly.duration + eventsInOrder1-tRef;
    elseif ((eventsInOrder2 == 2 && ~is_label) || (eventsInOrder2 == 3 && is_detection))
        metrics.event_detected.incorrectly.duration = metrics.event_detected.incorrectly.duration + eventsInOrder1-tRef;
    elseif ((eventsInOrder2 == 2 && is_label) || (eventsInOrder2 == 4 && is_detection))
        metrics.event_detected.correctly.duration = metrics.event_detected.correctly.duration + eventsInOrder1-tRef;
    end
    if eventsInOrder2 == 1
        is_detection = true;
    elseif eventsInOrder2 == 2
        is_detection = false;
    elseif eventsInOrder2 == 3
        is_label = true;
    elseif eventsInOrder2 == 4
        is_label = false;
    end
    tRef = eventsInOrder1;
end

if is_label
    if is_detection
        metrics.event_detected.correctly.duration = metrics.event_detected.correctly.duration + T-tRef;
    else
        metrics.noise_detected.incorrectly.duration = metrics.noise_detected.incorrectly.duration + T-tRef;
    end
else
    if is_detection
        metrics.event_detected.incorrectly.duration = metrics.event_detected.incorrectly.duration + T-tRef;
    else
        metrics.noise_detected.correctly.duration = metrics.noise_detected.correctly.duration + T-tRef;
    end
end

event_detected_duration=(metrics.noise_detected.incorrectly.duration+metrics.event_detected.correctly.duration);
noise_detected_duration=(metrics.event_detected.incorrectly.duration+metrics.noise_detected.correctly.duration);
if noise_detected_duration
    metrics.FAR = metrics.event_detected.incorrectly.duration / noise_detected_duration;
end
if event_detected_duration
    metrics.FRR = metrics.noise_detected.incorrectly.duration / event_detected_duration;
end
end