function [tout,xout,lout,newJson]=ExtractEventDataset(datasets,pre,post,dBFS,channels,spl_check_time,destination)
	% Extract the events from a dataset such that there's single event instances
	% with pre duration in front and post duration after.
	%
	% [t,x,l]=ExtractEventDataset(datasets,pre,post,destination)
	%  - datasets: can be a string containing the json file for the dataset
	%              or can be a cell array of strings for multiple datsets to combine
	%  - pre: amount of time in seconds to keep in front of each event
	%  - post: amount of time in seconds to keep after each event
	%  - dBFS: Normalize events to this level if it isn't []
	%  - channels: Which channels to keep from the file (-1 as argument takes the mean of
	%              the channels)
	%  - spl_check_time: amount of time from event start used to compuse gain
	%    parameter to normalize signal
	%  - destination: destination folder to place the extracted dataset into
	%                 if not given then don't save the dataset to files

	if ~iscell(datasets)
		datasets={datasets};
	end
	if nargin<6
		spl_check_time=-1;
	end
	if nargin<7
		destination=[];
	else
		if ~exist(destination,'dir')
			mkdir(destination);
		end
	end

	%t=[]; x=[]; l=[];
	newData=[];
	source='';
	datasetNames='';

	for d=1:length(datasets)
		%data=loadjson(datasets{d});
		data=json_read(datasets{d});
		source=sprintf('%s : %s',source,data.source);
		datasetNames=sprintf('%s : %s',datasetNames,data.dataset);
		[tl,xl,ll]=LoadDataset(datasets{d},'wav');
		% Pull out each event
		for f=1:length(tl)
			%disp(f)
			if iscell(data.data(f).label)
				ccc=cat(2,data.data(f).label{:});
				bbb=reshape(ccc,3,length(ccc)/3)';
				if iscell(bbb)
					labels=cell2mat(bbb);
				else
					labels=bbb;
				end
			else
				labels=data.data(f).label;
			end
			%labels=data.data{f}.label;
			tlf=tl{f};
			xlf=xl{f};
			llf=ll{f};
			% Pad the file if not long enough for the pre/post
			if labels(1,2)<pre
				addedSamples = round( data.data(f).fs*(pre-labels(1,2)) );
				xlf=[zeros(addedSamples,1); xlf];
				llf=[zeros(addedSamples,1); llf];
				tlf=(0:(length(xlf)-1))/data.data(f).fs;
				labels(:,2)=labels(:,2)+(pre-labels(1,2));
				labels(:,3)=labels(:,3)+(pre-labels(1,2));
			end
			for e=1:size(labels,1)
				nD=find(tlf>=labels(e,2)-pre & tlf<=labels(e,3)+post);
				%t{end+1}=tlf(nD)-min(tlf(nD));
				t=tlf(nD)-min(tlf(nD));
				if isempty(dBFS)
					%x{end+1}=xlf(nD,channels);
					if channels==-1
						x_tmp=mean(xlf,2);
						x=x_tmp(nD);
					else
						x=xlf(nD,channels);
					end
				else
					% Normalize
					if spl_check_time<=0
						nDnorm=find(tlf>=labels(e,2) & tlf<=labels(e,3));
					else
						nDnorm=find(tlf>=labels(e,2) & tlf<=(labels(e,2)+spl_check_time));
					end
					if channels==-1
						x_tmp=mean(xlf,2);
						rms=std(x_tmp(nDnorm,1));
						dBFSevent=20*log10(rms);
						gain=10.^((dBFS-dBFSevent)/20);
						%x{end+1}=xlf(nD,channels)*gain';
						x=x_tmp(nD,1)*gain';
					else
						rms=std(xlf(nDnorm,channels));
						dBFSevent=20*log10(rms);
						gain=10.^((dBFS-dBFSevent)/20);
						%x{end+1}=xlf(nD,channels)*gain';
						x=xlf(nD,channels)*gain';
					end
				end
				%l{end+1}=llf(nD);
				l=llf(nD);
				if f==1
					tout=SIGNAL_ARRAY('data',t,'tout');
					xout=SIGNAL_ARRAY('data',x,'xout');
					lout=SIGNAL_ARRAY('data',l,'lout');
				else
					tout = [tout t];
					xout = [xout x];
					lout = [lout l];
				end
				if ischar(destination)
					%newLabels=Detection2List(t{end},l{end});
					newLabels=Detection2List(t,l);
					if isempty(newLabels)
						%newLabels=[0,(length(l{end})-1)/data.data{f}.fs];
						newLabels=[0,(length(l)-1)/data.data(f).fs];
						%newLabels=[0,(length(l)-1)/data.data{f}.fs];
					end
					[~,fname,fext]=fileparts(data.data(f).file);
					%[~,fname,fext]=fileparts(data.data{f}.file);
					file=sprintf('%s/%s_%03d%s',destination,fname,e-1,fext);
					newData{end+1}=struct('label',[labels(e,1) newLabels], ...
																'fs',data.data(f).fs, ... % {f} -> (f)
																'extra',data.data(f).extra, ... % {f} -> (f)
																'file', collapseVarPath(file) ...
															 );
					%audiowrite(file,x{end},data.data{f}.fs);
					audiowrite(file,x,data.data(f).fs); % {f} -> (f)
				end
			end
		end
	end

	newJson=struct('source', source, ...
								 'dataset', sprintf('Events%s',datasetNames), ...
								 'data',[]);
	newJson.data=newData;
	if ischar(destination)
		jsonfile=sprintf('%s/dataset.json',destination);
		savejson('',newJson,jsonfile);
	end

