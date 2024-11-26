%% Loading data
fpath = 'Z:\Scott\20240125_20+minutes.adicht'; % path to data file
% EEG = abfLoadEEG(fpath,1,1000); % specifically for loading .abf files
EEG = adiLoadEEG(fpath,2,500);
CTX = adiLoadEEG(fpath,1,500);
EMG = adiLoadEEG(fpath,3,500); %EMG signal
%% Setting up data for processing - the 3 variables below are needed for code to run
Fs = EEG.finalFS; % Sampling rate in Hz
time = EEG.time; % time vector (ideally in seconds)
lfp = EEG.data; % voltage data

%% Low band 
lfc = 1; % Lower cutoff frequency in Hz
ufc = 80; % Upper cutoff frequency in Hz

% Set filter coefficients for a Butterworth filter
[b, a] = butter(2, [lfc, ufc]/(Fs/2), 'bandpass'); %2nd order butterworth filter
% Apply the filter using filtfilt
LFPlow = filtfilt(b, a, lfp);

%% High band
lfc = 80; % Lower cutoff frequency in Hz
ufc = 199; % Upper cutoff frequency in Hz

% Set filter coefficients for a Butterworth filter
[b, a] = butter(2, [lfc, ufc]/(Fs/2), 'bandpass'); %2nd order butterworth filter
% Apply the filter using filtfilt
LFPhigh = filtfilt(b, a, lfp);
envSize = 100;
rippEnv = envelope(LFPhigh,envSize);

%% Calculate power in ripple band
fprintf('Calculating spectrogram and bandpower...\n');
specClock = tic;
frange = [20 200];                                            % frequency range used for spectrogram
windw = 0.2; %spectrogram window size (in seconds)
overlap = 0.75; %proportion overlap of windows
[spectrogram,t,f] = MTSpectrogram([time, lfp],...
    'window',windw,'overlap',windw*.75,'range',frange);              % computes the spectrogram
bands = SpectrogramBands(spectrogram,f,'ripples',[80 200]);       % computes power in different bands
z_ripples = zscore(bands.ripples);
z_spec = zscore(spectrogram,0,2);
kernSize = 5;
kern = ones(kernSize,kernSize)./kernSize^2; % generate kernel
conv_spec = conv2(spectrogram,kern);
trimm = (kernSize-1)/2;

%trimming convolved matrix. Is this right!?!?!?!?
conv_spec(1:trimm,:) = [];
conv_spec(:,1:trimm) = [];
conv_spec(end-trimm+1:end,:) = [];
conv_spec(:,end-trimm+1:end) = [];
z_conv_spec = zscore(conv_spec,0,2);
fprintf('Spectrogram took %.2f seconds...\n',toc(specClock));

%% Plotting
figure;
np = 5; % number of plots
cpn = 1; %current plot number
% subplot below
sax(cpn) = subplot(np,1,cpn);
cpn = cpn+1;
plot(time, lfp);
title('Raw')
xticks([]);
% subplot below
sax(cpn) = subplot(np,1,cpn);
cpn = cpn+1;
imagesc(t,f,z_conv_spec);
title('Z-scored Convolved Spectrogram')
set(gca,'YDir','Normal',...
    'CLim',[-1 7]);
colormap(jet)
xticks([]);
% subplot below
sax(cpn) = subplot(np,1,cpn);
cpn = cpn+1;
plot(time, LFPhigh);
hold on
plot(time,rippEnv,'k');
hold off
title('80-200Hz Filtered (''Ripple band'')')
xticks([]);
% subplot below
sax(cpn) = subplot(np,1,cpn);
cpn = cpn+1;
plot(CTX.time, CTX.data);
title('Somatosensory ECoG')
xticks([]);
sax(cpn) = subplot(np,1,cpn);
cpn = cpn+1;
% imagesc(t,f,z_spec);
% title('Z-scored Spectrogram')
plot(EMG.time,EMG.data)
title('EMG Signal')
linkaxes(sax,'x');