% Setup filenames
script_name = 'trim_restore';
more off

% Call setup and calibrate if configured
%setup;
print_log(sprintf('Restoring part %d\n',id));

% New configuration
%   - override calibration
%   - update index array
%   - attempt to restore trims
is_newconfig = 0;

% Set to 1 when hardware is connected
is_hardware  = 0;

% Filename with results
fname_save = sprintf("results/ramp%d/results.mat",id);
printf('Loading %s...\n', fname_save);
load(fname_save)

more off

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Begin resume
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Create initial vad features
print_log(sprintf('Loading values and variables...\n'));

% Recall nn structure if saved
if isfield(results.resume, 'nn')
  nn = results.resume.nn;
else
  nn = [];
end

sig_trim  = results.sig.sig_trim;
sig_test  = results.sig.sig_test;
sig_train = results.sig.sig_train;

% Use post_cal ramp_ic values
run_netGen;
net=net_default;

% Get saved indexes
if is_newconfig
  idx_array = get_index_list(net);
  idx_trim  = 1;
  idx_step  = 1;
  idx_test  = 1;
  trim_list = 1:length(idx_array);
  test_list = 1:length(test_array);

  if exist('trim_info', 'var');     clear trim_info; end
else
  idx_array     = results.resume.idx_array;
  idx_trim      = results.resume.idx_trim;
  trim_list     = results.resume.trim_list;
  idx_step      = results.resume.idx_step;
  idx_test      = results.resume.idx_test;
  test_list     = results.resume.test_list;
  test_array    = results.resume.test_array;
  if isfield(results.resume, 'trim_info')
    trim_info = results.resume.trim_info;
  end
end

% Set current trim values
if isfield(results, 'component')
  for idx_res = 1:length(results.component)
    if ~isempty(results.component{idx_res}) && isfield(results.component{idx_res}, 'trim_info')
      cpnt_idx = idx_array{idx_res};
      results.component{idx_res}.net_idx = cpnt_idx;

      % Get string of component index
      str_idx = sprintf('%d', results.component{idx_res}.net_idx(1));
      for m = 2:length(results.component{idx_res}.net_idx)
        str_idx = sprintf('%s,%d', str_idx, results.component{idx_res}.net_idx(m));
      end

      % Get net structure for current component
      cur_net  = net; net_heir = [];
      for i = 1:length(cpnt_idx)
        net_heir{end+1} = cur_net;
        cur_net = cur_net.sub{cpnt_idx(i)};
      end

      str = sprintf('Loading Component %d Trim (idx %s)\n', idx_res, str_idx);
      print_log(str);

      % Restore Neural Network
      if strcmp(cur_net.name, 'ramp_ann')
        trim_idx = 1;

        % Restore scaling if do_nn_scale is set
        if isfield(results.component{idx_res}.trim_info, 'do_nn_scale') ...
            && results.component{idx_res}.trim_info.do_nn_scale
          layer = 1;
          for idx_in = 1:size(cur_net.hw{layer}.weight,2)
            nethw = cur_net.hw{layer}.in{idx_in};
            i = strmatch('scale', nethw.args.names, 'exact');
            nethw.args.args{i} = results.component{idx_res}.trim_info.tuned_params(trim_idx++);
            cur_net.hw{layer}.in{idx_in} = build_updated_device(nethw);
          end
        end

        % Restore weight trims
        for layer = 1:length(cur_net.hw)
          for idx_in = 1:size(cur_net.hw{layer}.weight,2)
            for idx_out = 1:size(cur_net.hw{layer}.weight,1)
              nethw = cur_net.hw{layer}.weight{idx_out,idx_in};
              i = strmatch('weight', nethw.args.names, 'exact');
              nethw.args.args{i} = results.component{idx_res}.trim_info.tuned_params(trim_idx++);
              cur_net.hw{layer}.weight{idx_out,idx_in} = build_updated_device(nethw);
            end
          end
        end

        % Restore bias trims
        for layer = 1:length(cur_net.hw)
          for idx_out = 1:length(cur_net.hw{layer}.out)
            nethw = cur_net.hw{layer}.out{idx_out};
            i = strmatch('bias', nethw.args.names, 'exact');
            nethw.args.args{i} = results.component{idx_res}.trim_info.tuned_params(trim_idx++);
            cur_net.hw{layer}.out{idx_out} = build_updated_device(nethw);
          end
        end

      % Restore other components (simple)
      else
        nethw = cur_net.hw{1};
        tunableArgs=find(nethw.args.tunable==1);
        for m = 1:length(tunableArgs)
          nethw.args.args{tunableArgs(m)} = results.component{idx_res}.trim_info.tuned_params(m);
        end

        % Build updated object
        cur_net.hw{1} = build_updated_device(nethw);
      end

      % Rebuild net structure with trimmed component
      for i = length(cpnt_idx):-1:1
        net_heir{i}.sub{cpnt_idx(i)} = cur_net;
        cur_net = net_heir{i};
      end
      net = cur_net;
    end
  end
end
