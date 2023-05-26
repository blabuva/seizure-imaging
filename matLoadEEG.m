function EEG = matLoadEEG(filename,eegChannel,targetFS)
%%
% matLoadEEG loads and downsamples the EEG data from a MATLAB data file
% (.mat) created by exporting from LabChart
% INPUTS:
%   filename - full file name to the .adicht file (including path)
%   eegChannel - channel number of the EEG, typically 1
%   targetFS - desired sampling frequency. This is useful for downsampling EEG data and making it easier to work with
% OUTPUTS:
%   EEG - a structure with following fields related to EEG signal:
%       data - actual values of EEG (in volts)
%       time - times corresponding to values in data field (in seconds)
%       tartgetFS - target sampling frequency specified by user (in samples/second)
%       finalFS - the sampling frequency ultimately used (in
%       samples/second)
%
% Written by Scott Kilianski
% Updated 5/26/2023

%% Set defaults as needed if not user-specific by inputs
if ~exist('eegChannel','var')
    eegChannel = 1; %default
end
if ~exist('targetFS','var')
    targetFS = 200; %default
end

%% Load raw data from .mat and resample
funClock = tic;     % function clock
fprintf('Loading data in\n%s...\n',filename);
load(filename,'data','samplerate');
if samplerate < targetFS
    warning(sprintf(['Sample rate is less than target FS of %dHz, ' ...
        'so using the acquisition sample rate of %dHz instead'],...
        targetFS,samplerate));
    targetFS = samplerate;
end
timeVec = ((1:length(data))-1)/samplerate(eegChannel);  % create time vector
dsFactor = floor(samplerate(eegChannel) / targetFS);    % downsampling factor to achieve targetFS
finalFS = samplerate(eegChannel) / dsFactor;            % calculate ultimate sampling frequency to be used
EEGdata = data(eegChannel,1:dsFactor:end)';             % subsample raw data
EEGtime = timeVec(1:dsFactor:end)';                      % subsample the time vector at dsFactor

%% Create output structure and assign values to fields
EEG = struct('data',EEGdata,...
    'time',EEGtime,...
    'finalFS',finalFS);

%%
fp = fileparts(filename);
fDir = dir(fp);
tdLog = strcmp({fDir.name},'timeData.mat'); %
if isempty(tdLog)
    warning(['No timeData.mat file found in this folder....' ...
        'Please create this file and run again if ' ...
        'you want Date-Time style plotting.'])
else
    tdName = fullfile(fp,fDir(tdLog).name);     %
    load(tdName,'recStart','tv');               % load in time vector ('tv') and start of recording time
    EEG.recStart = recStart;
    EEG.tv = double(tv(1:dsFactor:end));
end

fprintf('Loading data took %.2f seconds\n',toc(funClock));

end % function end