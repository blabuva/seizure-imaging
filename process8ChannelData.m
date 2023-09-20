%% Process various time series signals

%%
fileList = dir(uigetdir);
rmLog = strcmp({fileList.name},'.') | strcmp({fileList.name},'..');
fileList(rmLog) = [];
[~, fNames, fExts] = fileparts({fileList.name});

%% Process time series data
abfFile = fileList(contains(fExts,'abf')).name;
abfFile = fullfile(fileList(1).folder,abfFile);
[d.data, d.si, d.h] = abf2load(abfFile);
SI = 1e-6 * d.si; %sampling interval (in seconds)
timeVec = ((1:size(d.data,1))-1) .* SI; % time vector converted to seconds

%% Plot
if 0
tsFig = figure;
sigOrder = [1,3,4,5,6,7];
% convert rotary encoder (3) to speed 
% colorOrd = ; 
plotIdx = 1;
for sigIdx = sigOrder
    ax(plotIdx) = subplot(numel(sigOrder),1,plotIdx);
    plotIdx = plotIdx+1; 
    plot(timeVec, d.data(:,(sigIdx)))
    xticklabels([])
    ylabel(d.h.recChUnits(sigIdx));
end
set(ax(end),'XTickLabelMode','auto')
linkaxes(ax,'x');
ax(end).XLabel.String = 'Time (seconds)';

end

%% Process eye images
eyeFiles = {fileList(contains(fExts,'pgm')).name};
% for ei = 1:numel(eyeFiles)
%     currFile = fullfile(fileList(1).folder,eyeFiles{ei});
%     eyeImg = flipud(imread(currFile));
%     imshow(fliplr(eyeImg));
%     drawnow;
%     % Calculate pupil size
% end
eyeLvl = 1.5; %threshold level
eyeIdx = find(diff(d.data(:,8)>eyeLvl)==1)+1;
eyeTimes = timeVec(eyeIdx);

%% Process cortex images
ctxLvl = 2.5; %threshold level
ctxIdx = find(diff(d.data(:,2)>ctxLvl)==1)+1;
ctxTimes = timeVec(ctxIdx);

hcFile = fileList(contains(fExts,'imgbin')).name;
hcFile = fullfile(fileList(1).folder,hcFile);
ctx = imgbinRead(hcFile);

%% Resample data and find image frame times
updateFreq = 30; % frames per second
sv = 0:1/updateFreq:timeVec(end);
tsTimes = interp1(timeVec,timeVec,sv,'nearest');
[~,tsIdx] = ismember(tsTimes,timeVec);

winSize = 10; % temporal window size in seconds 
winss = 1/SI * winSize;
winIdx = 0:winss;
toRemove = tsIdx+winss>length(timeVec);
tsIdx = tsIdx(~toRemove); % remove frames that would exceed the data limit (when current window size is used)

eyeT = interp1(tsIdx,tsIdx,eyeIdx,'nearest'); % putting eye image frame time indices in new reference frame
[~,eyeFrames] = ismember(tsIdx,eyeT);

ctxT = interp1(tsIdx,tsIdx,ctxIdx,'nearest'); % putting cortex image frame time indices in new reference frame
[~,ctxFrames] = ismember(tsIdx,ctxT); 

%% Initialize figure
[CSDfig, ax] = initializeCSDfig();

% initialize imaging windows 
imagesc(ax.gcamp,imrotate(ctx.Data.frames(:,:,1),180));
imagesc(ax.vrefl,imrotate(ctx.Data.frames(:,:,2),180));
currFile = fullfile(fileList(1).folder,eyeFiles{1});
imagesc(ax.pupil,imrotate(imread(currFile),180));
colormap(gray);

%%
for tsii = 21200:numel(tsIdx)
    dr = winIdx+tsIdx(tsii);
    td = timeVec(dr);
    set(ax.ecog.Children,'XData',td,'YData', d.data(dr,1))
    set(ax.speed.Children,'XData',td,'YData', d.data(dr,3))
    set(ax.hr.Children,'XData',td,'YData', d.data(dr,4))
    set(ax.spO2.Children,'XData',td,'YData', d.data(dr,5))
    set(ax.br.Children,'XData',td,'YData', d.data(dr,6))
    set(ax.bd.Children,'XData',td,'YData', d.data(dr,7))
    eF = eyeFrames(tsii);
    cF = ctxFrames(tsii);
if eF
    currFile = fullfile(fileList(1).folder,eyeFiles{eF});
    ax.pupil.Children.CData = imrotate(imread(currFile),180);
end

if cF
    if mod(cF,2) % if odd, change gcamp image
        ax.gcamp.Children.CData = imrotate(ctx.Data.frames(:,:,cF),180);
    else    % if even, change violet reflectance image
        ax.vrefl.Children.CData = imrotate(ctx.Data.frames(:,:,cF),180);
    end
end
ax.bd.XLim = [td(1), td(end)];
drawnow;
disp(tsii);
end
% for EACH tsIdx GET THE CORRESPONDING WINDOW OF DATA AND PLOT

