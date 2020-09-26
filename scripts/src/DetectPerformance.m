function [Performance] = DetectPerformance(DetectionList, LabelList, T)

if isempty(LabelList)
  LabelList = [0 0];
end

% Associate detections with events or noise
DetectionType = 0 * DetectionList(:, 1);
   % -1 means noise
   %  positive numbers map to event numbers
EventDet = -1 + 0 * LabelList;
   % First column is latency
   % Second column maps to detection

for i = 1 : size(DetectionList, 1)

  % Ways it could be an event
    % Det starts before Label and ends after Label
    BefAft = find( ( DetectionList(i, 1) <= LabelList(:, 1) ) ...
        & ( DetectionList(i, 2) >= LabelList(:, 2) ) );
    % Det starts before Label and ends before Label
    BefBef = find( ( DetectionList(i, 1) <= LabelList(:, 1) ) ...
        & ( DetectionList(i, 2) >= LabelList(:, 1) ) ...
        & ( DetectionList(i, 2) <= LabelList(:, 2) ) );
    % Det starts after Label and ends after Label
    AftBef = find( ( DetectionList(i, 1) >= LabelList(:, 1) ) ...
        & ( DetectionList(i, 1) <= LabelList(:, 2) ) ...
        & ( DetectionList(i, 2) >= LabelList(:, 2) ) );
    % Det starts after Label and ends before Label
    AftAft = find( ( DetectionList(i, 1) >= LabelList(:, 1) ) ...
        & ( DetectionList(i, 2) <= LabelList(:, 2) ) );

  % Concatenate the detection maps
  event = [];
  if ~isempty(BefAft); event=[event; BefAft]; end
  if ~isempty(AftBef); event=[event; AftBef]; end
  if ~isempty(AftAft); event=[event; AftAft]; end
  if ~isempty(BefBef); event=[event; BefBef]; end

  % If detection map is empty, then it is noise
  if isempty(event) 
    DetectionType(i) = -1;
    
  % Otherwise it is an event
  else
    % Map detection to event
    DetectionType(i) = event(1);

    % Loop through detected event and assign to detection and record latency
    for k = 1 : length(event)
      Latency = max(0, DetectionList(i, 1) - LabelList(event(k), 1));
      if Latency < EventDet(event(k), 1) || EventDet(event(k), 2) == -1
        EventDet(event(k), :) = [Latency i];
      end      
    end
    
  end
end


% Statistics
EventLatency = EventDet( EventDet(:, 1) >= 0, 1);
if isempty(EventLatency)
  EventLatency = 1;
end

FalseTriggers = sum( DetectionType == -1 );

%% percentage accuracy
tRef = 0;
NoisePresent_NoiseDetected = 0;
NoisePresent_EventDetected = 0;
EventPresent_NoiseDetected = 0;
EventPresent_EventDetected = 0;

% Event types - 1 means detection on
%               2 means detection off
%               3 means label on
%               4 means label off

allEvents = [DetectionList(:, 1)        ones(size(DetectionList, 1), 1); ...
             DetectionList(:, 2)      2*ones(size(DetectionList, 1), 1); ...
             LabelList(:,     1)      3*ones(size(LabelList,     1), 1); ...
             LabelList(:,     2)      4*ones(size(LabelList,     1), 1)];
eventsInOrder = sortrows(allEvents, 1);

labelType = 0; detectionType = 0;
for i = 1 : size(eventsInOrder, 1)
  if eventsInOrder(i, 2) == 1 % started a detection
    if labelType==0
      NoisePresent_NoiseDetected = NoisePresent_NoiseDetected + eventsInOrder(i, 1) - tRef;
    else
      EventPresent_NoiseDetected = EventPresent_NoiseDetected + eventsInOrder(i, 1) - tRef;
    end
    detectionType = 1;
  elseif eventsInOrder(i, 2) == 2 % ended a detection
    if labelType == 0
      NoisePresent_EventDetected = NoisePresent_EventDetected + eventsInOrder(i, 1) - tRef;
    else
      EventPresent_EventDetected = EventPresent_EventDetected + eventsInOrder(i, 1) - tRef;
    end
    detectionType = 0;
  elseif eventsInOrder(i, 2) == 3 % started a label
    if detectionType == 0
      NoisePresent_NoiseDetected = NoisePresent_NoiseDetected + eventsInOrder(i, 1) - tRef;
    else
      NoisePresent_EventDetected = NoisePresent_EventDetected + eventsInOrder(i, 1) - tRef;
    end
    labelType=1;
  elseif eventsInOrder(i, 2) == 4 % ended a label
    if detectionType==0
      EventPresent_NoiseDetected = EventPresent_NoiseDetected + eventsInOrder(i, 1) - tRef;
    else
      EventPresent_EventDetected = EventPresent_EventDetected + eventsInOrder(i, 1) - tRef;
    end
    labelType = 0;
  end
  tRef = eventsInOrder(i, 1);
end

if labelType==0 && detectionType==0
  NoisePresent_NoiseDetected = NoisePresent_NoiseDetected + T-tRef;
elseif labelType==0 && detectionType==1
  NoisePresent_EventDetected = NoisePresent_EventDetected + T-tRef;
elseif labelType==1 && detectionType==0
  EventPresent_NoiseDetected = EventPresent_NoiseDetected + T-tRef;
elseif labelType==1 && detectionType==1
  EventPresent_EventDetected = EventPresent_EventDetected + T-tRef;
end

Performance = DETECT_PERFORMANCE;
Performance.T_total              = T;
Performance.T_Noise_LabeledNoise = NoisePresent_NoiseDetected;
Performance.T_Noise_LabeledEvent = NoisePresent_EventDetected;
Performance.T_Event_LabeledNoise = EventPresent_NoiseDetected;
Performance.T_Event_LabeledEvent = EventPresent_EventDetected;
Performance.FalseTriggers        = FalseTriggers;
Performance.Events_Total         = size(EventDet, 1);
Performance.Events_Missed        = sum(EventDet(:, 2) < 0);
Performance.Events_Latency       = EventLatency;
