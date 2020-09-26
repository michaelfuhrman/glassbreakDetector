load Rampdev_results_structure.mat;

subplot(2,1,1);
plot(mean(res_struct.false_pos_event'./res_struct.noise_time'), ...
 		 mean(res_struct.true_pos_detection'))
xlabel('False alarms per second'); ylabel('Event TPR')

subplot(2,1,2);
la=cell2mat(res_struct.latency);
Latency=[];
for i=1:size(la,1)
	la_notnan=la( i,~isnan(la(i,:)) );
	if ~isempty(la_notnan)
		Latency(i)=mean(la_notnan);
	else
		Latency(i)=NaN;
	end
end
plot(mean(res_struct.false_pos_event'./res_struct.noise_time'), ...
 		 Latency)
xlabel('False alarms per second'); ylabel('Latency (s)')

