function pf = plotEEGandCameraTTL(eeg_filename)
%% plotEEGandCameraTTL Plots the EEG and Camera TTLs 
%
% INPUTS:
%   eeg_filename: full path to .abf file
%
% OUTPUTS:
%   A figure showing the relevant data
%
% Written by Scott Kilianski
% Updated 05/28/2025

%% === Function Body === %%
[EEG,si] = abf2load(eeg_filename);
EEG = [EEG(:,3), EEG(:,1), EEG(:,2)]; % reorder EEG for data collected after April 2025
SI = si * 10e-7; % sampling interval in seconds
tv = ((1:length(EEG))-1)*SI;
pf = figure;
sax(1) = subplot(211);
plot(tv,EEG(:,1),'k');
title('EEG');
sax(2) = subplot(212);
plot(tv,EEG(:,2),'k');
title('Camera TTLs');
xlabel('Time (seconds)');
linkaxes(sax,'x');
end