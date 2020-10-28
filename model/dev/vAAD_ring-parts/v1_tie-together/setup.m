% Set script name for log file
if ~exist('script_name', 'var')
  script_name='setup';
end

% Set configuration variables
global trim_skip_cal = 0;
global trim_meas_pwr = 0;
global trim_logging  = 1;

% Read ID from RAMP and then load into MCU
ramp_library;
ramp_id = ramp_read_id(lib, ramp_ic);
if ramp_id ~= 0
	a1em_write('ID', ramp_id);
end


% Set paths first time
if ~exist('trim_setup_init', 'var') || trim_setup_init
  % trim_version = '0.6';
  % run([getenv('AspBox') '/engr/sig_proc/Script_Library/Octave/hellbender_trim/' trim_version '/trim_setup']);
	run(sprintf('%s/hellbender_trim/trim_setup.m', fileparts(which('ramp_setup'))));
end

% Run normal setup once paths have been configured
trim_setup;

