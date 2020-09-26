classdef SIGNAL_ARRAY
  properties
    storageType
    signal
    var_name
  end
  methods
    function obj=SIGNAL_ARRAY(storageType,signal,var_name)
      if strcmp(storageType,'file')
        filename=sprintf('%s/file_%s%d.mat',tempdir,var_name,1);
        save(filename,'signal');
        signal=filename;
      end
      obj.storageType=storageType;
      obj.signal{1}=signal;
      obj.var_name=var_name;
    end

    function y=subsref(obj,args)
      index=args.subs{1};
      y=load(obj,index);
    end

    function obj=subsasgn(obj,index,signal)
      obj.signal{index.subs{1}}=signal;
    end

    function y=load(obj,index)
      switch obj.storageType
        case 'data'
          y=obj.signal{index};
        case 'file'
          ystruct=load(obj.signal{index});
          fn=fieldnames(ystruct);
          y=getfield(ystruct,fn{1});
        case 'wav'
          if obj.var_name=='x'
            y=audioread(expandVarPath(obj.signal{index}));
          elseif obj.var_name=='t'
            [y_tmp,fs]=audioread(expandVarPath(obj.signal{index}));
            y=(0:1/fs:(length(y_tmp)-1)/fs)';
          elseif obj.var_name=='l'
            lab=obj.signal{index};
            [y_tmp,fs]=audioread(expandVarPath(lab.file));
            t=(0:1/fs:(length(y_tmp)-1)/fs)';
            y=List2Detections(t,lab.label(:,2:3).*(~lab.label(:,1)==0))';
            y=y(:);

          else
            y=obj.signal{index};
          end
      end
    end

    function obj=horzcat(obj,signal)
      if strcmp(obj.storageType,'file')
        filename=sprintf('%s/file_%s%d.mat',tempdir,obj.var_name,length(obj.signal)+1);
        save(filename,'signal');
        signal=filename;
      end
      obj.signal{end+1}=signal;
    end

    function y=append(obj)
      y=[];
      for i=1:length(obj.signal)
        y=[y;load(obj,i)];
      end
    end

    function y=length(obj)
      y=length(obj.signal);
    end

  end
end
