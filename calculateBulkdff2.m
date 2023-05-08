function ov = calculateBulkdff2(varargin)
%% calculateBulkdff2 Returns the bulk deltaF/F vector for the entire imaging session
% ***COMPATIBLE FOR USE WITH .ABF FILES***
% INPUTS:
%
%
% OUTPUTS:
%
%
% Written by Scott Kilianski
% Updated 4/10/2023
%-------------------------------------------------------------------------%
%% ----  ---- %%
altFlag = 0; % alternating between blue and violet illumination
firstBlueFrame = 1; % typically one, but sometimes the first frame is violet :(
[fn,fp] = uigetfile('*.abf');        % UI to select prepped data .mat file
[ifn,ifp] = uigetfile('*.imgbin',[],fp);        % UI to select image file (.imgbin)
fprintf('Loading EEG, camera, and movement data (if available)...\n');
[d, si] = abf2load(fullfile(fp,fn));
dt = si * 10^-6; % convert time interval from microseconds to seconds
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

save(sprintf('%s_bulkDF.mat',fullfile(fp,fn)),...
    'bulk_dfTrace','frameTimes','-v7.3');

end % function end
