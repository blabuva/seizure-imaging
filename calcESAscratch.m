%% Calculating Entire Spiking Activity (ESA)
% Set the sampling rate and cutoff frequency
Fs = EEG.finalFS; % Sampling rate in Hz
% Set the sampling rate and bandpass filter parameters
hp_Fc = 300; % Upper cutoff frequency in Hz
% Set filter coefficients for a Butterworth filter
[b, a] = butter(1, hp_Fc/(Fs/2), 'high');
hp_filtered = filtfilt(b, a, EEG.data);
hp_rectTrace = abs(hp_filtered);

lp_Fc = 12; % Lower cutoff frequency in Hz
[b, a] = butter(1, lp_Fc/(Fs/2), 'low');
% Apply the filter using filtfilt
lp_filtered = filtfilt(b, a, hp_rectTrace);


figure;
ax(1) = subplot(211);
plot(EEG.time,EEG.data,'k')
ax(2) = subplot(212);
plot(EEG.time,lp_filtered,'b');
linkaxes(ax,'x');