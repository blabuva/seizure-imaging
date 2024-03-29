%%
vfn = '/home/scott/Desktop/SI_014_20230213.avi';
writerObj  = VideoWriter(vfn);
open(writerObj);
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
writerObj.FrameRate = 30;
windowSize = 10; %seconds
halfWin = windowSize/2*EEG.finalFS;

%% Make figure
ecog_imag_fig = figure;
ecogax = subplot(10,1,1:2);
imgax = subplot(10,1,4:10);

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
% set(ecogax,'YLim',[-10 10],'XLim',[-windowSize/2 windowSize/2]);
% ecogax.XLabel.String = 'Time from present (seconds)';
grid on
%%
<<<<<<< HEAD
dList = dir(fp);
[~, filen] = fileparts(filename);
usInd = regexp(filen,'_');
subjName = filen(1:usInd(2)-1);
fn = dList(contains({dList.name},'.dcimg') & contains({dList.name},subjName)).name;
=======
dList = dir(fp);                        % list directory contents
[~, filen] = fileparts(filename);       % get the filename of the EEG file
usInd = regexp(filen,'_');              % get index of 2nd underscore in filename
subjName = filen(1:usInd(2)-1);         % get the subject 'name'
fn = dList(contains({dList.name},'.dcimg') & contains({dList.name},subjName)).name;  
>>>>>>> 3b15287d38a20df873aa23a6c21ebd082a9db9cc
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
timetxt = text(450,50,sprintf('%.2f',frameTimes(eck)),'Color','w','FontSize',18);
hold off
set(gcf().Children,'FontSize',20);
<<<<<<< HEAD
set(imgax,'CLim',[50 10000])
=======
set(imgax,'CLim',[500 15000])
>>>>>>> 3b15287d38a20df873aa23a6c21ebd082a9db9cc
set(ecogax,'YLim',[-10 10],'XLim',[-windowSize/2 windowSize/2]);
colorbar;
% set(ecog_imag_fig,'Position',[400 50 950 900],'Visible','off');
set(ecog_imag_fig,'Position',[400 50 950 900]);
drawnow;
F = getframe(ecog_imag_fig);
writeVideo(writerObj, F);
%% Update Plots
writeClock = tic;
while (imk+1) < nof
<<<<<<< HEAD
    fprintf('Frame %d out of %d - %.2f\n',imk,nof,toc(writeClock)/60);
=======
    fprintf('Frame %d out of %d - %.2f minutes total\n',imk,nof,toc(writeClock)/60);
>>>>>>> 3b15287d38a20df873aa23a6c21ebd082a9db9cc
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
% dcimgmex('close',hdcimg);

