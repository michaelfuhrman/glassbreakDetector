% Run setup
script_name = 'trim_script';
setup

if ~exist('lib', 'var') || ~exist('ramp_ic', 'var') || ~isfield(ramp_ic, 'test_bench')
  error('Must run "setup" first.');
end

figure(1);
figure(2);
figure(3);
figure(4);

% Begin timer
main_tic = tic();

% Run/Rerun specific routines
do_cal      = 0;  % rerun calibration
do_quickcal = 1;  % quick calibration (no mid/vcg trimming) if 1
do_create   = 0;  % create new features/component
do_trim     = 1;  % trim each feature
do_meas     = 1;  % measure output of each feature in isolation
do_test     = 1;  % test output of each feature in full VAD
do_final    = 1;  % do final output testing
do_resume   = 1;  % resume trimming/testing from last point
do_retrim   = 0;  % attempt to retrim components with unsuccessful trims
do_nn_scale = 0;  % scale nn inputs to match rampsim levels

% Steps for each block being trimmed
eval_steps = {'trim'; 'meas'; 'test'};

colors = lines();
more off

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setup data for test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('results', 'var') || ~do_resume
  results = [];
end

% Call setup and calibrate if configured
setup;
print_log(sprintf('Trimming part %d\n',id));

% Create input signal
if ~exist('sig_trim', 'var') || do_create
  import_audio;
end

% Create features
if ~exist('net', 'var') || ~exist('net_default', 'var') ...
    || isempty(strmatch('sub', fieldnames(net))) || do_create
  % Generate net
  run_netGen;
  check_net(net_default,lib,ramp_ic);
  net=net_default;
  do_create = 1;

  % Run rampsim on netlist
  figure(4);
  [testSW,testHW]=structure_parse(lib,net,[],[],[],[]);
  ySW=runNetlist(testSW,sig_test.sig_in,Fs);
  plot(sig_test.t, ySW, sig_test.t, 2.5*sig_test.lab);
  leg = legend(parse_io(net.out){:}, 'label');
  set(leg,'Interpreter', 'none') % Show underscores
end

% Get index array of all components to be trimmed
if ~exist('idx_array','var') || do_create
  idx_array = get_index_list(net);
end

% Setup test array
if ~exist('test_array', 'var') || do_create
  test_array = [];

  % Get single ended output nets
  for j = 1:length(net.out)
    test_array{end+1} = struct('pos', parse_io(net.out){j}, 'neg', 'gnd');
  end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Trim component
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
max_error = 2;
max_retry = 2;
tolerance = 0.07;

if ~exist('idx_trim', 'var') || ~do_resume || do_retrim || do_create
  idx_trim  = 1;
  idx_step  = 1;
  idx_test  = 1;

  trim_list = 1:length(idx_array);
  test_list = 1:length(test_array);
end

if ~isfield(results,'sig')
  results.sig.sig_trim      = sig_trim;
  results.sig.sig_test      = sig_test;
  results.sig.sig_train     = sig_train;
  results.sig.mid           = mid;
  results.sig.y_off         = y_off;
end

% Save resume information
trim_save_resume;

while(idx_trim <= length(trim_list))
  % Get index of current component in net structure
  cur_trim = trim_list(idx_trim);
  cpnt_idx = idx_array{cur_trim};

  % Determine if we need to retrim this feature
  if do_retrim
    [net, cont] = trim_retrim(net, net_default, cur_trim, cpnt_idx, results);

    % Continue to next component, don't need to retrim
    if cont
      idx_trim++;
      continue;
    end
  end

  % Get string for current component
  str_idx = sprintf('%d', cpnt_idx(1));
  for m = 2:length(cpnt_idx)
    str_idx = sprintf('%s,%d', str_idx, cpnt_idx(m));
  end

  % Print name
  printDeviceName(net,cpnt_idx);

  % Loop through trim and test steps
  while(idx_step <= length(eval_steps))

    % Trim step
    if (do_trim && strcmp(eval_steps{idx_step}, 'trim'))
      trim_step_trim;

    % Measure step
    elseif (do_meas && strcmp(eval_steps{idx_step}, 'meas'))
      trim_step_meas;

    % Test step
    elseif (do_test && strcmp(eval_steps{idx_step}, 'test'))
      trim_step_test;
    end

    % Increment test/trim step for next iteration
    idx_step += 1;

    % Save resume variables
    trim_save_resume;
  end

  idx_trim += 1;
  idx_step  = 1;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Final Test step
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

while(do_final && idx_test <= length(test_list))
  cur_test = test_list(idx_test);
  trim_test_output_A1;

  % Save results with test measurement
  trim_save_resume;

  % Increment test for next iteration
  idx_test += 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% End of script
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

print_log(sprintf('Final Time: %d\n',toc(main_tic)), 1);
