function [dff] = pixelFilter(mtx,Fs,Fc)
%% pixelFilter Low-cut filter for imgaging matrix (height x width x frames)

% INPUTS:
%   mtx - data matrix. 3rd dimension is frame
%   Fs - sampling rate in Hz
%   Fc - cutoff frequency in Hz
%
% OUTPUTS:
%   dff - deltaF/F matrix. Filtered and smoothed output matrix
%
% Written by Scott Kilianski
% Updated 8/28/2023

%% Function body
% Set the sampling rate and cutoff frequency
% Fs = 25; % Sampling rate in Hz
% Fc = .1; % Cutoff frequency in Hz

% [b, a] = butter(2, Fc/(Fs/2), 'high');
filtClock = tic;                        % Function clock
[d, c] = butter(2, Fc/(Fs/2), 'low');   % Create the low?? (low-cut or low-pass??) filter
lpmtx = filtfilt(d,c, double(mtx));     % Apply the filter to produce
dff = (double(mtx)-lpmtx)./lpmtx;       % subtract the filtered matrix from the original and divide by filtered matrix (output is deltaF/F)
dff = smoothdata(dff,1,"gaussian",5);   % smooth data temporally with gaussian window

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