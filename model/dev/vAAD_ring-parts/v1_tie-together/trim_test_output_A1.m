% Updating this to not use pin A1, since that conflicts with the glass break detector's
% use of pin A3's amplifier

figure(4); subplot(1,1,1);
pos_net = test_array{cur_test}.pos;
neg_net = test_array{cur_test}.neg;

str = sprintf('Testing output %d (%s - %s)...\n', cur_test, pos_net, neg_net);
print_log(str)

out_nets = [];
out_nets{1} = pos_net;
out_nets{2} = neg_net;

% Remove neg net from measurement
if ~isempty(strmatch(neg_net, {'gnd', 'Gnd', 'GND'},'exact'))
  out_nets = out_nets(1);
  neg_sw  = 0;
  neg_hw  = 0;
%elseif ~isempty(strmatch(neg_net, {'mid', 'Mid', 'MID'},'exact'))
%  out_nets = out_nets(1);
%  neg_sw  = 0;
%  neg_hw  = mid;
end


% Run sw netlist
[vadSW,vadHW]=structure_parse(lib,net,[],[],[],out_nets);
ySW=runNetlist(vadSW,sig_test.sig_in,sig_test.Fs);

% Create hardware netlist
netHW=[];
netHW{end+1}=vadHW;
netHW{end+1}=lib.pin.A1('net',out_nets{1}, 'dir','out');
if length(out_nets) == 2
  netHW{end+1}=lib.pin.A3('net',out_nets{2}, 'dir','out');
else
  % netHW{end+1}=lib.pin.A3('net','mid', 'dir','out');
end


% Program design
error_count = 0;
while(error_count < max_error)
  try
    str = evalc('[des, ram] = ramp_compile(netHW,ramp_ic);');
    print_log(str,1);
  catch
    trim_catch_error;
    if do_break;
      break;
    else
      continue;
    end
  end
  break;
end
if error_count >= max_error
  error('Too many failures. Exiting.');
end

% Get hardware results
error_count = 0;
while(error_count < max_error)
  try
    trim_settle(mid);
    yHW=ADaoutIn(sig_test.sig_in+mid,[1:2],sig_test.Fs,sig_test.t(end)) - y_off;
  catch
    trim_catch_error;
    if do_break;
      break;
    else
      continue;
    end
  end
  break;
end
if error_count >= max_error
  error('Too many failures. Exiting.\n');
end

% Extract measured results
pos_hw = yHW(:,1);
pos_sw = ySW(:,1);
if length(out_nets) == 2
  neg_hw = yHW(:,2);
  neg_sw = ySW(:,2);
end
meas_hw = pos_hw - neg_hw;
meas_sw = pos_sw - neg_sw;
raw_hw  = meas_hw;
raw_sw  = meas_sw;

% Remove offsets
off_hw = mean(meas_hw(1/2*sig_test.T0*sig_test.Fs:3/4*sig_test.T0*sig_test.Fs));
off_sw = mean(meas_sw(1/2*sig_test.T0*sig_test.Fs:3/4*sig_test.T0*sig_test.Fs));
if max(meas_hw) > 1.75; off_hw = 0; end;
if max(meas_sw) > 1.75; off_sw = 0; end;
meas_hw -= off_hw;
meas_sw -= off_sw;

% plot results
figure(4); subplot(1,1,1);
%plot(sig_test.t, meas_hw, 'color', colors(2,:), sig_test.t, meas_sw, 'color', colors(1,:));
%leg = legend('HW', 'SW');
plot(sig_test.t, meas_sw, sig_test.t, meas_hw);
leg = legend('SW', 'HW');
set(leg,'Interpreter', 'none') % Show underscores
xlabel('Time (s)');
ylabel('Output (V)');
tit = title(sprintf('Test Output %d (%s - %s)', cur_test, pos_net, neg_net));
set(tit,'Interpreter', 'none') % Show underscores

% Save measure values
results.test{cur_test}.t        = sig_test.t;
results.test{cur_test}.ySW      = ySW;
results.test{cur_test}.yHW      = yHW;
results.test{cur_test}.raw_hw   = raw_hw;
results.test{cur_test}.raw_sw   = raw_sw;
results.test{cur_test}.meas_hw  = meas_hw;
results.test{cur_test}.meas_sw  = meas_sw;
results.test{cur_test}.off_hw   = off_hw;
results.test{cur_test}.off_sw   = off_sw;
results.test{cur_test}.out_net  = out_nets;
