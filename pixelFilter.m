function [dff] = pixelFilter(mtx,Fs,Fc)
%% pixelFilter Temporal filter for imgaging matrix (height x width x frames)

% INPUTS:
%   mtx - data matrix. Each row 
%   Fs - sampling rate in Hz
%   Fc - cutoff frequency in Hz
%
% OUTPUTS:
%   fitted_y - y data returned from the the best fit function (same length as 'y' input )
%
% Written by Scott Kilianski
% Updated 3/17/2023

%% Function body
% Set the sampling rate and cutoff frequency
% Fs = 25; % Sampling rate in Hz
% Fc = .1; % Cutoff frequency in Hz

% Set filter coefficients for a Butterworth filter
% [b, a] = butter(2, Fc/(Fs/2), 'high');
filtClock = tic;

[d, c] = butter(2, Fc/(Fs/2), 'low');

% Apply the filter using filtfilt
% hpy= filtfilt(b, a, y);
lpmtx = filtfilt(d,c, double(mtx));

%
dff = (double(mtx)-lpmtx)./lpmtx;
fprintf('Filtering took %.2f seconds\n',toc(filtClock));

% Smooth the output
dff = smoothdata(dff,1,"gaussian",5);   % smooth data temporally with guassian window
fprintf('Filtering and smoothing took %.2f seconds\n',toc(filtClock));

%% Plotting optional
% figure; 
% subplot(311);
% plot(x,y,'k');
% title('Raw Pixel Intensity over Time');
% subplot(312);
% plot(x,lpy,'k');
% title('Low-pass Filtered');
% subplot(313);
% plot(x,hpy,'k');
% title('High-pass Filtered');

end % function end