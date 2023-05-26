%% Generate 24-hr clock timestamps
clear all; close all; clc

[fn,fp] = uigetfile;
% function generateTimeVector_EEG(fp,fn)

load(fullfile(fp,fn));
dateTimes = datetime(datevec(blocktimes));
recStart = dateTimes(1);
durTimes = duration(dateTimes-dateTimes(1));
tv = []; % time vector
for blocki = 1:length(blocktimes)
    sfs = seconds(durTimes(blocki));                    % convert dtime to seconds-from-recording-start units
    si = 1/tickrate(blocki);                            % sampling interval (in seconds)
    sTime = datastart(blocki):dataend(blocki);          % generate vector with appropriate number of samples
    sTime = sTime-datastart(blocki);                    % make it start from 0
    sTime = (sTime./tickrate(blocki)) + sfs;            % convert to seconds-from-recording start units
    tv = [tv; sTime'];                                  % append to time vector
end
tv = single(tv);  % convert to single precision because double is unnecessary 
filename = sprintf('%stimeData.mat',fp);
%
save(filename','tv','recStart','-v7.3')
% end