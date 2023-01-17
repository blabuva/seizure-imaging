%% 
[fn, fp] = uigetfile('*.adicht');
filename = [fp,fn];
ttl = adiLoadEEG(filename,2,20000);
x = ttl.data>3; % generating TTL trace
rte = diff(x)>0; %rising TTL edges
yi = find(rte); % indices of rising edges

%%
EEG = adiLoadEEG(filename,1,20000);
frameTimes = EEG.time(yi);
windowSize = 10; %seconds
halfWin = windowSize/2*EEG.finalFS;

%% Make figure
figure;
ecogax = subplot(10,1,1:2);
imgax = subplot(10,1,4:10);
grid; % turn grid on for 


%% Initialize ECoG plot and show first window
imk = 0;    % frame index (0-indexed)
eck = imk+1;    % ecog index (1-indexed)
axes(ecogax);
wt = linspace(ecogax.YLim(1),ecogax.YLim(2),halfWin*2+1);
wi = yi(eck)-halfWin:yi(eck)+halfWin;
egLine = plot(wt,EEG.data(wi),'k');
set(ecogax,'YLim',[-5 5],'XLim',[-windowSize/2 windowSize/2]);
ecogax.Title.String = 'ECoG';
ecogax.YLabel.String = 'Voltage';
% ecogax.XLabel.String = 'Time from present (seconds)';
grid on
%%
[fn,fp] = uigetfile('*.dcimg');
dcimg_filename = [fp,fn];
hdcimg = dcimgmex('open',dcimg_filename);                     % open the original .dcimg file
nof = dcimgmex('getparam',hdcimg,'NUMBEROF_FRAME');     % retrieve the total number of frames in the session

%% Initialize imaging plot and show first frame
axes(imgax);
imgax.CLim = [1800,2500];
greenMap = [zeros(256,1), linspace(0,1,256)', zeros(256,1)];
imgax.Colormap = colormap(greenMap);
imgData = dcimgmex('readframe', hdcimg, imk)';% read in next frame
im = imagesc(flipud(imgData));
set(imgax, 'box','off','XTickLabel',[],'XTick',[],'YTickLabel',[],'YTick',[])
hold on
timetxt = text(260,25,sprintf('%.2f',frameTimes(imk)),'Color','w','FontSize',18);
hold off
set(gcf().Children,'FontSize',20);
set(imgax,'CLim',[1600 4000])
colorbar;
%% Update Plots
imk = imk + 2;
eck = eck+2;
wi = yi(eck)-halfWin:yi(eck)+halfWin;
imgData = dcimgmex('readframe', hdcimg, imk)';% read in next frame
egLine.YData = EEG.data(wi);
im.CData = flipud(imgData);
set(timetxt,'String',sprintf('%.2f',frameTimes(imk)));


%%
dcimgmex('close',hdcimg);

