%% 
% [fn, fp] = uigetfile('*.mat');
% filename = [fp,fn];
% ttl = adiLoadEEG(filename,2,20000);
load('/media/scottX/SI_012_20221215/ttl.mat','ttl');
x = ttl.data>3; % generating TTL trace
rte = diff(x)>0; %rising TTL edges
yi = find(rte); % indices of rising edges

%%
% EEG = adiLoadEEG(filename,1,20000);
load('/media/scottX/SI_012_20221215/EEG.mat','EEG');
frameTimes = EEG.time(yi);

windowSize = 10; %seconds
halfWin = windowSize/2*EEG.finalFS;

%% Make figure
figure;
ecogax = subplot(10,1,1:2);
imgax = subplot(10,1,4:10);
grid; % turn grid on for 


%% Initialize ECoG plot and show first window
frameN = 1;    % frame index (1-indexed)
eck = frameN;    % ecog index (1-indexed)
axes(ecogax);
set(ecogax,'YLim',[-5 5],'XLim',[-windowSize/2 windowSize/2]);
wt = linspace(ecogax.YLim(1),ecogax.YLim(2),halfWin*2+1);
wi = yi(eck)-halfWin:yi(eck)+halfWin;
egLine = plot(wt,EEG.data(wi),'k');
set(ecogax,'YLim',[-5 5]);
ecogax.Title.String = 'ECoG';
ecogax.YLabel.String = 'Voltage';
% ecogax.XLabel.String = 'Time from present (seconds)';
grid on
%% Image loading and processing
%
[fn,fp] = uigetfile('*.imgbin'); % UI to select .imgbin file
filename = fullfile(fp,fn);     % append to make full file path
img = imgbinRead(filename);     % read in the imaging data
nm470 = img.Data.frames(:,:,1:2:end); %grab every other frame (470nm illumination only)

%
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
im = imagesc(flipud(divImage(:,:,frameN)));
set(imgax, 'box','off','XTickLabel',[],'XTick',[],'YTickLabel',[],'YTick',[])
hold on
timetxt = text(260,25,sprintf('%.2f',frameTimes(frameN)),'Color','g','FontSize',18);
hold off
set(gcf().Children,'FontSize',20);
set(imgax,'CLim',[finalMin,.15])
colorbar;
%% Update Plots
frameN = frameN + 1;
eck = eck+2;
wi = yi(eck)-halfWin:yi(eck)+halfWin;
egLine.YData = EEG.data(wi);
im.CData = flipud(divImage(:,:,frameN));
set(timetxt,'String',sprintf('%.2f',frameTimes(frameN)));
