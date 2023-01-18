%% Dropped frame check
% [fn, fp] = uigetfile('*.adicht');
fp = uigetdir;
dList = dir(fp);
fn = dList(contains({dList.name},'.adicht')).name;
eeg_filename = fullfile(fp,fn);
EEG = adiLoadEEG(eeg_filename,2,20000);
x = EEG.data>3; % generating TTL trace
rte = diff(x)>0; %rising TTL edges
z = diff(x)<0; %falling TTL edges
yi = find(rte)+1; % indices of rising edges
zi = find(z)+1; % indices of falling edges
figure;
subplot(211);
histogram((zi-yi)/EEG.finalFS*1000); % histogram of difference between rising and falling (estimate of exposure time)
title('Time (in ms) between rising and falling edges (exposure time)');
subplot(212);
histogram(diff(yi)/EEG.finalFS*1000); % histogram of intervals between rising edges (inter-frame interval)
title('Time (in ms) between rising edges (inter-frame interval)')
xlabel('Time (milliseconds)')

%%
% [fn,fp] = uigetfile('*.dcimg');
fn = dList(contains({dList.name},'.dcimg')).name;
dcimg_filename = fullfile(fp,fn);
hdcimg = dcimgmex('open',dcimg_filename);                     % open the original .dcimg file
nof = dcimgmex('getparam',hdcimg,'NUMBEROF_FRAME');     % retrieve the total number of frames in the session
dcimgmex('close',hdcimg);

ndf = sum(rte) - nof; %number of dropped frames (# rising TTL edges minus number of frames)
if ndf %if number of dropped frames isn't 0, find where the frames were else
    fprintf('%d dropped frames. Identifying times of dropped frames...\n',ndf);
    %%% HERE'S WHERE I HAVE TO CHECK THE INTER-FRAME INTERVALS %%%
else
    fprintf('No dropped frames! Woohoooo!\n');
end

%% Account for dropped frames
% fprintf('Assigning times to frames...\n');
% fprintf('Frames are now accurately timestamped.\n')