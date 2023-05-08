function make_widefieldMovie(varargin)
%% make_widefieldMovie Makes a movie out of ephys trace and image series
% 
% INPUTS:
%
%
% OUTPUTS:
%
%
% Written by Scott Kilianski
% Updated 4-11-2023
%-------------------------------------------------------------------------%
%% ----  ---- %%
altFlag = 0; % alternating between blue and violet illumination
firstBlueFrame = 1; % typically one
[fn,fp] = uigetfile('*_prepped*.mat');        % UI to select prepped data .mat file
[ifn,ifp] = uigetfile('*.imgbin',[],fp);        % UI to select image file (.imgbin)
fprintf('Loading EEG, camera, and movement data (if available)...\n');
load(fullfile(fp,fn),'ds');

%% ---- Grab data and reshape it for dF/F calculation ---- %%
fprintf('Loading and processing image series...\n');
imgFile = fullfile(ifp,ifn);
img = imgbinRead(imgFile); % read in the imaging data
drawFig = figure; 
imagesc(img.Data.frames(:,:,2)); % display first frame
title('Draw the boundaries of the cortex','FontSize',20);
colormap(gray);
drawnow

%% Draw mask and apply to image matrix
fprintf('Waiting for user to draw contour around imaging area...\n');
goodShape = 0;
while ~goodShape
    fhShape = drawassisted;            % draw shape
    shInp = input('Are you happy with the shape you drew? 1 to accept. 0 to redraw');
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

%% Apply dF/F function and reshape data back into height x width x frames shape
fprintf('Processing the image series to calculate dF over F...\n');

dff = pixelFilter(trace,25,.1);         % filter the traces %%NEED TO ADJUST FILTER SETTINGS HERE!!!!!%%

dff = reshape(dff',ysz,xsz,zsz);        % reshape the imaging matrix back into (height x width x # of frames)
%expDecayFit();

%% ---- Loading camera TTLs and EEG data ---- %%

% Camera TTLs
% fprintf('Loading camera output TTLs...\n');
% load('/media/scottX/SI_Project/20230213/SI_014_20230213_2_ttl.mat','ttl');
x = ds.cam.data>3;     % generating TTL trace
rte = diff(x)>0;    % rising TTL edges
yi = find(rte);     % indices of rising edges

% EEG data
% fprintf('Loading EEG data...\n');
% load('/media/scottX/SI_Project/20230213/SI_014_20230213_2_EEG.mat','EEG');
frameTimes = ds.cam.time(yi);          % get the frame times (time when there is a rising TTL edge from the camera)
frameTimes = frameTimes(2:2:end);   % get every other frame time (corresponds to only blue LED illumation)
windowSize = 10;                    % time window to display ECoG data (in seconds units)
finalEEGfs = 1/(ds.eeg.time(2)-ds.eeg.time(1));
halfWin = windowSize/2*finalEEGfs; % calculate the half-window (in # of EEG sample units)
if numel(frameTimes) > size(dff,3)
    frameTimes(size(dff,3)+1:end) = []; % delete excess frame TTLs
end

%% ---- Initialize figure ---- %%
fprintf('Initializing figure...\n');
ecog_imag_fig = figure;
set(ecog_imag_fig,'Position',[200 1300 1200 1080]);
ecogax = subplot(16,1,1:2);
dfax = subplot(16,1,4:5);
imgax = subplot(16,1,7:16);

% Initialize ECoG plot
frameN = 1;                                 % frame index (1-indexed)
yl = [-8 8];                                % user-defined y limits for ECoG axis (should not be more than +-10)
xl = [-windowSize/2, windowSize/2];         % x limits; determined by the ECoG window size defined earlier
axes(ecogax);
wt = linspace(xl(1),xl(2),halfWin*2+1);     % time vector in ECoG window (relative to current time)
wi = yi(frameN)-halfWin:yi(frameN)+halfWin; % indices into EEG data at camera output TTL rising edges
egLine = plot(ecogax,wt,ds.eeg.data(wi),'k');  % plot first bit of ECoG data
set(ecogax,'YLim',yl,'XLim',xl);            % set xy limits
ecogax.Title.String = 'ECoG';   
ecogax.YLabel.String = 'Volts';

% Initialize image axes
cll = [-0.1 0.1]; % color  limits
axes(imgax);
imgax.Colormap = colormap(redblue);
im = imagesc(dff(:,:,1));    % plot baseline image for anatomical reference
set(imgax, 'box','off','XTickLabel',[],'XTick',[],...
    'YTickLabel',[],'YTick',[]);                                    % remove boxes and ticks
hold on
[bX, bY] = size(im.CData);                                   % get x and y limits of the image
timetxt = text(.9*bX,.10*bY,sprintf('%.2f',frameTimes(1)));         % set the text showing the time of the current frame
set(timetxt,'Color','k','FontSize',24);                             % set the font color and size of that frame time
set(imgax,'CLimMode','manual','CLim',cll);
hold off

%% ---- Calculate bulk deltaF/F over time ---- %%
fprintf('Calculating bulk fluorescence signal over time...\n');
bulk_dfTrace = squeeze(sum(dff.*msk2,[1 2]));                         % calculate the summed df/F for each frame
vidFS = round([numel(frameTimes)/(frameTimes(end)-frameTimes(1))]);  % video sampling frequency (one-color only)
bfTime = linspace(xl(1),xl(2),vidFS*windowSize+1);                   % calculate 
bfHW = floor(vidFS*windowSize/2);               %
padded_bulkdfTrace = [zeros(1,bfHW), bulk_dfTrace',zeros(1,bfHW+1)]; % add zeros and beginning and end of recording
bfk = bfHW+1; % bulk fluorescence index
bfi = bfk-bfHW:bfk+bfHW;
axes(dfax);
bfLine = plot(dfax,bfTime,padded_bulkdfTrace(bfi),'k');              %
set(gcf().Children,'FontSize',20);
set(dfax,'Ylim',[-1000 3000])
set(dfax,'XLim',xl);
dfax.Title.String = 'Bulk Fluorescence';
dfax.YLabel.String = '';

%% ---- Writing to video frame by frame ---- %% 

% Initialize video object
fprintf('Initializing video...\n');
vfn = '/media/scottX/Random/SI_016_20230213_ECoGGCaMPmovie_test.avi';
writerObj  = VideoWriter(vfn);
writerObj.FrameRate = vidFS;    %
open(writerObj);
frameN = 1; eck = 1;            % start at 1st frame and corresponding EEG sample
spsf = 0.75; %spatial smoothing factor

%Update plots and write to video object
fprintf('Plotting and writing images to video file...\n');
writeClock = tic;
while frameN <= size(dff,3)
    fprintf('Frame %d out of %d - %.2f minutes\n',frameN,size(dff,3),toc(writeClock)/60);
    wi = yi(eck)-halfWin:yi(eck)+halfWin;
    egLine.YData = ds.eeg.data(wi);
    bfi = bfk-bfHW:bfk+bfHW;
    bfLine.YData = padded_bulkdfTrace(bfi);
    cf = dff(:,:,frameN);
    cf = imgaussfilt(cf,spsf).*msk2; %gaussian spatial filter and apply mask
    im.CData = flipud(cf);
    set(timetxt,'String',sprintf('%.2f',frameTimes(frameN)));
    drawnow;
    % update indices
    frameN = frameN + 1;
    eck = eck+2;
%     eck = eck + 1;
    bfk = bfHW+frameN;
    F = getframe(ecog_imag_fig);
    writeVideo(writerObj, F);
end
close(writerObj);
fprintf('Done writing video\n')

end % function end
