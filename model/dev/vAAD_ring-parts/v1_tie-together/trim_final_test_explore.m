% Get parts
compareAll=0;
partsDirs=dir('results');
fprintf('Which part?\n');
for i=3:length(partsDirs)
	fprintf('  %d) %s\n',i-2,partsDirs(i).name);
end
fprintf('  %d) Compare all\n',i-2+1);
partSel=input(sprintf('[1-%d]: ',length(partsDirs)-2))+2;
partsSel=partSel;
if partSel>length(partsDirs)
	compareAll=1; partSel=3; partsSel=3:length(partsDirs);
end
id=[];
for i=1:length(partsSel)
	idCell=regexp(partsDirs(partsSel(i)).name,'ramp([0-9]*)','tokens');
	ids(i)=str2num(idCell{1}{1});
end
ids(ids==999)=[];
id=ids(1);
trim_restore;

% Loop of options
done=0; testSel=0;
while ~done
	fprintf('\n*******************************************************\n')
	fprintf('Which component?\n');
	fprintf('  0) quit\n');
	for i=1:length(results.test)
		fprintf('  %d) %s\n',i,results.test{i}.out_net{1});
	end
	testSelPre=testSel;
	testSel=input(sprintf('[0-%d (%d)]: ',length(results.test),testSel));
	if isempty(testSel); testSel=testSelPre; end;

	if testSel==0
		done=1;
	else
		% Display info about the test
		fprintf('\n*******************************************************\n')
		fprintf('%s\n',results.test{testSel}.out_net{1});


		% Display results
		leg_test=[];
		for id_nD=1:length(ids)
			if length(ids)>1
				id=ids(id_nD);
				trim_restore;
			end
			test_res=results.test{testSel};

			% Plots
			downsamp=50;
			nD=sig_test.T0*sig_test.Fs:downsamp:length(sig_test.t);
			% Input and label
			a1=subplot(2,1,1);
			if id_nD==1
				plot(sig_test.t(nD),sig_test.x(nD),sig_test.t(nD),sig_test.lab(nD));
			end
			% Test
			a2=subplot(2,1,2);
			if id_nD==1
				plot(test_res.t(nD),test_res.meas_sw(nD)); hold on;
				leg_test{end+1}=sprintf('SW, %dVdc',test_res.off_sw);
			end
			plot(test_res.t(nD),test_res.meas_hw(nD));
			leg_test{end+1}=sprintf('HW, %dVdc',test_res.off_hw);
			linkaxes([a1,a2],'x');
		end
		subplot(2,1,2); hold off; legend(leg_test);
		xlabel('Time (s)'); ylabel('Voltage'); title('Measure (Component only)');
	end
end
