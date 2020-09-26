function FR=FR_RAMP_Model(L,f,res)
  % FR=FR_RAMP_Model(L,f,res_struct)
  % Inputs
  %   L - latency
  %   f - False alarm rate (as number of events per second)
  %   res - Results struct from modeling
  % Outputs
  %   FR - False reject rate (in terms of events)

  % Event based false reject
  FRres=1-mean(res.true_pos_detection');

  % False alarms/second
  fres=mean(res.false_pos_event'./res.noise_time');

  % Latency
  la=cell2mat(res.latency);
  Lres=[];
  for i=1:size(la,1)
    la_notnan=la( i,~isnan(la(i,:)) );
    if ~isempty(la_notnan)
      Lres(i)=mean(la_notnan);
    else
      Lres(i)=NaN;
    end
  end

  % Find FR at this L/f combo
  nD=find(Lres<L & fres<f);
  if ~isempty(nD)
    FR=min(FRres(nD));
  else
    FR=1;
  end
end
