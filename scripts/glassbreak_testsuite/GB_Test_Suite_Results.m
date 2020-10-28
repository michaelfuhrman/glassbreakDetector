function table_data = GB_Test_Suite_Results(res,res_plot,res_table,success_thresholds)
  if nargin<4
    success_thresholds=[];
  end
  if res_table==0
    tab=[];
    table_data=[];
  end
  % Evaluate the output of GB_Test_Suite to generate plots and system analysis
  % GB_Test_Suite_Results(res)
  thresh=res.settings.thresh;
  overhang=res.settings.overhang;

  %% Group to get overall performance over tests
  summary=[];
  summary.thresh=thresh; summary.overhang=overhang; summary.fr=[]; summary.latencyMax=[]; summary.latencyMean=[]; summary.fa_per_s=[];
  % Input will be keyed off of latency and FAR
  % Go through detection tests to get overall FR and latency
  for to=1:length(thresh)
    fr=[]; latencyMax=[]; latencyMean=[];
    tests={'eventSPL','snrSPL'};
    for testNum=1:length(tests)
      thisTest=getfield(res,tests{testNum});
      nD=find(thisTest.thresh'==thresh(to) & thisTest.overhang(:,1)==overhang(to,1) & thisTest.overhang(:,2)==overhang(to,2));
      fr(testNum)=1-mean(mean(thisTest.detect(nD,:)'));

      latencyTemp=[];
      for l=1:length(nD)
        detectedFiles=find(thisTest.detect(nD(l),:)==1);
        if ~isempty(detectedFiles)
          latencyTemp=[latencyTemp thisTest.latency(nD(l),detectedFiles)];
        end
      end
      if ~isempty(latencyTemp)
        latencyMean(testNum)=mean(latencyTemp);
        latencyMax(testNum)=max(latencyTemp);
      else
        latencyMean(testNum)=NaN;
        latencyMax(testNum)=NaN;
      end
    end
    summary.fr(to)=mean(fr);

    nD=find(~isnan(latencyMax));
    if isempty(nD)
      summary.latencyMax(to)=NaN;
    else
      summary.latencyMax(to)=max(latencyMax(nD));
    end

    nD=find(~isnan(latencyMean));
    if isempty(nD)
      summary.latencyMean(to)=NaN;
    else
      summary.latencyMean(to)=mean(latencyMean(nD));
    end
  end

  % Go through far test to get FA per s
  for to=1:length(thresh)
    fa_per_s=[];
    tests={'powerFAR'};
    for testNum=1:length(tests)
      thisTest=getfield(res,tests{testNum});
      nD=find(thisTest.thresh'==thresh(to) & thisTest.overhang(:,1)==overhang(to,1) & thisTest.overhang(:,2)==overhang(to,2));
      %fa_per_s(testNum)=sum(thisTest.false_trig(nD))/sum(thisTest.noise_time(nD));
      fa_per_s(testNum)=sum(thisTest.false_on_time(nD));
    end
    summary.fa_per_s(to)=mean(fa_per_s);
  end

  % Go through all and get total FAR time
  for to=1:length(thresh)
    fa_per_s_all=[];
    tests={'eventSPL','interfererSPL','snrSPL','powerFAR'};
    for testNum=1:length(tests)
      thisTest=getfield(res,tests{testNum});
      nD=find(thisTest.thresh'==thresh(to) & thisTest.overhang(:,1)==overhang(to,1) & thisTest.overhang(:,2)==overhang(to,2));
      % fa_per_s_all(testNum)=sum(thisTest.false_trig(nD))/sum(thisTest.noise_time(nD));
      fa_per_s_all(testNum)=sum(thisTest.false_on_time(nD));
    end
    summary.fa_per_s_all(to)=mean(fa_per_s_all);
  end

  res=setfield(res,'summary',summary);


  %% Decide which to plot
  fom=res.summary.fr*100+res.summary.fa_per_s_all/10;
  [~,fomSort]=sort(fom);
  numToConsider=1;
  fomNd=fomSort(1:numToConsider);


  %% Plots for SPL sweep
  tpr=mean(res.eventSPL.detect(:,1:end)');
  spl=res.eventSPL.spl;
  for i=1:length(fomNd)
    nD=find(res.eventSPL.thresh'==thresh(fomNd(i)) & res.eventSPL.overhang(:,1)==overhang(fomNd(i),1) & res.eventSPL.overhang(:,2)==overhang(fomNd(i),2));
    latencyMean=[]; latencyMax=[];
    for l=1:length(nD)
      detectedFiles=find(res.eventSPL.detect(nD(l),:)==1);
      if ~isempty(detectedFiles)
        latencyMean(l)=mean(res.eventSPL.latency(nD(l),detectedFiles));
        latencyMax(l)=max(res.eventSPL.latency(nD(l),detectedFiles));
      else
        latencyMean(l)=NaN;
        latencyMax(l)=NaN;
      end
    end
    spl_sweep_save{i}.spl=spl(nD);
    spl_sweep_save{i}.tpr=tpr(nD)*100;
    spl_sweep_save{i}.mean_latency=latencyMean;
    spl_sweep_save{i}.max_latency=latencyMax;

  end
  if res_table==1
    figure(1)
    fig = gcf;
    tableData={};
    row_name={};
    cn=1;
    for num=1:length(spl_sweep_save)
      eventDetected=num2cell(spl_sweep_save{num}.tpr);
      if ~isempty(success_thresholds)
        eventRequirement=num2cell(success_thresholds.spl_sweep.eventRequirement);
        tableData(cn,:)=cellfun(@(det,req)sprintf('%c %d',(det>=req)*88,det),eventDetected,eventRequirement,'UniformOutput',false);
      else
        tableData(cn,:)=eventDetected;
      end
      row_name{cn}='Events Detected (%)';
      cn=cn+1;
      latencyDetected=num2cell(spl_sweep_save{num}.mean_latency);
      if ~isempty(success_thresholds)
        latencyRequirement=num2cell(success_thresholds.spl_sweep.latencyRequirement);
        tableData(cn,:)=cellfun(@(det,req)sprintf('%c %d',(det<=req)*88,det),latencyDetected,latencyRequirement,'UniformOutput',false);
      else
        tableData(cn,:)=latencyDetected;
      end
      row_name{cn}='Mean Latency (s)';
      cn=cn+1;
    end
    tab.spl_sweep=uitable('Parent', fig,'Units','Normalized','Position',[0 3/4 1 1/4-0.05],  ...
                          'RowName',row_name, ...
                          'ColumnName',spl_sweep_save{1}.spl, ...
                          'Data',tableData);
    txt = uicontrol( ...
                     'Parent', fig, ...
                     'Style', 'text', ...
                     'String', 'SPL sweep over event dataset', ...
                     'Units', 'Normalized', ...
                     'Position', [0.05 0.95 0.3 0.03] ...
                   );

    table_data.spl_sweep.data=tab.spl_sweep.Data;
    table_data.spl_sweep.rows=tab.spl_sweep.RowName;
    table_data.spl_sweep.columns=cellstr(tab.spl_sweep.ColumnName)';
  end

  %% Plots for interferer sweep
  tpr=mean(res.interfererSPL.detect(:,1:end)');
  spl=res.interfererSPL.spl;
  for i=1:length(fomNd)
    nD=find(res.interfererSPL.thresh'==thresh(fomNd(i)) & res.interfererSPL.overhang(:,1)==overhang(fomNd(i),1) & res.interfererSPL.overhang(:,2)==overhang(fomNd(i),2));
    latencyMean=[]; latencyMax=[];
    for l=1:length(nD)
      detectedFiles=find(res.interfererSPL.detect(nD(l),:)==1);
      if ~isempty(detectedFiles)
        latencyMean(l)=mean(res.interfererSPL.latency(nD(l),detectedFiles));
        latencyMax(l)=max(res.interfererSPL.latency(nD(l),detectedFiles));
      else
        latencyMean(l)=NaN;
        latencyMax(l)=NaN;
      end
    end
    spl_sweep_save{i}.interferer_spl=spl(nD);
    spl_sweep_save{i}.interferer_fpr=tpr(nD)*100;
    spl_sweep_save{i}.interferer_mean_latency=latencyMean;
    spl_sweep_save{i}.interferer_max_latency=latencyMax;
  end

  if res_table==1
    tableData={};
    row_name={};
    cn=1;
    for num=1:length(spl_sweep_save)
      eventDetected=num2cell(spl_sweep_save{num}.interferer_fpr);
      if ~isempty(success_thresholds)
        eventRequirement=num2cell(success_thresholds.spl_sweep.interfererRequirement);
        tableData(cn,:)=cellfun(@(det,req)sprintf('%c %d',(det<=req)*88,det),eventDetected,eventRequirement,'UniformOutput',false);
      else
        tableData(cn,:)=eventDetected;
      end
      row_name{cn}='Interferers Detected (%)';
      cn=cn+1;
      latencyDetected=num2cell(spl_sweep_save{num}.interferer_mean_latency);
      if ~isempty(success_thresholds)
        latencyRequirement=num2cell(success_thresholds.spl_sweep.interferer_latencyRequirement);
        tableData(cn,:)=cellfun(@(det,req)sprintf('%c %d',(det<=req)*88,det),latencyDetected,latencyRequirement,'UniformOutput',false);
      else
        tableData(cn,:)=latencyDetected;
      end
      row_name{cn}='Mean Latency (s)';
      cn=cn+1;
    end
    tab.spl_sweep_interferer=uitable('Parent', fig,'Units','Normalized','Position',[0 2/4 1 1/4],  ...
                                     'RowName',row_name, ...
                                     'ColumnName',spl_sweep_save{1}.interferer_spl, ...
                                     'Data',tableData);
    txt = uicontrol( ...
                     'Parent', fig, ...
                     'Style', 'text', ...
                     'String', 'SPL sweep over interferers dataset', ...
                     'Units', 'Normalized', ...
                     'Position', [0.05 0.75 0.3 0.03] ...
                   );
    table_data.spl_sweep_interferer.data=tab.spl_sweep_interferer.Data;
    table_data.spl_sweep_interferer.rows=tab.spl_sweep_interferer.RowName;
    table_data.spl_sweep_interferer.columns=cellstr(tab.spl_sweep_interferer.ColumnName)';
  end

  %% Plots for event and interferer sweep
  if res_plot==1
    figure(2);
    subplot(2,3,1)
    for num=1:length(spl_sweep_save)
      plot(spl_sweep_save{num}.spl,spl_sweep_save{num}.tpr,'b'); ylim([0 100]); ax(1)=gca; hold on;
      plot(spl_sweep_save{num}.interferer_spl,spl_sweep_save{num}.interferer_fpr,'r'); ylim([0 100]);hold on;
      if ~isempty(success_thresholds)
        index = (spl_sweep_save{num}.tpr >= success_thresholds.spl_sweep.eventRequirement);
        plot(spl_sweep_save{num}.spl(index), spl_sweep_save{num}.tpr(index), 'b*');
        index = (spl_sweep_save{num}.interferer_fpr <= success_thresholds.spl_sweep.interfererRequirement);
        plot(spl_sweep_save{num}.spl(index), spl_sweep_save{num}.interferer_fpr(index), 'r*');
      end
    end
    hold off; xlabel('Event SPL (dB)'); ylabel({'Event TPR (%)';'Interferer FPR (%)'})
    title('Event and Interferer detection ')
    legend('Event','Interferer')
    subplot(2,3,4)
    for num=1:length(spl_sweep_save)
      semilogy(spl_sweep_save{num}.spl,spl_sweep_save{num}.mean_latency,'b'); ax(2)=gca; hold on;
      semilogy(spl_sweep_save{num}.spl,spl_sweep_save{num}.max_latency,'r');hold on;
      if ~isempty(success_thresholds)
        index = (spl_sweep_save{num}.mean_latency <= success_thresholds.spl_sweep.latencyRequirement);
        semilogy(spl_sweep_save{num}.spl(index), spl_sweep_save{num}.mean_latency(index), 'b*');
        index = (spl_sweep_save{num}.max_latency <= success_thresholds.spl_sweep.latencyRequirement);
        semilogy(spl_sweep_save{num}.spl(index), spl_sweep_save{num}.max_latency(index), 'r*');
      end
    end
    hold off; xlabel('Event SPL (dB)'); ylabel('Latency (s)');
    title('Event detection latency')
    legend('Event Mean latency','Event Max latency')
    %     linkaxes(ax,'x')
  end

  %% Plots for snr sweep
  tpr=mean(res.snrSPL.detect(:,1:end)');
  snr=res.snrSPL.snr;
  for i=1:length(fomNd)
    nD=find(res.snrSPL.thresh'==thresh(fomNd(i)) & res.snrSPL.overhang(:,1)==overhang(fomNd(i),1) & res.snrSPL.overhang(:,2)==overhang(fomNd(i),2));
    latencyMean=[]; latencyMax=[];
    for l=1:length(nD)
      detectedFiles=find(res.snrSPL.detect(nD(l),:)==1);
      if ~isempty(detectedFiles)
        latencyMean(l)=mean(res.snrSPL.latency(nD(l),detectedFiles));
        latencyMax(l)=max(res.snrSPL.latency(nD(l),detectedFiles));
      else
        latencyMean(l)=NaN;
        latencyMax(l)=NaN;
      end
    end
    snr_sweep_save{i}.snr=snr(nD);
    snr_sweep_save{i}.tpr=tpr(nD)*100;
    snr_sweep_save{i}.mean_latency=latencyMean;
    snr_sweep_save{i}.max_latency=latencyMax;
  end

  if res_plot==1
    %     figure;
    figure(2)
    subplot(2,3,2)
    for num=1:length(snr_sweep_save)
      plot(snr_sweep_save{num}.snr,snr_sweep_save{num}.tpr,'b'); ylim([0 100]); ax(3)=gca; hold on;
      if ~isempty(success_thresholds)
        index = (snr_sweep_save{num}.tpr >= success_thresholds.snr_sweep.eventRequirement);
        plot(snr_sweep_save{num}.snr(index), snr_sweep_save{num}.tpr(index), 'b*');
      end
    end
    hold off; xlabel('SNR (dB)'); ylabel('TPR (%)');
    title('Mixed dataset detection')
    legend('Mixed Event')
    subplot(2,3,5)
    for num=1:length(snr_sweep_save)
      semilogy(snr_sweep_save{num}.snr,snr_sweep_save{num}.mean_latency,'b'); ax(4)=gca; hold on;
      semilogy(snr_sweep_save{num}.snr,snr_sweep_save{num}.max_latency,'r');hold on;
      if ~isempty(success_thresholds)
        index = (snr_sweep_save{num}.mean_latency <= success_thresholds.snr_sweep.latencyRequirement);
        semilogy(snr_sweep_save{num}.snr(index), snr_sweep_save{num}.mean_latency(index), 'b*');
        index = (snr_sweep_save{num}.max_latency <= success_thresholds.snr_sweep.latencyRequirement);
        semilogy(snr_sweep_save{num}.snr(index), snr_sweep_save{num}.max_latency(index), 'r*');
      end
    end
    hold off; xlabel('SNR (dB)'); ylabel('Latency (s)');
    title('Mixed dataset (event+noise) latency')
    legend('Mean latency','Max latency')
    %     linkaxes(ax,'x')
  end
  if res_table==1
    tableData={};
    row_name={};
    cn=1;
    for num=1:length(snr_sweep_save)
      eventDetected=num2cell(snr_sweep_save{num}.tpr);
      if ~isempty(success_thresholds)
        eventRequirement=num2cell(success_thresholds.snr_sweep.eventRequirement);
        tableData(cn,:)=cellfun(@(det,req)sprintf('%c %d',(det>=req)*88,det),eventDetected,eventRequirement,'UniformOutput',false);
      else
        tableData(cn,:)=eventDetected;
      end
      row_name{cn}='Events Detected (%)';
      cn=cn+1;
      latencyDetected=num2cell(snr_sweep_save{num}.mean_latency);
      if ~isempty(success_thresholds)
        latencyRequirement=num2cell(success_thresholds.snr_sweep.latencyRequirement);
        tableData(cn,:)=cellfun(@(det,req)sprintf('%c %d',(det<=req)*88,det),latencyDetected,latencyRequirement,'UniformOutput',false);
      else
        tableData(cn,:)=latencyDetected;
      end
      row_name{cn}='Mean Latency (s)';
      cn=cn+1;
    end
    tab.snr_sweep=uitable('Parent', fig,'Units','Normalized','Position',[0 1/4 1 1/4],  ...
                          'RowName',row_name, ...
                          'ColumnName',snr_sweep_save{1}.snr, ...
                          'Data',tableData);

    txt = uicontrol( ...
                     'Parent', fig, ...
                     'Style', 'text', ...
                     'String', 'SNR sweep over mixed dataset', ...
                     'Units', 'Normalized', ...
                     'Position', [0.05 0.5 0.3 0.03] ...
                   );

    table_data.snr_sweep.data=tab.snr_sweep.Data;
    table_data.snr_sweep.rows=tab.snr_sweep.RowName;
    table_data.snr_sweep.columns=cellstr(tab.snr_sweep.ColumnName)';
  end

  %% Plots for far sweep
  far=res.powerFAR.false_on_time;
  valid_dur=0.2;%seconds
  fp_count = cellfun(@(x) get_valid_trigger_count(x,valid_dur),res.powerFAR.triggers,'UniformOutput',false);
  total_fp_count=sum(cell2mat(fp_count'));
  for i=1:length(fomNd)
    nD=find(res.powerFAR.thresh'==thresh(fomNd(i)) & res.powerFAR.overhang(:,1)==overhang(fomNd(i),1) & res.powerFAR.overhang(:,2)==overhang(fomNd(i),2));
    far_sweep_save{i}.spl=res.powerFAR.spl(nD);
    far_sweep_save{i}.fon=far(nD);
    far_sweep_save{i}.fcount=total_fp_count(nD);
  end

  if res_plot==1
    %     figure;
    figure(2)
    subplot(2,3,3);
    for num=1:length(spl_sweep_save)
      yyaxis left
      plot(far_sweep_save{num}.spl,far_sweep_save{num}.fon,'b');ax(5)=gca; hold on
      yyaxis right
      plot(far_sweep_save{num}.spl,far_sweep_save{num}.fcount,'r');ax(6)=gca; hold on
      %[hAx,~,~] = plotyy(far_sweep_save{num}.spl,far_sweep_save{num}.fon,far_sweep_save{num}.spl,far_sweep_save{num}.fcount);ax(5)=gca; hold on
      if ~isempty(success_thresholds)
        index1 = (far_sweep_save{num}.fon <=success_thresholds.far_sweep.fonRequirement);
        yyaxis left
        plot(far_sweep_save{num}.spl(index1),far_sweep_save{num}.fon(index1),'b*');
        index2 = (far_sweep_save{num}.fcount <= success_thresholds.far_sweep.fcountRequirement);
        yyaxis right
        plot(far_sweep_save{num}.spl(index2),far_sweep_save{num}.fcount(index2),'r*');

      end
    end
    hold off;xlabel('SPL (dB)')
    title('False positives over background')
    yyaxis left
    ylabel(ax(5),'False positive on time (s)') % left y-axis
    yyaxis right
    ylabel(ax(6),'# False triggers') % right y-axis
  end
  if res_table==1
    tableData={};
    row_name={};
    cn=1;
    for num=1:length(far_sweep_save)
      fpDetected=num2cell(far_sweep_save{num}.fon);
      if ~isempty(success_thresholds)
        fonRequirement=num2cell(success_thresholds.far_sweep.fonRequirement);
        tableData(cn,:)=cellfun(@(det,req)sprintf('%c %d',(det<=req)*88,det),fpDetected,fonRequirement,'UniformOutput',false);
      else
        tableData(cn,:)=fpDetected;
      end
      row_name{cn}='False positives on time (s)';
      cn=cn+1;
      fcountDetected=num2cell(far_sweep_save{num}.fcount);
      if ~isempty(success_thresholds)
        fcountRequirement=num2cell(success_thresholds.far_sweep.fcountRequirement);
        tableData(cn,:)=cellfun(@(det,req)sprintf('%c %d',(det<=req)*88,det),fcountDetected,fcountRequirement,'UniformOutput',false);
      else
        tableData(cn,:)=fcountDetected;
      end
      row_name{cn}='# fp triggers';
      cn=cn+1;
    end

    tab.far_sweep=uitable('Parent', fig,'Units','Normalized','Position',[0 0 1 1/4],  ...
                          'RowName',row_name, ...
                          'ColumnName',far_sweep_save{1}.spl, ...
                          'Data',tableData);

    txt = uicontrol( ...
                     'Parent', fig, ...
                     'Style', 'text', ...
                     'String', 'SPL sweep over background', ...
                     'Units', 'Normalized', ...
                     'Position', [0.05 0.25 0.3 0.03] ...
                   );

    table_data.far_sweep.data=tab.far_sweep.Data;
    table_data.far_sweep.rows=tab.far_sweep.RowName;
    table_data.far_sweep.columns=cellstr(tab.far_sweep.ColumnName)';
  end
end

function count=get_valid_trigger_count(arr,valid_dur)
  count=0;
  if size(arr,1)>0
    for iter=1:size(arr,1)
      if iter>1
        if arr(iter,2)-det_end>valid_dur
          count=count+1;
          det_end=arr(iter,3);
        end
      else
        count=count+1;
        det_end=arr(iter,3);
      end
    end
  end
end
