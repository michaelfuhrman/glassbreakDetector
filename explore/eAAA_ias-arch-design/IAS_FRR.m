function FRR=IAS_FRR(res,Latency,f_rollAvg,Sensitivity)
  s=strmatch(Sensitivity,res.Sensitivity);

  % Find closest f_rollAvg
  [~,fn]=min(abs(f_rollAvg-res.f_rollAvg));
  % Find closest latency
  [~,ln]=min(abs(Latency-res.Latency));

  % Return corresponding FRR delta
  TPRatPoint=res.IAS{s}(ln,fn);
  TPRwithout=res.IAS{s}(1,fn);
  FRR=max(TPRwithout-TPRatPoint);
end
