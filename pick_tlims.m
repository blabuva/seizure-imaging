function tlim = pick_tlims(eeg_filename)
%% pick_tlims Pick the time limits of the camera TTL epoch 
%
% INPUTS:
%   eeg_filename: full path to .abf file
%
% OUTPUTS:
%   tlim: a 2-element vector with the start and end of the camera TTL epoch of interest
%
% Written by Scott Kilianski
% Updated 05/28/2025

%% === Function Body === %%
pf = plotEEGandCameraTTL(eeg_filename);
set(pf.Children(1).Title,'String','Click the time limits');
drawnow;
[tlim,~] = ginput(2);
fp = fileparts(eeg_filename);
save(fullfile(fp,'tlim.mat'),'tlim');
end