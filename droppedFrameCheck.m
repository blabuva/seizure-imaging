function ndf = droppedFrameCheck(eeg_filename,dcimg_filename)
%% Dropped frame check
% fp = uigetdir;
% dList = dir(fp);
% fn = dList(contains({dList.name},'.abf')).name;
% eeg_filename = fullfile(fp,fn);
% eeg_filename = 'X:\SI_Data\Sakina Gria x GCaMP_server\20240930\20240930_228_0000.abf';
if ~exist("eeg_filename",'var')
    [fn,fp] = uigetfile('*.abf','Select EEG file');
    eeg_filename = fullfile(fp,fn);
end
if ~exist("dcimg_filename",'var')
    [fn,fp] = uigetfile('*.dcimg','Select DCIMG file');
    dcimg_filename = fullfile(fp,fn);
end
[EEG,si,h] = abf2load(eeg_filename);
x = EEG(:,2)>1; % generating TTL trace
rte = diff(x)>0; %rising TTL edges
z = diff(x)<0; %falling TTL edges
yi = find(rte)+1; % indices of rising edges
zi = find(z)+1; % indices of falling edges
SI = si * 10e-7; % sampling interval in seconds
FS = 1/SI;

%%
if 0
    figure;
    subplot(211);
    histogram((zi-yi)/FS*1000); % histogram of difference between rising and falling (estimate of exposure time)
    title('Time (in ms) between rising and falling edges (exposure time)');
    subplot(212);
    histogram(diff(yi)/FS*1000); % histogram of intervals between rising edges (inter-frame interval)
    title('Time (in ms) between rising edges (inter-frame interval)')
    xlabel('Time (milliseconds)')
end

%%
% fn = dList(contains({dList.name},'.dcimg')).name;
% dcimg_filename = fullfile(fp,fn);
hdcimg = dcimgmex('open',dcimg_filename);                     % open the original .dcimg file
nof = dcimgmex('getparam',hdcimg,'NUMBEROF_FRAME');     % retrieve the total number of frames in the session
dcimgmex('close',hdcimg);

ndf = sum(rte) - nof; %number of dropped frames (# rising TTL edges minus number of frames)
if ndf %if number of dropped frames isn't 0, find where the frames were else
    fprintf('%d dropped frames. Identifying times of dropped frames...\n',ndf);
    figure; histogram(diff(yi)./FS);
else
    fprintf('No dropped frames! Woohoooo!\n');
end

%% Account for dropped frames
% fprintf('Assigning times to frames...\n');
% fprintf('Frames are now accurately timestamped.\n')