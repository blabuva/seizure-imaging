function seizures = findSeizures_MatlabFromLabChart(varargin)%pband, ptCut, ttv, eegChannel, targetFS)
%% findSeizures Finds seizures in an EEG/LFP traces based on power thresholding
%
% INPUTS:
%   %----------------------Name-Value-Pairs----------------------%
%   Name: 'filename'     Value: full file path to file with EEG data
%   Name: 'pband'        Value: passband filter limits for seizure detection (default = [4 8])
%   Name: 'ttv'          Value: trough threshold value. This value is multipled by the standard
%                               deviation of the EEG to set a threshold that seizure troughs must
%                               pass (default = 3)
%   Name: 'ptCut'        Value: percentile cuttoff threshold. This value determines the
%                               threshold for detecting potential seizures by bandpower thresholding (default = 95)
%   Name: 'eegChannel'   Value: channel number of the EEG (usually 1 or 2) (default = 1)
%   Name: 'targetFS'     Value: target sampling frequency. Used to downsample data to
%                               reduce computational load (default = 200)
%   Name: 'plotFlag'     Value: 0 or 1 for no plot or plotting options, respectively (default = 1)
%   Name: 'tb'           Value: time buffer (in seconds) before and after seizures to grab  (default = 2)
%   %------------------------------------------------------------%
%
% OUTPUTS:
%   seizures - structure containing information about detected seizures
%
% Written by Scott Kilianski
% Updated 5/26/2023

%-------------------------------------------------------------------------%
%% Quick check to get the correct 'findpeaks' function because the chronux
% toolbox function of the same name sometimes shadows the MATLAB signal
% processing toolobox version (i.e. the version we actually want)
fpList = which('findpeaks.m','-all'); % find all 'findpeaks.m'
fpInd = find(contains(fpList,[filesep 'toolbox' filesep 'signal' filesep 'signal' filesep 'findpeaks.m']),1,'first'); %get location of the correct 'findpeaks.m'
currdir = cd; % save current directory path
cd(fileparts(fpList{fpInd})); % change directory to locatin of correct 'findpeaks.m'
fpFun = @findpeaks; % set function handle to correct 'findpeaks.m'
cd(currdir); % cd back to original directory

%-------------------------------------------------------------------------%
%% Parse inputs
validScalarNum = @(x) isnumeric(x) && isscalar(x);
default_filename = [];
default_pband = [4 8];
default_ptCut = 95;
default_ttv = 3;
default_eegChannel = 1;
default_targetFS = 200;
default_plotFlag = 1;
default_tb = 2; % time buffer (in seconds) - time to grab before and after each detected seizure
p = inputParser;
addParameter(p,'filename',default_filename,@(x) isstring(x) || ischar(x));
addParameter(p,'pband',default_pband,@(x) numel(x)==2);
addParameter(p,'ptCut',default_ptCut,validScalarNum);
addParameter(p,'ttv',default_ttv,validScalarNum);
addParameter(p,'eegChannel',default_eegChannel,validScalarNum);
addParameter(p,'targetFS',default_targetFS);
addParameter(p,'plotFlag',default_plotFlag);
addParameter(p,'tb',default_tb);
parse(p,varargin{:});
filename = p.Results.filename;
pband = p.Results.pband;
ptCut = p.Results.ptCut;
ttv = p.Results.ttv;
eegChannel = p.Results.eegChannel;
targetFS = p.Results.targetFS;
plotFlag = p.Results.plotFlag;
tb = p.Results.tb;
detectionParameters(1,:) = {'pband','ptCut','ttv','eegChannel'};
detectionParameters(2,:) = {pband,ptCut,ttv,eegChannel};

%-------------------------------------------------------------------------%
%% Load in data
if isempty(filename)
    [fn,fp,rv] = uigetfile({'*.abf;*.mat;*.adicht;*.rhd'});
    if ~rv % if no file selected, end function early
        return
    else
        filename = fullfile(fp,fn);
    end
end
[fp, fn, fext] = fileparts(filename);                   % get file name, path, and extension
if strcmp(fext,'.mat')
    EEG = matLoadEEG(filename,eegChannel,targetFS);     % loads .mat files that were exported from LabChart
else
    error('File type unrecognized. Use .rhd, .adicht, .mat file types only');
end
detectionParameters = [detectionParameters,{'finalFS';EEG.finalFS}];

%-------------------------------------------------------------------------%
%% Calculate spectrogram and threshold bandpower in band specificed by pband
frange = [0 50];                                            % frequency range used for spectrogram
[spectrogram,t,f] = MTSpectrogram([EEG.time, EEG.data*0.01],...
    'window',1,'overlap',0.5,'range',frange);              % computes the spectrogram
bands = SpectrogramBands(spectrogram,f,'broadLow',pband);   % computes power in different bands

% Find where power crosses threhold (rising and falling edge)
tVal = prctile(bands.broadLow, ptCut);          % find the bandpower threshold value based on percentile threshold (ptCut)
riseI = find(diff(bands.broadLow>tVal)>0) + 1;  % seizure rising edge index
fallI = find(diff(bands.broadLow>tVal)<0) + 1;  % seizure falling edge index

%-------------------------------------------------------------------------%
%% Find putative seizures, merge those that happen close in time, detect troughs, and store everything in structure(sz)
pzit = 2; % gap length under which to merge (seconds)
mszt = .5; % minimum seizure time duration (seconds)
ttv = -std(EEG.data)*ttv; % calculate trough threshold value (standard deviation * user-defined multiplier)

%-------------------------------------------------------------------------%
% INCLUDE BIT HERE TO CHECK IF CODE IS TRYING TO GRAB TIME OUTSIDE OF ACTUAL DATA (BECAUSE OF TIME BUFFER AROUND PUTATIVE SEIZURES)
%-------------------------------------------------------------------------%

if fallI(1) < riseI(1)
    fallI(1) = [];
end
if riseI(end) > fallI(end)
    riseI(end) = [];
end
startEnd = [t(riseI)-tb,t(fallI)+tb];           % seizure start and end times
startEnd_interp = interp1(EEG.time,EEG.time,...
    startEnd,'nearest');                    % interpolate from spectrogram time to nearest EEG timestamps
startEnd_interp = szmerge(startEnd_interp, pzit); % merge seizure if/when appropriate
tooShortLog = diff(startEnd_interp,1,2)<mszt; % find too-short seizures
startEnd_interp(tooShortLog,:) = []; % remove seizures that are too short
ts = cell2mat(arrayfun(@(x) find(x==EEG.time), ...
    startEnd_interp,...
    'UniformOutput',0)); % getting start and end indices
outfn = sprintf('%s%s%s_seizures.mat',fp,'\',fn); % name of the output file

%-------Check if date times are available-----------%
if isfield(EEG,'tv') && isfield(EEG,'recStart')
    DTtime = EEG.recStart + seconds(EEG.tv);
end
%---------------------------------------------------%

for ii = 1:size(ts,1)
    eegInd = ts(ii,1):ts(ii,2);
    seizures(ii).time = EEG.time(eegInd); % find EEG.time-referenced.
    seizures(ii).DTtime = DTtime(eegInd);
    seizures(ii).EEG = EEG.data(eegInd);
    seizures(ii).type = 'Unclassified';
    [trgh, locs] = fpFun(-seizures(ii).EEG); % find troughs (negative peaks)
    locs(-trgh>ttv) = []; % remove those troughs that don't cross the threshold (ttv)
    trgh(-trgh>ttv) = []; % remove those troughs that don't cross the threshold (ttv)
    seizures(ii).trTimeInds = locs; seizures(ii).trVals = -trgh; % store trough time (indices) and values in sz structure
    seizures(ii).filename = outfn;
    seizures(ii).parameters = detectionParameters;
end

%-------------------------------------------------------------------------%
%% Plotting trace, thresholds, and identified putative seizures
if plotFlag % plotting option
    figure; ax(1) = subplot(311);
    if isfield(EEG,'tv') && isfield(EEG,'recStart')
        nearestTime = interp1(EEG.time,EEG.time,t,'nearest','extrap');
        [~,Tidx] = ismember(nearestTime,EEG.time);
        t = EEG.recStart + seconds(EEG.tv(Tidx));
        plot(DTtime, EEG.data,'k','LineWidth',2); title('EEG');
    else
        plot(EEG.time, EEG.data,'k','LineWidth',2); title('EEG');
    end
    hold on
    plot(get(gca,'xlim'),[ttv,ttv],'b','linewidth',1.5); hold off;
    ax(2) = subplot(312);
    plot(t,bands.broadLow,'k','linewidth',2);
    title(sprintf('Power in %d-%dHz Range',pband(1),pband(2)));
    hold on
    plot(get(gca,'xlim'),[tVal,tVal],'r','linewidth',1.5); hold off;
    ax(3) = subplot(313);
    cutoffs = [3 8];
    %         pcolor(datenum(xData), yData, matrix);
    %         cplot = pcolor(t,f,spectrogram);
    cplot = pcolor(t,f,log(spectrogram));
    clim(cutoffs);
    set(cplot,'EdgeColor','none');
    colormap(jet)
    %         PlotColorMap(log(spectrogram),1,'x',t,'y',f,'cutoffs',cutoffs);
    title('Spectrogram'); xlabel('Time (sec)'); ylabel('Frequency (Hz)');
    title('Spectrogram'); xlabel('Time'); ylabel('Frequency (Hz)');
    linkaxes(ax,'x');
    axes(ax(1)); hold on;
    xlim('tight');
    drawnow;
    yP = [min(EEG.data), max(EEG.data), max(EEG.data), min(EEG.data)];
    for ii = 1:numel(seizures)
        xP = [seizures(ii).DTtime(1), seizures(ii).DTtime(1), ...   % seizure start time
            seizures(ii).DTtime(end), seizures(ii).DTtime(end)];    % end time
        a = area(xP,yP,'basevalue',min(EEG.data),...
            'FaceColor','g','EdgeColor','none','FaceAlpha',0.25);
        a.BaseLine.Visible = 'off';
    end
end % plotting option end

[fp, fn, fext] = fileparts(outfn);
try % try statement here because sometimes saving fails due to insufficient permissions
    save(outfn,'seizures'); % save output into same folder as filename
    fprintf('%s%s saved in %s\n',fn,fext,fp)
catch
    fprintf('%s%s could not be saved in %s, likely because of insufficient permissions\n',fn,fext,fp)
end

end %main function end

function startEnd_interp = szmerge(startEnd_interp, pzit)
%szmerge Merges overlapping or close-in-time seizures
pzInts = startEnd_interp(2:end,1)-startEnd_interp(1:end-1,2); % intervals between putative seizures
fprintf('Merging putative seizures if/when appropriate...\n')
tmInd = find(pzInts<pzit,1,'first'); % index of 1st putative seizure pair to merge
while tmInd % if putative seizures to merge, do it, then check for more
    startEnd_interp(tmInd,2) = startEnd_interp(tmInd+1,2); % replace the end time
    startEnd_interp(tmInd+1,:) = []; % remove 2nd putative seizure in the pair
    pzInts = startEnd_interp(2:end,1)-startEnd_interp(1:end-1,2); % intervals between putative seizures
    tmInd = find(pzInts<pzit,1,'first'); % check for more pairs to merge
end

end % szmerge function end
