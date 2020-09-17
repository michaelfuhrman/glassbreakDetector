function Detections=List2Detections(t,DetList)
	% Detections=List2Detections(t,DetList)

Detections=0*t;

if sum(DetList(:))>0
  for i=1:size(DetList,1)
    nD=find(t>=DetList(i,1) & t<=DetList(i,2));
    Detections(nD)=1;
  end
end
