%% Generate 24-hr clock timestamps
clear all; close all; clc

[fn,fp] = uigetfile;                                    % get .adicht file
% function generateTimeVector_EEG(fp,fn)
% blocktimes 
ad = adi.readFile(fullfile(fp,fn));
blocktimes = [ad.records(:).record_start];

% load(fullfile(fp,fn));
dateTimes = datetime(datevec([ad.records(:).record_start]));
recStart = dateTimes(1);
durTimes = duration(dateTimes-dateTimes(1));
tv = []; % time vector
    si = ad.records(1).tick_dt;                         % sampling interval (in seconds)

for blocki = 1:numel(ad.records)
    sfs = seconds(durTimes(blocki));                    % convert dtime to seconds-from-recording-start units
%     sTime = datastart(blocki):dataend(blocki);          % generate vector with appropriate number of samples
%     sTime = sTime-datastart(blocki);                    % make it start from 0
    sTime = (1:ad.records(blocki).n_ticks)-1;
    sTime = sTime./ad.records(blocki).tick_fs + sfs;    % convert to seconds-from-recording start units
    tv = [tv; sTime'];                                  % append to time vector
end
tv = single(tv);  % convert to single precision because double is unnecessary 
filename = sprintf('%stimeData2.mat',fp);
%
save(filename','tv','recStart','-v7.3')
% end