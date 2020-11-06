function [tmax,valmax,allLoc]=asyncSamplingMax(x,t,a,d)
  pkmax=PDmodel(t,x,a,d);
  maxLoc=find(diff(pkmax>x)==1);
  pkmin=PDmodel(t,x,d,a);
  minLoc=find(diff(pkmin<x)==1);
  %allLoc=sort([maxLoc; minLoc]);
  allLoc=sort(maxLoc);
  tmax=t(allLoc); valmax=x(allLoc);
end