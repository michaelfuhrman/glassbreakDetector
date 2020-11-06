function nn=gb_testClip_train_v0(t,y,l,acceptableLatency)
	% nn=gb_testClip_train(t,y,l,acceptableLatency)
	%
    % Brandon's original code
    % It was modified to return the indices of the training wav file which
    % are useful for at least two reasons
    %   1) reproduce results with alternative methods for training
    %   2) determine degree of correlation between labels and tarining data
   

	%% Extract feature vector
	% Non-events are wherever the label is 0
	noise_index=find(l==0);
	% Events are wherever the label is higher for less than the acceptable latency time
	labels=Detection2List(t,l);
	labels_acceptable=[labels(:,1) min(labels(:,2),labels(:,1)+acceptableLatency)];
	l_acceptable=List2Detections(t,labels_acceptable);
	event_index=find(l_acceptable==1);

	noise_index=noise_index(1:10:end);
	X=y([event_index noise_index],:);
	Y=[ones(size(event_index)) zeros(size(noise_index))]';

	X=X(1:20:end,:);
	Y=Y(1:20:end);

	% Train
	rate=.6; iterations=15e3; hiddenLayers=[8 8];
	nn=nnModelCreate(X,Y,rate,iterations,hiddenLayers);

