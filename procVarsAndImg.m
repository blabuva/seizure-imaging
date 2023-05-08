function ov = procVarsAndImg(varargin)
%% procVarsAndImg Processes all ECoG, behavioral signals (speed, etc.), and imaging data for a recording session
%
% INPUTS:
%
%
% OUTPUTS:
%
%
% Written by Scott Kilianski
% Updated 4/18/2023
%-------------------------------------------------------------------------%
%% ---- Setting parameters and getting files  ---- %%
altFlag = 0; % alternating between blue and violet illumination
firstBlueFrame = 1; % typically one, but sometimes the first frame is violet :(
[fn,fp] = uigetfile({'*.abf;*.mat'}); % UI to select data
[ifn,ifp] = uigetfile('*.imgbin',[],fp);  % UI to select image file (.imgbin)
fprintf('Loading EEG, camera, and movement data (if available)...\n');
[~,~,fext] = fileparts(fn);
if strcmp(fext,'.mat')
    load(fullfile(fp,fn),'d','dt');     % loads .adicht files
elseif strcmp(fext,'.abf')
    [d, si] = abf2load(fullfile(fp,fn));
    dt = si * 10^-6; % convert time interval from microseconds to seconds
else
    error(['File type unrecognized.' ...
        ' Use .mat or .abf files only']);
end
tv = (0:size(d,1)-1)*dt; %create time vector

%% ---- Grab data and reshape it for dF/F calculation ---- %%
fprintf('Loading and processing image series...\n');
imgFile = fullfile(ifp,ifn);
img = imgbinRead(imgFile); % read in the imaging data
drawFig = figure;
imagesc(img.Data.frames(:,:,firstBlueFrame)); % display first frame
title('Draw the boundaries of the cortex','FontSize',20);
colormap(gray);
drawnow

%% Draw mask and apply to image matrix
fprintf('Waiting for user to draw contour around imaging area...\n');
goodShape = 0;
while ~goodShape
    fhShape = drawassisted;            % draw shape
    shInp = input('Are you happy with the shape you drew? 1 to accept. 0 to redraw  ');
    if ~shInp
        delete(fhShape);
    else
        goodShape = 1;
    end
end
fprintf('User is finished drawing\n');
msk = fhShape.createMask;               % create mask from shape
close(drawFig);
crange = find(sum(msk,1),1,'first'):find(sum(msk,1),1,'last');
rrange = find(sum(msk,2),1,'first'):find(sum(msk,2),1,'last');
ysz = numel(rrange);
xsz = numel(crange);
if altFlag
    zsz = size(img.Data.frames,3)/2; % divide by 2 because you only want half (ie the blue frames only)
    trace = reshape(img.Data.frames(rrange,crange,[firstBlueFrame:2:(zsz*2)]), xsz*ysz,zsz)'; % linearize pixels
else
    zsz = size(img.Data.frames,3); % divide by 2 because you only want half (ie the blue frames only)
    trace = reshape(img.Data.frames(rrange,crange,:), xsz*ysz,zsz)'; % linearize pixels
end
msk2 = msk(rrange,crange); % generate mask

%% ---- Apply dF/F function and reshape data back into height x width x frames shape ---- %%
fprintf('Processing the image series to calculate dF over F...\n');
dff = pixelFilter(trace,25,.1);         % filter the traces %%NEED TO ADJUST FILTER SETTINGS HERE!!!!!%%
dff = reshape(dff',ysz,xsz,zsz);        % reshape the imaging matrix back into (height x width x # of frames)

%% ---- Finding frame times ---- %%
% Camera TTLs
x = d(:,2)>3;     % generating TTL trace
frameTimes = tv(diff(x)>0);       % get the frame times (time when there is a rising TTL edge from the camera)
if numel(frameTimes) > size(dff,3)
    frameTimes(size(dff,3)+1:end) = []; % delete excess frame TTLs
end

%% ---- Calculate bulk deltaF/F over time ---- %%
fprintf('Calculating bulk fluorescence signal over time...\n');
bulk_dfTrace = squeeze(sum(dff.*msk2,[1 2]));                         % calculate the summed df/F for each frame

%% ---- Calculate speed vector ---- %%
fprintf('Calculating speed...\n')
binSize = 1; % time bin size (in seconds)
[~, rt] = risetime(d(:,3),tv); %find rise times
binVec = tv(1):binSize:tv(end);
[bv,be] = histcounts(rt,binVec);
bc = be(1:end-1) + mean(diff(be))/2; % bin centers
distK = 0.9576; % distance constant: distance per output of rotary encoder (in cm)
spdVec = (bv*distK)/binSize; % (cm/sec)
smoothWin = 5; %seconds
spd_smoothed = smoothdata(spdVec,"movmean",smoothWin);

%% ---- Split LFP into low and high power bands ---- %%
fprintf('Splitting LFP into low and high power bands...\n')
pb = splitLFPpower([tv' ,d(:,1)]); % lfp

%% ---- Interpolate all signals to synchronize ---- %%
% intTime =
% lfpLow = ;
% lfpHigh = ;

%% ---- Plot ---- %%
figure;
ax(1) = subplot(411);
plot(frameTimes,bulk_dfTrace,'g');
ax(2) = subplot(412);
plot(bc,spd_smoothed,'k');
ax(3) = subplot(413);
plot(pb.time,pb.low,'b');
ax(4) = subplot(414);
plot(pb.time,pb.high,'r');
linkaxes(ax,'x');

%% ---- Store relevant data in structure to be output/saved ---- %%
% ov.fluor.time = bulk_dfTrace;
% ov.fluor.data = frameTimes;
% ov.speed.time = bc;
% ov.speed.data = spd_smoothed;
% ov.lfpPower.time = pb.time;
% ov.lfpPower.high = pb.high;
% ov.lfpPower.low = pb.low;

end % function end
