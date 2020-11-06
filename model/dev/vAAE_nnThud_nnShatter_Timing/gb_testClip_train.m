function [nn, event_index, noise_index] = gb_testClip_train(t,y,l,acceptableLatency,gap,iterations)
	% nn=gb_testClip_train(t,y,l,acceptableLatency)
	%
    % Original code except it returns the indices of the training wav file.
    % The indices were returned for use in alternatives to the training
    % method nnModelCreate

	%% Extract feature vector
    % Non-events are wherever the label is 0
    noise_index=find(l==0);
    % Events are wherever the label is higher for less than the acceptable latency time
    labels=Detection2List(t,l);
    labels_acceptable=[labels(:,1)+gap min(labels(:,2),labels(:,1)+acceptableLatency)];
    l_acceptable=List2Detections(t,labels_acceptable);
    event_index=find(l_acceptable==1);
    
    % Unused optional code fo training on peaks such as thuds occurring in
    % the wav file
    if 0 %gap == 0
        % Try to get just peaks
        [Pks,Locs]= findpeaks(y(:,4),'MinPeakProminence',.0001); %max(y(:,4))/8);
        Locs = unique(sort([Locs;Locs-1;Locs-2;Locs+1;Locs+2;Locs+3;Locs+4]));
        
        event_index = intersect(event_index,Locs);
        event_index = event_index';
        %     foo = 0*t;
        %     foo(event_index)=1;
        %     figure;plot(t(event_index),l_acceptable(event_index))
    end
    
    if 0 %gap > 0
        % Try to get just peaks
        [Pks,Locs]= findpeaks(y(:,4),'MinPeakProminence',.000001); %max(y(:,4))/8);
        noise_index = setxor(noise_index,Locs);
        Locs = sort([Locs;Locs+1;Locs-1]);
        
        % Remove peaks
        noise_index = noise_index';
        %     foo = 0*t;
        %     foo(event_index)=1;
        %     figure;plot(t(event_index),l_acceptable(event_index))
    end

    % Intend to keep all the thud data; cutting the background data down by
    % a factor of 10? This was in Brandon's original code.
    noise_index=noise_index(1:10:end);
    %noise_index=noise_index(1:20:end);
    X=y([event_index noise_index],:);
    Y=[ones(size(event_index)) zeros(size(noise_index))]';
           
    % Clean the training data by applying thresholds    
    
    % A subset of the data for training
    if 1 %gap > 0
        X=X(1:20:end,:);
        Y=Y(1:20:end);
        
        event_index = event_index(1:20:end);
        noise_index = noise_index(1:20:end);
    end
    
	% Train
	rate=.6;
    hiddenLayers=[8 8];
	nn=nnModelCreate(X,Y,rate,iterations,hiddenLayers);
    
return

