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
done=0; compSel=0;
while ~done
	fprintf('\n*******************************************************\n')
	fprintf('Which component?\n');
	fprintf('  0) quit\n');
	for i=1:length(results.component)
		net_comp=getDeviceSub(net_default,results.component{i}.net_idx);
		fprintf('  %d) %s\n',i,net_comp.name);
	end
	compSelPre=compSel;
	compSel=input(sprintf('[0-%d (%d)]: ',length(results.component),compSel));
	if isempty(compSel); compSel=compSelPre; end;

	if compSel==0
		done=1;
	else
		% Display info about the component and it's place in the netlist
		fprintf('\n*******************************************************\n')
		net_comp=getDeviceSub(net_default,results.component{compSel}.net_idx);
		fprintf('%s\n',net_comp.name);

		fprintf('  Inputs: ');
		for i=1:length(net_comp.in)
			fprintf('%s, ', net_comp.in{i});
		end
		fprintf('\n');

		fprintf('  Outputs: ');
		for i=1:length(net_comp.out)
			fprintf('%s, ', net_comp.out{i});
		end
		fprintf('\n');

		[net_compSW,net_compHW]=structure_parse(lib,net_comp,[],[],net_comp.in,net_comp.out,0);
		fprintf('  RampSim Netlist:\n');
		for i=1:length(net_compSW)
			fprintf('    %s\n', net_compSW{i});
		end
		fprintf('\n');


		% Display results
		leg_meas=[]; leg_test=[];
		for id_nD=1:length(ids)
			if length(ids)>1
				id=ids(id_nD);
				trim_restore;
			end
			comp_res=results.component{compSel};

			fprintf('  Trim results:\n');
			for i=1:length(comp_res.trim_info.targets)
				fprintf('    Targ = %d, Actual = %d\n',comp_res.trim_info.targets(i), comp_res.trim_info.values(i));
			end
			fprintf('\n');

			% Plots
			downsamp=50;
			nD=sig_trim.T0*sig_trim.Fs:downsamp:length(sig_trim.t);
			% Input and label
			a1=subplot(3,1,1);
			if id_nD==1
				plot(sig_test.t,sig_test.x,sig_test.t,sig_test.lab);
			end
			% Measure
			a2=subplot(3,1,2);
			if isfield(comp_res,'meas')
				if id_nD==1
					plot(comp_res.meas{1}.t(nD),comp_res.meas{1}.meas_sw(nD)); hold on;
					leg_meas{end+1}=sprintf('SW, %dVdc',comp_res.meas{1}.off_sw);
				end
				plot(comp_res.meas{1}.t(nD),comp_res.meas{1}.meas_hw(nD));
				leg_meas{end+1}=sprintf('HW, %dVdc',comp_res.meas{1}.off_hw);
			end
			% Test
			a3=subplot(3,1,3);
			if isfield(comp_res,'test')
				if id_nD==1
					plot(comp_res.test{1}.t(nD),comp_res.test{1}.meas_sw(nD)); hold on;
					leg_test{end+1}=sprintf('SW, %dVdc',comp_res.test{1}.off_sw);
				end
				plot(comp_res.test{1}.t(nD),comp_res.test{1}.meas_hw(nD));
				leg_test{end+1}=sprintf('HW, %dVdc',comp_res.test{1}.off_hw);
			end
			linkaxes([a1,a2,a3],'xy');
		end
		subplot(3,1,2); hold off; legend(leg_meas);
		xlabel('Time (s)'); ylabel('Voltage'); title('Measure (Component only)');
		subplot(3,1,3); hold off; legend(leg_test);
		xlabel('Time (s)'); ylabel('Voltage'); title('Test (With preceding chain)');
	end
end
