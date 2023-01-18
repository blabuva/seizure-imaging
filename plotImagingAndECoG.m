%%
vfn = 'C:\Users\Scott\Desktop\testVid.avi';
writerObj  = VideoWriter(vfn);
[fn, fp] = uigetfile('*.adicht');
filename = [fp,fn];
ttl = adiLoadEEG(filename,2,20000);
x = ttl.data>3; % generating TTL trace
rte = diff(x)>0; %rising TTL edges
yi = find(rte); % indices of rising edges

%%
EEG = adiLoadEEG(filename,1,20000);
frameTimes = EEG.time(yi);
vidFS = round([numel(frameTimes)/(frameTimes(end)-frameTimes(1))]/2); %video sampling frequency
writerObj.FrameRate = vidFS;
open(writerObj);
windowSize = 10; %seconds
halfWin = windowSize/2*EEG.finalFS;

%% Make figure
ecog_imag_fig = figure;
ecogax = subplot(10,1,1:2);
imgax = subplot(10,1,4:10);
grid; % turn grid on for


%% Initialize ECoG plot and show first window
imk = 0;    % frame index (0-indexed)
eck = imk+1;    % ecog index (1-indexed)
axes(ecogax);
set(ecogax,'YLim',[-10 10],'XLim',[-windowSize/2 windowSize/2]);
wt = linspace(ecogax.YLim(1),ecogax.YLim(2),halfWin*2+1);
wi = yi(eck)-halfWin:yi(eck)+halfWin;
egLine = plot(wt,EEG.data(wi),'k');
ecogax.Title.String = 'ECoG';
ecogax.YLabel.String = 'Voltage';
% ecogax.XLabel.String = 'Time from present (seconds)';
grid on
%%
dList = dir(fp);
fn = dList(contains({dList.name},'.dcimg')).name;
dcimg_filename = fullfile(fp,fn);
hdcimg = dcimgmex('open',dcimg_filename);                     % open the original .dcimg file
nof = dcimgmex('getparam',hdcimg,'NUMBEROF_FRAME');     % retrieve the total number of frames in the session

%% Initialize imaging plot and show first frame
axes(imgax);
greenMap = [zeros(256,1), linspace(0,1,256)', zeros(256,1)];
imgax.Colormap = colormap(greenMap);
imgData = dcimgmex('readframe', hdcimg, imk)';% read in next frame
im = imagesc(flipud(imgData));
set(imgax, 'box','off','XTickLabel',[],'XTick',[],'YTickLabel',[],'YTick',[])
hold on
timetxt = text(260,25,sprintf('%.2f',frameTimes(eck)),'Color','w','FontSize',18);
hold off
set(gcf().Children,'FontSize',20);
set(imgax,'CLim',[500 1500])
set(ecogax,'YLim',[-10 10],'XLim',[-windowSize/2 windowSize/2]);
colorbar;
set(ecog_imag_fig,'Position',[400 50 950 900],'Visible','off');
drawnow;
F = getframe(ecog_imag_fig);
writeVideo(writerObj, F);
%% Update Plots
writeClock = tic;
while (imk+1) < 5000
    fprintf('Frame %d out of %d - %.2f minutes total\n',imk,nof,toc(writeClock)/60);
    imk = imk + 2;
    eck = imk+1;
    wi = yi(eck)-halfWin:yi(eck)+halfWin;
    imgData = dcimgmex('readframe', hdcimg, imk)';% read in next frame
    egLine.YData = EEG.data(wi);
    im.CData = flipud(imgData);
    set(timetxt,'String',sprintf('%.2f',frameTimes(eck)));
    drawnow;
    F = getframe(ecog_imag_fig);
    writeVideo(writerObj, F);
end
close(writerObj);

%%
dcimgmex('close',hdcimg);

