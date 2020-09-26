function [t,y,l]=EvalChainMixData(chain,dataset1_txl,dataset2_txl,gain1,gain2,event_time,no_files,targ_fs,save_directory)
  if nargin==8
    save_directory=[];
  else
    if ~exist(save_directory)
      mkdir(save_directory);
    end
  end

  t1=dataset1_txl.t;
  x1=dataset1_txl.x;
  l1=dataset1_txl.l;
  %jsonFile1 = dataset1_txl.jsonFile;

  t2=dataset2_txl.t;
  x2=dataset2_txl.x;
  l2=dataset2_txl.l;
  %jsonFile2 = dataset2_txl.jsonFile;

  y=[];
  jsonOut=struct('source',sprintf('%s:Aspinity','Mixed files dataset'),'dataset','Mixed files dataset','data',[]);
  rng(10);
  %event_order=randperm(length(t1));
  event_order=mod(randperm(no_files),length(t1))+1;
  rng(5);
  % rng(2);
  %noise_order=randperm(length(t2));
  noise_order=mod(randperm(no_files),length(t2))+1;
  post_time=0.5;

  for i=1:length(event_order)
    bee=t1{event_order(i)};
    fs1=1/(bee(2)-bee(1));

    bee=t2{noise_order(i)};
    fs2=1/(bee(2)-bee(1));

    idx=targ_fs*event_time;
    resamp_x2=resample(x2{noise_order(i)},targ_fs,fs2);
    resamp_x1=resample(x1{event_order(i)},targ_fs,fs1);
    x=resamp_x2*gain2;
    x(idx+1:idx+length(resamp_x1))=x(idx+1:idx+length(resamp_x1))+resamp_x1*gain1;
    resamp_l2=resample(l2{noise_order(i)},targ_fs,fs2);
    resamp_l1=resample(l1{event_order(i)},targ_fs,fs1);
    l_tmp=resamp_l2;
    l_tmp(idx+1:idx+length(resamp_l1))=l_tmp(idx+1:idx+length(resamp_l1))+resamp_l1;
    resamp_t2=resample(t2{noise_order(i)},targ_fs,fs2);
    t_tmp=resamp_t2;
    y_tmp=chain(t_tmp,x);
    downcross=(find(l_tmp(1:end-1) >= 0.5 & l_tmp(2:end) < 0.5))+round(post_time*targ_fs);
    y_tmp=y_tmp(1:downcross);
    l_tmp=l_tmp(1:downcross);
    t_tmp=t_tmp(1:downcross);
    %         x_tmp=x(1:downcross);
    if i==1
      y=SIGNAL_ARRAY('data',y_tmp,'y');
      l=SIGNAL_ARRAY('data',l_tmp,'l');
      t=SIGNAL_ARRAY('data',t_tmp,'t');

    else
      y = [y y_tmp];
      l = [l l_tmp];
      t = [t t_tmp];
    end

    %         if ~isempty(save_directory)
    %             [~,file,ext]=fileparts(jsonFile.data{i}.file);
    %             targetFile=sprintf('%s/%s%s',save_directory,file,ext);
    %             audiowrite(targetFile,y{i},jsonFile.data{i}.fs);
    %             jsonOut.data{i}=struct('label',jsonFile.data{i}.label, 'fs',jsonFile.data{i}.fs, 'extra',[], 'file',targetFile);
    %         end
  end
  %if ~isempty(save_directory)
  %    savejson('',jsonOut,sprintf('%s.json',save_directory));
  %end
end
