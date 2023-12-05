Fs = EEG.finalFS; % Sampling rate in Hz
time = EEG.time;
lfp = EEG.data;

%% Low band
lfc = 4; % Lower cutoff frequency in Hz
ufc = 10; % Upper cutoff frequency in Hz

% Set filter coefficients for a Butterworth filter
[b, a] = butter(2, [lfc, ufc]/(Fs/2), 'bandpass');
% Apply the filter using filtfilt
LFPlow = filtfilt(b, a, lfp);

%% High band
lfc = 100; % Lower cutoff frequency in Hz
ufc = 500; % Upper cutoff frequency in Hz

% Set filter coefficients for a Butterworth filter
[b, a] = butter(2, [lfc, ufc]/(Fs/2), 'bandpass');
% Apply the filter using filtfilt
LFPhigh = filtfilt(b, a, lfp);

%%
figure;
ax(1) = subplot(311);
plot(time, lfp);
title('Raw')
ax(2) = subplot(312);
plot(time, LFPlow);
title('Low Band Filtered')
ax(3) = subplot(313);
plot(time, LFPhigh);
title('High Band Filtered')
linkaxes(ax,'x');
