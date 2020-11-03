% Also extract levels for the speech segments for comparison

dataset   = 'vitron_tester.json';
[t, x, l] = LoadDataset(dataset);
ds        = loadjson(dataset);

%% Ring Loudness estimation for vitron recording + our rms extraction
loudness = []; startWindow=.2;

for f = 1:length(x)
	temp_x = x{f};
	temp_t = t{f};
	temp_l = l{f};
	Fs     = 1 / (temp_t(2) - temp_t(1));

	speech_indices   = find(temp_t>3 & temp_t<9);   % Roughly where the speech occurs, exact timing will only effect by few dB
	glassbreak_times = ds.data{f}.label(:,2:3);
	loudness.sensitivity(f) = ds.data{f}.extra.sensitivity;
	loudness.distance(f)    = ds.data{f}.extra.distance;

	% Speech
	loudness.speech.rms_full(f) = 20*log10( std( temp_x(speech_indices, 2) ) );
	loudness.speech.peak(f)     = 20*log10( max( temp_x(speech_indices, 2) ) / sqrt(2) );
	loudness.speech.ring(f)     = 20*log10( max( loudness_estimation(0.1, 0.01, temp_x(speech_indices, 2), Fs) ) / sqrt(2) );

	% Glassbreak
	for d = 1 %:size(glassbreak_times, 1)
		indices_on_seconds = find( temp_t > floor(glassbreak_times(d,1)) ...
														&  temp_t < ceil(glassbreak_times(d,2))  );

		loudness.glassbreak.ring(f, d) = 20*log10( max( loudness_estimation(0.1, 0.01, temp_x(indices_on_seconds, 2), Fs) ) / sqrt(2) );

		indices_on_label                   = find(temp_t > glassbreak_times(d, 1) & temp_t < glassbreak_times(d, 2));
		loudness.glassbreak.peak(f, d)     = 20*log10( max(temp_x(indices_on_label, 2)) / sqrt(2) );
		loudness.glassbreak.rms_full(f, d) = 20*log10( std(temp_x(indices_on_label, 2)) );

		indices_on_start_window               = find(temp_t > glassbreak_times(d,1) ...
																               & temp_t < (glassbreak_times(d,1) + startWindow));
		loudness.glassbreak.rms_window(f, d) = 20*log10( std(temp_x(indices_on_start_window, 2)) );
	end
end

% Sort by distance
distance = unique(loudness.distance);
speech = []; glassbreak = [];
for d = 1:length(distance)
	this = find(loudness.distance == distance(d));
	speech.ring(d)           = median(94 - loudness.sensitivity(this) + loudness.speech.ring(this));
	speech.peak(d)           = median(94 - loudness.sensitivity(this) + loudness.speech.peak(this));
	speech.rms_full(d)       = median(94 - loudness.sensitivity(this) + loudness.speech.rms_full(this));
	glassbreak.ring(d)       = median(94 - loudness.sensitivity(this) + transpose(loudness.glassbreak.ring(this)));
	glassbreak.peak(d)       = median(94 - loudness.sensitivity(this) + transpose(loudness.glassbreak.peak(this)));
	glassbreak.rms_full(d)   = median(94 - loudness.sensitivity(this) + transpose(loudness.glassbreak.rms_full(this)));
	glassbreak.rms_window(d) = median(94 - loudness.sensitivity(this) + transpose(loudness.glassbreak.rms_window(this)));
end

figure(1);
% Glassbreak
rg = plot(distance, glassbreak.ring,     'ro-'); hold on;
ag = plot(distance, glassbreak.rms_window, 'bo-'); hold on;
% Speech
rs = plot(distance, speech.ring,         'rx-'); hold on;
as = plot(distance, speech.rms_full,     'bx-'); hold on;
hold off;

xlabel('Distance (m)'); ylabel('dB SPL');
legend([rg(1), ag(1), rs(1), as(1)], ...
       {'Glassbreak - Ring', 'Glassbreak - Aspinity', 'Speech - Ring', 'Speech - Aspinity'});


figure(2);
% Compare glassbreak and speech
r = plot(distance, glassbreak.ring - speech.ring,         'ro-'); hold on;
a = plot(distance, glassbreak.rms_window - speech.rms_full, 'bo-'); hold on;
hold off;

xlabel('Distance (m)'); ylabel('Glassbreak - Speech (dB)');
legend([r(1), a(1)], ...
       {'Ring', 'Aspinity'});
