function [Performance]=DetectPerformance(DetectionList,LabelList,T)

if isempty(LabelList)
  LabelList=[0 0];
end

% Associate detections with speech or noise
DetectionType=0*DetectionList(:,1);
   % -1 means noise
   %  positive numbers map to syllable numbers
SyllableDet=-1+0*LabelList;
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
    AftBef=find( ( DetectionList(i,1) >= LabelList(:,1) ) ...
        & ( DetectionList(i,1) <= LabelList(:,2) ) ...
        & ( DetectionList(i,2) >= LabelList(:,2) ) );
    % Det starts after Label and ends before Label
    AftAft=find( ( DetectionList(i,1) >= LabelList(:,1) ) ...
        & ( DetectionList(i,2) <= LabelList(:,2) ) );

  % Concatenate the detection maps
  syllable=[];
  if ~isempty(BefAft); syllable=[syllable; BefAft]; end
  if ~isempty(AftBef); syllable=[syllable; AftBef]; end
  if ~isempty(AftAft); syllable=[syllable; AftAft]; end
  if ~isempty(BefBef); syllable=[syllable; BefBef]; end

  % If detection map is empty, then it is noise
  if isempty(syllable) 
    DetectionType(i)=-1;
    
  % Otherwise it is speech
  else
    % Map detection to syllable
    DetectionType(i)=syllable(1);
    

    % Loop through detected syllable and assign to detection and record latency
    for k=1:length(syllable)
      Latency=max(0,DetectionList(i,1)-LabelList(syllable(k),1));
      if Latency<SyllableDet(syllable(k),1) || SyllableDet(syllable(k),2)==-1
        SyllableDet(syllable(k),:)=[Latency i];
      end      
    end
    
  end
end


%%% # of syllable hits
SyllablePerc = sum(SyllableDet(:,2)>=0) / size(SyllableDet,1);
SyllableLatency = SyllableDet( SyllableDet(:,1)>=0 ,1);
if isempty(SyllableLatency)
  SyllableLatency=1;
end

%%% # of false triggers
%minSpeechDuration=1e-3;

%shortSegmentsToFilter=diff(DetectionList(DetectionType==-1)')<minSpeechDuration;
%Detections=DetectionList(1==(1-shortSegmentsToFilter),:);

%shortSegmentsToFilter = (Detections(2:end,1) - Detections(1:end-1,2)) < minSpeechDuration;
%Detections=Detections(1==(1-shortSegmentsToFilter),:);

FalseTriggers = sum( DetectionType==-1 );
%FalseTriggers = size(Detections,1);

%% percentage accuracy
tRef=0;
NoisePresent_NoiseDetected=0;
NoisePresent_SpeechDetected=0;
SpeechPresent_NoiseDetected=0;
SpeechPresent_SpeechDetected=0;

% Event types - 1 means detection on
%               2 means detection off
%               3 means label on
%               4 means label off

allEvents=[DetectionList(:,1) ones(size(DetectionList,1),1); ...
           DetectionList(:,2) 2*ones(size(DetectionList,1),1); ...
           LabelList(:,1) 3*ones(size(LabelList,1),1); ...
           LabelList(:,2) 4*ones(size(LabelList,1),1)];
eventsInOrder=sortrows(allEvents,1);

labelType=0; detectionType=0;
for i=1:size(eventsInOrder,1)
  if eventsInOrder(i,2)==1 % started a detection
    if labelType==0
      NoisePresent_NoiseDetected = NoisePresent_NoiseDetected + eventsInOrder(i,1)-tRef;
    else
      SpeechPresent_NoiseDetected = SpeechPresent_NoiseDetected + eventsInOrder(i,1)-tRef;
    end
    detectionType=1;
  elseif eventsInOrder(i,2)==2 % ended a detection
    if labelType==0
      NoisePresent_SpeechDetected = NoisePresent_SpeechDetected + eventsInOrder(i,1)-tRef;
    else
      SpeechPresent_SpeechDetected = SpeechPresent_SpeechDetected + eventsInOrder(i,1)-tRef;
    end
    detectionType=0;
  elseif eventsInOrder(i,2)==3 % started a label
    if detectionType==0
      NoisePresent_NoiseDetected = NoisePresent_NoiseDetected + eventsInOrder(i,1)-tRef;
    else
      NoisePresent_SpeechDetected = NoisePresent_SpeechDetected + eventsInOrder(i,1)-tRef;
    end
    labelType=1;
  elseif eventsInOrder(i,2)==4 % ended a label
    if detectionType==0
      SpeechPresent_NoiseDetected = SpeechPresent_NoiseDetected + eventsInOrder(i,1)-tRef;
    else
      SpeechPresent_SpeechDetected = SpeechPresent_SpeechDetected + eventsInOrder(i,1)-tRef;
    end
    labelType=0;
  end
  tRef = eventsInOrder(i,1);
end

if labelType==0 && detectionType==0
  NoisePresent_NoiseDetected = NoisePresent_NoiseDetected + T-tRef;
elseif labelType==0 && detectionType==1
  NoisePresent_SpeechDetected = NoisePresent_SpeechDetected + T-tRef;
elseif labelType==1 && detectionType==0
  SpeechPresent_NoiseDetected = SpeechPresent_NoiseDetected + T-tRef;
elseif labelType==1 && detectionType==1
  SpeechPresent_SpeechDetected = SpeechPresent_SpeechDetected + T-tRef;
end

FAR = NoisePresent_SpeechDetected / (NoisePresent_SpeechDetected+NoisePresent_NoiseDetected);
FRR = SpeechPresent_NoiseDetected / (SpeechPresent_NoiseDetected+SpeechPresent_SpeechDetected);
%SpeechPresent_SpeechDetected+SpeechPresent_NoiseDetected+NoisePresent_NoiseDetected+NoisePresent_SpeechDetected

Performance=DETECT_PERFORMANCE;
Performance.T_total=T;
Performance.T_Noise_LabeledNoise=NoisePresent_NoiseDetected;
Performance.T_Noise_LabeledSpeech=NoisePresent_SpeechDetected;
Performance.T_Speech_LabeledNoise=SpeechPresent_NoiseDetected;
Performance.T_Speech_LabeledSpeech=SpeechPresent_SpeechDetected;
Performance.FalseTriggers=FalseTriggers;
Performance.Syllables_Total=size(SyllableDet,1);
Performance.Syllables_Missed=sum(SyllableDet(:,2)<0);
Performance.Syllables_Latency=SyllableLatency;
