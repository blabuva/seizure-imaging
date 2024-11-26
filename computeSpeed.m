function [spd_smoothed, bc, spdVec] = computeSpeed(varargin)
%% computesSpeed Calculates instantaneous speed vector based on rotary encoder information
% INPUTS (optional):
%   filename - varargin{1} - full path to the directory containing adicht or abf file
%   smoothWin - varargin{2} - smoothing time window (in seconds)
%   plotFlag - varargin{3} - 0 for no plotting, 1 for plotting
% OUTPUTS:
%   spd_smoothed - instantaneous speed vector of time
%   bc - bin centers. The middle point of each time bin (same length as spd_smoothed)
%
%
% Written by Scott Kilianski
% Updated 4/13/2023

%% Set data file and handle function inputs
if isempty(varargin)
    [fn,fp,rv] = uigetfile('*.adicht;*.abf');
    if ~rv % if no file selected, end function early
        return
    else
        filename = fullfile(fp,fn);
    end
else
    filename = varargin{1};
end
[~,~,fext] = fileparts(fn);

if nargin < 2
    smoothWin = 5; %seconds
else
    smoothWin = varargin{2}; % seconds
end

if nargin < 3
    plotFlag = 1;
else
    plotFlag = varargin{3};
end
binSize = 1; % in seconds

%% Loading file
if strcmp(fext,'.abf')
    [d, si] = abf2load(fullfile(fp,fn));
    dt = si * 10^-6; % convert time interval from microseconds to seconds
    time = (0:size(d,1)-1)*dt; %create time vector
    data = d(:,3);
elseif strcmp(fext,'.adicht')
    re = adiLoadEEG(filename,3,20000); % rotary encoder information
    data = re.data;
    time = re.time;
else
    error(['The file you selected does not have a .abf or .adicht ' ...
        'extension. This function only works with files that do.']);
end

%% Calculate speed vector
[~, rt] = risetime(data,time); %find rise times
binVec = time(1):binSize:time(end);
[bv,be] = histcounts(rt,binVec);
bc = be(1:end-1) + mean(diff(be))/2; % bin centers
% distK = 0.9576; % distance constant: distance per output of rotary encoder (in cm)
distK = 0.6604; 
spdVec = (bv*distK)/binSize; % delta_dist/delta_time (cm per second)
spd_smoothed = smoothdata(spdVec,"movmean",smoothWin);

%% Plot, if plotFlag is on
if plotFlag
    figure; plot(bc,spd_smoothed,'k');
    title('Speed');
    ylabel('cm/sec');
    xlabel('Time (sec)')
end

end % function end