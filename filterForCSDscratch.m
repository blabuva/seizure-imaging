%%
[fn,fp] = uigetfile('.adicht');
EEG = adiLoadEEG(fullfile(fp,fn),1,10);

%%
[fn,fp] = uigetfile('.abf');
[d, si] = abf2load(fullfile(fp,fn));
dt = si * 10^-6; % convert time interval from microseconds to seconds
dsFactor = 1;
dsInd = 1:dsFactor:size(d,1);
endTime = (size(d,1)-1)*dt;
EEG.finalFS = 1/(dsFactor*dt);
EEG.time = 0:dt:endTime;
EEG.time = EEG.time(dsInd);
EEG.data = d(dsInd,1);
%%
% Load the trace data into a vector, e.g. using the "load" command

% Set the sampling rate and cutoff frequency
Fs = EEG.finalFS; % Sampling rate in Hz
% Set the sampling rate and bandpass filter parameters
Fc2 = 0.5; % Upper cutoff frequency in Hz

Fc1 = 0.001; % Lower cutoff frequency in Hz
% Set filter coefficients for a Butterworth filter
[b, a] = butter(2, [Fc1, Fc2]/(Fs/2), 'bandpass');
% Apply the filter using filtfilt
filtered_trace_1 = filtfilt(b, a, EEG.data);

Fc3 = 0.01;
% Set filter coefficients for a Butterworth filter
[b, a] = butter(2, [Fc3, Fc2]/(Fs/2), 'bandpass');
% Apply the filter using filtfilt
filtered_trace_2 = filtfilt(b, a, EEG.data);

Fc4 = 0.1; % Lower cutoff frequency in Hz
% Set filter coefficients for a Butterworth filter
[b, a] = butter(2, [Fc4, Fc2]/(Fs/2), 'bandpass');
% Apply the filter using filtfilt
filtered_trace_3 = filtfilt(b, a, EEG.data);


% Plot the original and filtered traces
figure;
ax(1) = subplot(4,1,1);
plot(EEG.time,EEG.data);
title('Original trace - 1st Recording');
ax(2) = subplot(4,1,2);
plot(EEG.time,filtered_trace_1);
title(sprintf(['Bandpass filtered' ...
    '  trace:  %.3f  to  %.1fHz'],Fc1,Fc2));
ax(3) = subplot(4,1,3);
plot(EEG.time,filtered_trace_2);
title(sprintf(['Bandpass filtered' ...
    '  trace:  %.3f  to  %.1fHz'],Fc3,Fc2));
ax(4) = subplot(4,1,4);
plot(EEG.time,filtered_trace_3);
title(sprintf(['Bandpass filtered' ...
    '  trace:  %.3f  to  %.1fHz'],Fc4,Fc2));

linkaxes(ax,'x');
xlim('tight')

set(gcf().Children,'FontSize',20)