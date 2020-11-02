clear
close all
clc
dataset='vitron_tester.json';
[t,x,l]=LoadDataset(dataset);
ds=loadjson(dataset);


%% Ring Loudness estimation for vitron recording + our rms extraction

rmsFull=[]; rmsWindow=[]; peak=[]; startWindow=.2; sensitivity=[]; distance=[];
for f=1:length(x)
	times=ds.data{f}.label(:,2:3);
    sensitivity(f)=ds.data{f}.extra.sensitivity;
	distance(f)=ds.data{f}.extra.distance;
	for d=1:size(times,1)
		nD=find(t{f}>floor(times(d,1)) & t{f}<ceil(times(d,2)));
        temp_x=x{f};
        temp_t=t{f};
        temp_l=l{f};
        Fs=1/(temp_t(2)-temp_t(1));
        avg_peak=loudness_estimation(0.1,0.01,temp_x(nD,2),Fs);
        highest_avg(f,d)=max(avg_peak);
        
        nD=find(t{f}>times(d,1) & t{f}<times(d,2));
		peak(f,d)=max(temp_x(nD,2));
		rmsFull(f,d)=std(temp_x(nD,2));
		nD=find(temp_t>times(d,1) & temp_t<times(d,1)+startWindow);
		rmsWindow(f,d)=std(temp_x(nD,2));
        
		% pause(.01);
	end
end

dBSPLfull=20*log10(rmsFull);
dBSPLwindow=20*log10(rmsWindow);
dBSPLloudness=20*log10(highest_avg);
dBSPLpeak=20*log10(peak);
% plot(distance,dBSPLfull-sensitivity'+94,'o',distance,dBSPLwindow-sensitivity'+94,'x',distance,dBSPLloudness-sensitivity'+94,'*')
l1=plot(distance,dBSPLfull-sensitivity'+94,'bo');
hold on,l2=plot(distance,dBSPLwindow-sensitivity'+94,'rx');
hold on,l3=plot(distance,dBSPLloudness-sensitivity'+94,'g*');
hold on,l4=plot(distance,dBSPLpeak-sensitivity'+94,'k+');

xlabel('Distance (m)'); ylabel('dB SPL');
legend([l1(1),l2(1),l3(1),l4(1)],{'RMS over full label','RMS over 200ms window in label','Ring loudness estimation','Peak over full label'})
