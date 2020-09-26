function [t,y,l]=EvalChainSet(chain,dataset_txl,gain,save_directory)
  if nargin==3
    save_directory=[];
  else
    if ~exist(save_directory)
      mkdir(save_directory);
    end
  end

  %jsonFile=loadjson(dataset);
  %[t,x,l]=LoadDataset(dataset);
  t=dataset_txl.t;
  x=dataset_txl.x;
  l=dataset_txl.l;
  jsonFile = dataset_txl.jsonFile;
  y=[];
  jsonOut=struct('source',sprintf('%s:Aspinity',jsonFile.source),'dataset',sprintf('%s:Processed',jsonFile.dataset),'data',[]);
  for i=1:length(t)
    y_tmp=chain(t{i},x{i}*gain);
    if i==1
      y=SIGNAL_ARRAY('data',y_tmp,'y');
    else
      y = [y y_tmp];
    end

    if ~isempty(save_directory)
      [~,file,ext]=fileparts(jsonFile.data(i).file);
      %[~,file,ext]=fileparts(jsonFile.data{i}.file);
      targetFile=sprintf('%s/%s%s',save_directory,file,ext);
      audiowrite(targetFile,y{i},jsonFile.data(i).fs);
      %audiowrite(targetFile,y{i},jsonFile.data{i}.fs);
      if iscell(jsonFile.data(i).label)
        ccc=cat(2,jsonFile.data(i).label{:});
        bbb=reshape(ccc,3,length(ccc)/3)';
        if iscell(bbb)
          label=cell2mat(bbb);
        else
          label=bbb;
        end
      else
        label=jsonFile.data(i).label;
      end
      jsonOut.data{i}=struct('label',label, 'fs',jsonFile.data(i).fs, 'extra',[], 'file',targetFile);
      %jsonOut.data{i}=struct('label',jsonFile.data{i}.label, 'fs',jsonFile.data{i}.fs, 'extra',[], 'file',targetFile);
    end
  end
  if ~isempty(save_directory)
    savejson('',jsonOut,sprintf('%s.json',save_directory));
  end
end
