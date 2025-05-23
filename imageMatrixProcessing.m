
%% ---- Grab data and reshape it for dF/F calculation ---- %%
fprintf('Loading and processing image series...\n');
imgFile = '/media/scottX/SI_Project/20230213/SI_014_20230213_00001.imgbin';
img = imgbinRead(imgFile); % read in the imaging data
drawFig = figure; 
imagesc(img.Data.frames(:,:,1)); % display first frame
colormap(gray);

%% Draw mask and apply to image matrix
fprintf('Waiting for user to draw contour around imaging area...\n');
fhShape = drawassisted;                 % draw shape
msk = fhShape.createMask;               % create mask from shape
fprintf('User is finished drawing\n');
close(drawFig);
crange = find(sum(msk,1),1,'first'):find(sum(msk,1),1,'last');
rrange = find(sum(msk,2),1,'first'):find(sum(msk,2),1,'last');
ysz = numel(rrange);
xsz = numel(crange);
zsz = size(img.Data.frames,3)/2; % divide by 2 because you only want half (ie the blue frames only)
msk2 = msk(rrange,crange);
trace = reshape(img.Data.frames(rrange,crange,[1:2:(zsz*2)]), xsz*ysz,zsz)'; % linearize pixels

%% Apply dF/F function and reshape data back into height x width x frames shape
dff = pixelFilter(trace,25,.1);
dff = reshape(dff',ysz,xsz,zsz);        % reshape the imaging matrix back into (height x width x # of frames)

%% ---- Loading camera TTLs and EEG data ---- %%

% Camera TTLs
fprintf('Loading camera output TTLs...\n');
load('/media/scottX/SI_Project/20230213/SI_014_20230213_2_ttl.mat','ttl');
x = ttl.data>3;     % generating TTL trace
rte = diff(x)>0;    % rising TTL edges
yi = find(rte);     % indices of rising edges

% EEG data
fprintf('Loading EEG data...\n');
load('/media/scottX/SI_Project/20230213/SI_014_20230213_2_EEG.mat','EEG');
frameTimes = EEG.time(yi);          % get the frame times (time when there is a rising TTL edge from the camera)
% frameTimes = frameTimes(1:2:end);   % get every other frame time (corresponds to only blue LED illumation)
windowSize = 10;                    % time window to display ECoG data (in seconds units)
halfWin = windowSize/2*EEG.finalFS; % calculate the half-window (in # of EEG sample units)
frameTimes = frameTimes(1:2:end);   % grab every other frame time
if numel(frameTimes) > size(dff,3)
    frameTimes(size(dff,3)+1:end) = []; % delete excess frame TTLs
end

%% ---- Initialize figure ---- %%
fprintf('Initializing figure...\n');
ecog_imag_fig = figure; 
ecogax = subplot(16,1,1:2);
dfax = subplot(16,1,4:5);
imgax = subplot(16,1,7:16);

% Initialize ECoG plot
frameN = 1;                                 % frame index (1-indexed)
yl = [-10 10];                                % user-defined y limits for ECoG axis (should not be more than +-10)
xl = [-windowSize/2, windowSize/2];         % x limits; determined by the ECoG window size defined earlier
axes(ecogax);
wt = linspace(xl(1),xl(2),halfWin*2+1);     % time vector in ECoG window (relative to current time)
wi = yi(frameN)-halfWin:yi(frameN)+halfWin; % indices into EEG data at camera output TTL rising edges
egLine = plot(ecogax,wt,EEG.data(wi),'k');  % plot first bit of ECoG data
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
vfn = '/media/scottX/SI_Movies/SI_014_20230213_ECoGGCaMPmovie_TESTING.avi';
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
    egLine.YData = EEG.data(wi);
    bfi = bfk-bfHW:bfk+bfHW;
    bfLine.YData = padded_bulkdfTrace(bfi);
    cf = imgaussfilt(cf,spsf);
    cf = dff(:,:,frameN).*msk2;
    im.CData = flipud(cf);
    set(timetxt,'String',sprintf('%.2f',frameTimes(frameN)));
    drawnow;
    % update indices
    frameN = frameN + 1;
    eck = eck+2;
    bfk = bfHW+frameN;
    F = getframe(ecog_imag_fig);
    writeVideo(writerObj, F);
end
close(writerObj);
fprintf('Done writing video\n')

% SCRIPT END
