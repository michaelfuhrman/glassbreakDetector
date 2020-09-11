function List=Detection2List(t,Detection)

Detection(1)=0;
Detection(end)=0;
transitions=diff(Detection);
tOn=t(transitions>0);
tOff=t(transitions<0);

if size(t,1)<size(t,2)
  List=[tOn' tOff'];
else
  List=[tOn tOff];
end
