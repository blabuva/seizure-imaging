fprintf('linuxTest2 started\n')
%% Load Camera TTLs
load('/media/scottX/SI_012_20221215/ttl.mat','ttl');
x = ttl.data>3; % generating TTL trace
rte = diff(x)>0; %rising TTL edges
yi = find(rte); % indices of rising edges

%% Load EEG Data
load('/media/scottX/SI_012_20221215/EEG.mat','EEG');
frameTimes = EEG.time(yi);
frameTimes = frameTimes(1:2:end); % get every other frame time (corresponds to only blue LED illumation)
windowSize = 10; %seconds
halfWin = windowSize/2*EEG.finalFS;

%% Initialize figure
ecog_imag_fig = figure;
ecogax = subplot(16,1,1:2);
dfax = subplot(16,1,4:5);
imgax = subplot(16,1,7:16);

%% Initialize ECoG plot
frameN = 1;    % frame index (1-indexed)
% eck = frameN;    % ecog index (1-indexed)
yl = [-5 5];        % user-defined y limits
xl = [-windowSize/2, windowSize/2]; % x limits
axes(ecogax);   
wt = linspace(xl(1),xl(2),halfWin*2+1);
wi = yi(frameN)-halfWin:yi(frameN)+halfWin;
egLine = plot(ecogax,wt,EEG.data(wi),'k');
set(ecogax,'YLim',yl,'XLim',xl);
ecogax.Title.String = 'ECoG';
ecogax.YLabel.String = 'Volts';
grid on
%% Image loading and processing
img = imgbinRead('/media/scottX/SI_012_20221215/SI_012_2022121500001.imgbin');     % read in the imaging data
nm470 = img.Data.frames(:,:,1:2:end); %grab every other frame (470nm illumination only)
diffImage = double(nm470) - mean(nm470,3);
diffZero = max(diffImage,0);
divImage = (diffZero ./ mean(nm470,3));
finalMin = min(divImage(:));
finalMax = max(divImage(:));

%% Initialize imaging plot and show first frame
axes(imgax);
imgax.CLim = [finalMin,.15];
% greenMap = [zeros(256,1), linspace(0,1,256)', zeros(256,1)];
imgax.Colormap = colormap(gray);
baseFrame = 2;
im = imagesc(imgax,flipud(divImage(:,:,baseFrame)));  % PLOT 2ND FRAME BC 1ST IS USUALLY NON-REPRESENTATIVE
set(imgax, 'box','off','XTickLabel',[],'XTick',[],'YTickLabel',[],'YTick',[])
hold on
timetxt = text(260,25,sprintf('%.2f',frameTimes(baseFrame)),'Color','r','FontSize',18);
hold off
set(imgax,'CLim',[finalMin,.15])
colorbar;
%% Draw Mask and calculate bulk fluorescence vector and %%%%%%% plot fluorescence trace %%%%%%%
fprintf('Waiting for user to draw contour around imaging area...\n');
fhShape = drawfreehand;
fprintf('User is finished drawing\n');
msk = fhShape.createMask;
bulk_dfTrace = squeeze(sum(divImage.*msk,[1 2]));
vidFS = round([numel(frameTimes)/(frameTimes(end)-frameTimes(1))]); %video sampling frequency (one-color only)
bfTime = linspace(xl(1),xl(2),vidFS*windowSize+1); % time units
bfHW = floor(vidFS*windowSize/2);               %
padded_bulkdfTrace = [zeros(1,bfHW), bulk_dfTrace',zeros(1,bfHW+1)]; %add zeros and beginning and end of recording
bfk = bfHW+1; % bulk fluorescence index
bfi = bfk-bfHW:bfk+bfHW;
axes(dfax);
bfLine = plot(dfax,bfTime,padded_bulkdfTrace(bfi),'k');              % 
grid on
set(gcf().Children,'FontSize',20);
set(dfax,'Ylim',[0 3000])
set(dfax,'XLim',xl);
dfax.Title.String = 'Bulk Fluorescence';
dfax.YLabel.String = 'Intensity';
%% Initialize video object
vfn = '/media/scottX/SI_012_20221215/ECoGandGCaMP_synced_ecogAxFixed.avi';
writerObj  = VideoWriter(vfn);
writerObj.FrameRate = vidFS;
open(writerObj);
frameN = 1; eck = 1; %start at 1st frame and corresponding EEG sample
writeClock = tic;
nof = size(divImage,3); % number of frames (in this color at least)
% set(ecog_imag_fig,'Visible','off');
%% Update plots and write to video object
while frameN < nof
    fprintf('Frame %d out of %d - %.2f minutes\n',frameN,nof,toc(writeClock)/60);
    wi = yi(eck)-halfWin:yi(eck)+halfWin;
    egLine.YData = EEG.data(wi);
    bfi = bfk-bfHW:bfk+bfHW;
    bfLine.YData = padded_bulkdfTrace(bfi);
    im.CData = flipud(divImage(:,:,frameN)).*msk;
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