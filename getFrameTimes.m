function [FT, FS, EEG, tv] = getFrameTimes(eeg_filename,nof,tlim)
%% getFrameTimes Retrieves frames times from timeseries with camera TTL input
% Rising TTL edges are taken as frame times
%
% INPUTS:
%   eeg_filename: full path to .abf file
%   nof: number of frames (any extra TTLs are ignored)
%   tlim: 2-element vector containing time limits (in seconds)
%
% OUTPUTS:
%   FT - frame times (in seconds)
%   FS - sampling frequency (Hz)
%
% Written by Scott Kilianski
% Updated 05/23/2025

%% Function body
ttlThresh = 2; % voltage threshold for detecting TTLs
[EEG,si] = abf2load(eeg_filename);
EEG = [EEG(:,3), EEG(:,1), EEG(:,2)]; % reorder EEG for data collected after April 2025
SI = si * 10e-7; % sampling interval in seconds
tv = (0:length(EEG(:,2))-1)*SI; % time vector
keepLog = tv > tlim(1) & tv < tlim(2); % find all samples within the time limits
TTLtrace = EEG(:,2) .* keepLog'; % changing all samples outside of time limits 
x = TTLtrace>ttlThresh; % generating TTL trace by threhsolding
rte = diff(x)>0; %rising TTL edges
ri = find(rte,nof,'first'); % indices of rising edges
FS = 1/(mean(diff(ri))*SI); % the sampling frequency of the camera
FT = ri * SI; 
fp = fileparts(eeg_filename);
save(fullfile(fp,'ft.mat'),"FT","FS","EEG","tv",'-v7.3');

end % function end