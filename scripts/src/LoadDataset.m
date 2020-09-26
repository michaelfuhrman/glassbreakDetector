function [t,x,l]=LoadDataset(dataset,varargin);
  numFilesToUse=-1; % By default load all files if set to -1
  append_data=0;
  storageType='data';
  for i=1:length(varargin)
    if ischar(varargin{i})
      if strcmp(varargin{i},'append')
        append_data=1;
      end
      if strcmp(varargin{i},'file')
        storageType='file';
      end
      if strcmp(varargin{i},'data')
        storageType='data';
      end
      if strcmp(varargin{i},'wav')
        storageType='wav';
      end
    else
      % If gave a number, then use it as the number of files to load
      numFilesToUse=varargin{i};
    end
  end

  t=[]; x=[]; l=[];

  if isstruct(dataset)
    jsonFile=dataset;
  else
    %jsonFile=loadjson(dataset);
    jsonFile=json_read(dataset);
  end

  fprintf('Loaded dataset "%s": source "%s"\n',jsonFile.dataset,jsonFile.source);

  numFiles=length(jsonFile.data);
  if numFilesToUse==-1
    numFilesToUse=numFiles; % Use all of the files
  end
  if strcmp(storageType,'data')
    getFileSize=0;
    for i=1:numFilesToUse
      file=collapseVarPath(jsonFile.data(i).file);
      %file=collapseVarPath(jsonFile.data{i}.file);
      %fileInfo=dir(file);
      fileInfo=dir(expandVarPath(expandVarPath(file)));
      getFileSize=getFileSize+ fileInfo.bytes;
      if getFileSize>4e+09
        storageType='file';
        break
      end
    end
  end

  totalSize=0;
  for i=1:numFilesToUse
    file=collapseVarPath(jsonFile.data(i).file);
    %file=collapseVarPath(jsonFile.data{i}.file);
    f=dir(expandVarPath(expandVarPath(file)));
    totalSize=totalSize+f.bytes;

    [~,~,extension]=fileparts(jsonFile.data(i).file);
    %[~,~,extension]=fileparts(jsonFile.data{i}.file);
    switch extension
      case '.wav'
        if ~strcmp(storageType,'wav')
          x_tmp=audioread(expandVarPath(file));
        end
      otherwise
        error('Unknown file extension %s',extension);
    end

    if append_data
      if i==1
        if strcmp(storageType,'wav')
          x=SIGNAL_ARRAY(storageType,file,'x');
          t=SIGNAL_ARRAY(storageType,file,'t');
          lab.file=file;
          if iscell(jsonFile.data(i).label)
            ccc=cat(2,jsonFile.data(i).label{:});
            bbb=reshape(ccc,3,length(ccc)/3)';
            if iscell(bbb)
              lab.label=cell2mat(bbb);
            else
              lab.label=bbb;
            end
          else
            lab.label=jsonFile.data(i).label;
          end
          %lab.label=jsonFile.data{i}.label;
          l=SIGNAL_ARRAY(storageType,lab,'l');
        else
          x=SIGNAL_ARRAY(storageType,x_tmp,'x');
          t_tmp=(0:1/jsonFile.data(i).fs:(length(x_tmp)-1)/jsonFile.data(i).fs)';
          %t_tmp=(0:1/jsonFile.data{i}.fs:(length(x_tmp)-1)/jsonFile.data{i}.fs)';
          if iscell(jsonFile.data(i).label)
            ccc=cat(2,jsonFile.data(i).label{:});
            bbb=reshape(ccc,3,length(ccc)/3)';
            if iscell(bbb)
              label=cell2mat(bbb);
            else
              label=bbb;
            end
            l_tmp=List2Detections(t_tmp,label(:,2:3).*(~label(:,1)==0))';
          else
            l_tmp=List2Detections(t_tmp,jsonFile.data(i).label(:,2:3).*(~jsonFile.data(i).label(:,1)==0))';
          end
          %l_tmp=List2Detections(t_tmp,jsonFile.data{i}.label(:,2:3).*(~jsonFile.data{i}.label(:,1)==0))';
          l=SIGNAL_ARRAY(storageType,l_tmp(:),'l');
        end
      else
        if strcmp(storageType,'wav')
          x = [x file];
          lab.file=file;
          if iscell(jsonFile.data(i).label)
            ccc=cat(2,jsonFile.data(i).label{:});
            bbb=reshape(ccc,3,length(ccc)/3)';
            if iscell(bbb)
              lab.label=cell2mat(bbb);
            else
              lab.label=bbb;
            end
          else
            lab.label=jsonFile.data(i).label;
          end
          %lab.label=jsonFile.data{i}.label;
          l = [l lab];
        else
          x = [x x_tmp];
          t_tmp=(0:1/jsonFile.data(i).fs:(length(x_tmp)-1)/jsonFile.data(i).fs)';
          %t_tmp=(0:1/jsonFile.data{i}.fs:(length(x_tmp)-1)/jsonFile.data{i}.fs)';
          if iscell(jsonFile.data(i).label)
            ccc=cat(2,jsonFile.data(i).label{:});
            bbb=reshape(ccc,3,length(ccc)/3)';
            if iscell(bbb)
              label=cell2mat(bbb);
            else
              label=bbb;
            end
            l_tmp=List2Detections(t_tmp,label(:,2:3).*(~label(:,1)==0))';
          else
            l_tmp=List2Detections(t_tmp,jsonFile.data(i).label(:,2:3).*(~jsonFile.data(i).label(:,1)==0))';
          end
          %l_tmp=List2Detections(t_tmp,jsonFile.data{i}.label(:,2:3).*(~jsonFile.data{i}.label(:,1)==0))';
          l = [l l_tmp(:)];
        end
      end
    else
      if i==1
        if strcmp(storageType,'wav')
          x=SIGNAL_ARRAY(storageType,file,'x');
          t=SIGNAL_ARRAY(storageType,file,'t');
          lab.file=file;
          if iscell(jsonFile.data(i).label)
            ccc=cat(2,jsonFile.data(i).label{:});
            bbb=reshape(ccc,3,length(ccc)/3)';
            if iscell(bbb)
              lab.label=cell2mat(bbb);
              %lab.label=cellfun(@(x) vercat(x),jsonFile.data(i).label);
            else
              lab.label=bbb;
            end
          else
            lab.label=jsonFile.data(i).label;
          end

          %lab.label=jsonFile.data{i}.label;
          l=SIGNAL_ARRAY(storageType,lab,'l');
        else
          x=SIGNAL_ARRAY(storageType,x_tmp,'x');
          t_tmp=(0:1/jsonFile.data(i).fs:(length(x_tmp)-1)/jsonFile.data(i).fs)';
          %t_tmp=(0:1/jsonFile.data{i}.fs:(length(x_tmp)-1)/jsonFile.data{i}.fs)';
          t=SIGNAL_ARRAY(storageType,t_tmp,'t');
          if iscell(jsonFile.data(i).label)
            ccc=cat(2,jsonFile.data(i).label{:});
            bbb=reshape(ccc,3,length(ccc)/3)';
            if iscell(bbb)
              label=cell2mat(bbb);
              %lab.label=cellfun(@(x) vercat(x),jsonFile.data(i).label);
            else
              label=bbb;
            end
            l_tmp=List2Detections(t(i),label(:,2:3).*(~label(:,1)==0))';
          else
            l_tmp=List2Detections(t(i),jsonFile.data(i).label(:,2:3).*(~jsonFile.data(i).label(:,1)==0))';
          end
          %l_tmp=List2Detections(t(i),jsonFile.data{i}.label(:,2:3).*(~jsonFile.data{i}.label(:,1)==0))';
          l=SIGNAL_ARRAY(storageType,l_tmp(:),'l');
        end
      else
        if strcmp(storageType,'wav')
          x = [x file];
          t = [t file];
          lab.file=file;
          if iscell(jsonFile.data(i).label)
            ccc=cat(2,jsonFile.data(i).label{:});
            bbb=reshape(ccc,3,length(ccc)/3)';
            if iscell(bbb)
              lab.label=cell2mat(bbb);
            else
              lab.label=bbb;
            end
          else
            lab.label=jsonFile.data(i).label;
          end
          %lab.label=jsonFile.data{i}.label;
          l = [l lab];
        else
          x = [x x_tmp];
          t_tmp=(0:1/jsonFile.data(i).fs:(length(x_tmp)-1)/jsonFile.data(i).fs)';
          %t_tmp=(0:1/jsonFile.data{i}.fs:(length(x_tmp)-1)/jsonFile.data{i}.fs)';
          t = [t t_tmp];
          if iscell(jsonFile.data(i).label)
            ccc=cat(2,jsonFile.data(i).label{:});
            bbb=reshape(ccc,3,length(ccc)/3)';
            if iscell(bbb)
              label=cell2mat(bbb);
            else
              label=bbb;
            end
            l_tmp=List2Detections(t(i),label(:,2:3).*(~label(:,1)==0))';
          else
            l_tmp=List2Detections(t(i),jsonFile.data(i).label(:,2:3).*(~jsonFile.data(i).label(:,1)==0))';
          end
          %l_tmp=List2Detections(t(i),jsonFile.data{i}.label(:,2:3).*(~jsonFile.data{i}.label(:,1)==0))';
          l = [l l_tmp(:)];
        end
      end
    end
  end

  if append_data

    x = append(x);
    l = append(l);

    t=(0:1/jsonFile.data(i).fs:(length(x)-1)/jsonFile.data(i).fs)';
    %t=(0:1/jsonFile.data{i}.fs:(length(x)-1)/jsonFile.data{i}.fs)';

  end


  if totalSize<1e6
    fprintf('  %d files with a total size of %.02dkB\n',numFilesToUse,totalSize/1e3);
  else
    fprintf('  %d files with a total size of %.02dMB\n',numFiles,totalSize/1e6);
  end
end
