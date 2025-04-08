function [FT, FS, EEG, tv] = getFrameTimes(eeg_filename,nof)
%% getFrameTimes Retrieves frames times from timeseries with camera TTL input
% Rising TTL edges are taken as frame times
%
% INPUTS:
%   eeg_filename: full path to .abf file
%   nof: number of frames (any extra TTLs are ignored)
%
% OUTPUTS:
%   FT - frame times (in seconds)
%   FS - sampling frequency (Hz)
%
% Written by Scott Kilianski
% Updated 04/07/2025

%% Function body
[EEG,si] = abf2load(eeg_filename);
x = EEG(:,2)>1; % generating TTL trace
rte = diff(x)>0; %rising TTL edges
ri = find(rte,nof,'first'); % indices of rising edges
SI = si * 10e-7; % sampling interval in seconds
FS = 1/(mean(diff(ri))*SI); % the sampling frequency of the camera
FT = ri * SI; 
tv = (0:length(EEG(:,2))-1)*SI;

end % function end