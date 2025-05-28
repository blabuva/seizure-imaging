function [dff] = pixelFilter(mtx,Fs,Fc)
%% pixelFilter Caclulates change in fluorescence 

% INPUTS:
%   mtx - data matrix. 1st dimension will be filtered
%   Fs - sampling rate in Hz
%   Fc - cutoff frequency in Hz
%
% OUTPUTS:
%   dff - deltaF/F matrix. Filtered and smoothed output matrix
%
% Written by Scott Kilianski
% Updated 04/07/2025

%% Function body
% Set the sampling rate and cutoff frequency
% Fs = 25; % Sampling rate in Hz
% Fc = .1; % Cutoff frequency in Hz

% [b, a] = butter(2, Fc/(Fs/2), 'high');
filtClock = tic;                        % Function clock
[d, c] = butter(2, Fc/(Fs/2), 'low');   % Create the low?? (low-cut or low-pass??) filter
lpmtx = filtfilt(d,c, single(mtx));     % Apply the filter to produce
% twin = 3;
% lpmtx = movmean(double(mtx),twin*Fs,1);
dff = (double(mtx)-lpmtx)./lpmtx;       % subtract the filtered matrix from the original and divide by filtered matrix (output is deltaF/F)
% dff = smoothdata(dff,1,"gaussian",5);   % smooth data temporally with gaussian window

fprintf('Filtering took %.2f seconds\n',toc(filtClock));

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