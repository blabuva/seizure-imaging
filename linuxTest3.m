fprintf('linuxTest3 started\n')
%% Load Camera TTLs
fprintf('Loading camera output TTLs...\n');
load('/media/scottX/SI_Project/20230213/SI_014_20230213_2_ttl.mat','ttl');
x = ttl.data>3;     % generating TTL trace
rte = diff(x)>0;    % rising TTL edges
yi = find(rte);     % indices of rising edges

%% Load EEG Data
fprintf('Loading EEG data...\n');
load('/media/scottX/SI_Project/20230213/SI_014_20230213_2_EEG.mat','EEG');
frameTimes = EEG.time(yi);          % get the frame times (time when there is a rising TTL edge from the camera)
frameTimes = frameTimes(1:2:end);   % get every other frame time (corresponds to only blue LED illumation)
windowSize = 10;                    % time window to display ECoG data (in seconds units)
halfWin = windowSize/2*EEG.finalFS; % calculate the half-window (in # of EEG sample units)

%% Initialize figure
fprintf('Initializing figure...\n');
ecog_imag_fig = figure; 
ecogax = subplot(16,1,1:2);
dfax = subplot(16,1,4:5);
imgax = subplot(16,1,7:16);

%% Initialize ECoG plot
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
grid on

%% Image loading imaging data
fprintf('Loading and processing image series...\n');
img = imgbinRead('/media/scottX/SI_Project/20230213/SI_014_20230213_00001.imgbin');     % read in the imaging data
zsz = size(img.Data.frames,3);
% rrange = 141:470;
% xsz = numel(rrange);
% crange = 150:429;
% ysz = numel(crange);
% frange = 1:2:zsz;
% zsz = numel(frange);

%% Initialize imaging plot and show first frame
axes(imgax);
imgax.Colormap = colormap(gray);
baseFrame = 1; % PLOT 2ND FRAME BECAUSE 1ST IS OFTEN NON-REPRESENTATIVE
baseImage = image(img.Data.frames(:,:,baseFrame),'CDataMapping','scaled');    % plot baseline image for anatomical reference
set(imgax, 'box','off','XTickLabel',[],'XTick',[],...
    'YTickLabel',[],'YTick',[]);                                    % remove boxes and ticks
imgax.Title.String = 'Imaging Frames';
hold on
[bX, bY] = size(baseImage.CData);                                   % get x and y limits of the image
timetxt = text(.8*bX,.15*bY,sprintf('%.2f',frameTimes(baseFrame))); % set the text showing the time of the current frame
set(timetxt,'Color','c','FontSize',18);                             % set the font color and size of that frame time
redtxt = text(.05*bX,.9*bY,'Positive Fluorescence');                 % set the text showing that red is positive fluorescence from mean
set(redtxt,'Color','r','FontSize',10);
bluetxt = text(.05*bX,.95*bY,'Negative Fluorescence');
set(bluetxt,'Color','b','FontSize',10);
hold off
% colorbar;

%% Fitting photobleaching to a function for dF/F calculation

%[photobleaching,gof] = fit();

%% Calculating deltaF/F (dF/F)
% using median because of logorithmic decay of fluorescence due to photobleaching
fprintf('Calculating deltaF/F...\n');
%medianImage = median(nm470,3);                              % get some F (using median for now)
meanImage = mean(bminusv,3);                                   % use rms because pre-photobleaching was removed
%dfF = double(nm470-medianImage) ./ double(medianImage);             % calculate dF/F
dfF = (double(bminusv)-double(meanImage)) ./ double(meanImage);
dfMax = .25;                                                 % maximum absolute intensity change to set the transparency & color scales for dF/F

%% Draw mask and apply to image matrix
fprintf('Waiting for user to draw contour around imaging area...\n');
fhShape = drawassisted;                 % draw shape
fprintf('User is finished drawing\n');
msk = fhShape.createMask;               % create mask from shape
crange = find(sum(msk,1),1,'first'):find(sum(msk,1),1,'last');
rrange = find(sum(msk,2),1,'first'):find(sum(msk,2),1,'last');
ysz = numel(rrange);
xsz = numel(crange);
zsz = ;
msk2 = msk(rrange,crange);
trace = reshape(img.Data.frames(rrange,crange,frange), xsz*ysz,zsz)'; % linearize pixels

%% calculate bulk fluorescence vector and %%%%%%% plot fluorescence trace %%%%%%%
fprintf('Calculating bulk fluorecence signal over time...\n');
nof = size(dfF,3); % number of frames (in this color at least)
while nof > numel(frameTimes)
    frameTimes(end) = []; %get rid of excess frames
end
bulk_dfTrace = squeeze(sum(dfF.*msk,[1 2]));                         % calculate the summed df/F for each frame
vidFS = round([numel(frameTimes)/(frameTimes(end)-frameTimes(1))]);  % video sampling frequency (one-color only)
bfTime = linspace(xl(1),xl(2),vidFS*windowSize+1);                   % calculate 
bfHW = floor(vidFS*windowSize/2);               %
padded_bulkdfTrace = [zeros(1,bfHW), bulk_dfTrace',zeros(1,bfHW+1)]; % add zeros and beginning and end of recording
bfk = bfHW+1; % bulk fluorescence index
bfi = bfk-bfHW:bfk+bfHW;
axes(dfax);
bfLine = plot(dfax,bfTime,padded_bulkdfTrace(bfi),'k');              %
grid on
set(gcf().Children,'FontSize',20);
set(dfax,'Ylim',[-1000 3000])
set(dfax,'XLim',xl);
dfax.Title.String = 'Bulk Fluorescence';
dfax.YLabel.String = 'delF/F';

%% Initialize video object
fprintf('Initializing video...\n');
vfn = '/media/scottX/SI_Movies/SI_016_20230223_ECoGGCaMPmovie_TESTING_blue-violet.avi';
writerObj  = VideoWriter(vfn);
writerObj.FrameRate = vidFS;    %
open(writerObj);
frameN = 1; eck = 1;            % start at 1st frame and corresponding EEG sample
writeClock = tic;

%% Update plots and write to video object
fprintf('Plotting and writing images to video file...\n');
axes(imgax);
drawnow;
hold on
cmap = zeros([size(baseImage.CData),3]);
% ovFrame = zeros(size(baseImage.CData));     % set up current frame to be plotted -
ovImage = image(cmap,'AlphaData',0);     % plot the overlay image completely transparent (i.e. 'AlphaData'=0)
colorRes = 256; %256 possible color values
mapValues = linspace(-dfMax,dfMax,colorRes)';
redMap = linspace(0,1,colorRes);
blueMap = flip(linspace(0,1,colorRes));

while frameN <= nof
    fprintf('Frame %d out of %d - %.2f minutes\n',frameN,nof,toc(writeClock)/60);
    wi = yi(eck)-halfWin:yi(eck)+halfWin;
    egLine.YData = EEG.data(wi);
    bfi = bfk-bfHW:bfk+bfHW;
    bfLine.YData = padded_bulkdfTrace(bfi);
    %     im.CData = flipud(dfF(:,:,frameN)).*msk;
    frame_dfF = dfF(:,:,frameN) .* msk /dfMax;
    [a,mapInd] = ismember(interp1(mapValues,mapValues,frame_dfF,'nearest','extrap'),mapValues); % find corresponding color indices
    cmap(:,:,1) = redMap(mapInd); % red
    cmap(:,:,3) = blueMap(mapInd); % blue
    set(ovImage,'CData',cmap,'AlphaData',abs(frame_dfF));

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
fprintf('linuxTest2 finished\n')