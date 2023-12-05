function EEG = binLoadEEG(filename,targetFS)
%% binLoadEEG Loads and downsamples the EEG data from a .bin data file
% created by convertRHDtoBIN
%
% INPUTS:
%   filename - full file name to the .bin file (including path). There must
%       also be a timestamps.bin file in the same directory
%   eegChannel - channel number of the EEG, typically 1
%   targetFS - desired sampling frequency. This is useful for downsampling EEG data and making it easier to work with
%
% OUTPUTS:
%   EEG - a structure with following fields related to EEG signal:
%       data - actual values of EEG (in volts)
%       time - times corresponding to values in data field (in seconds)
%       tartgetFS - target sampling frequency specified by user (in samples/second)
%       finalFS - the sampling frequency ultimately used (in
%       samples/second)
%
% Written by Scott Kilianski
% Updated 2023-11-06
%
% TO DO:
%   - add argument to select which analog channel to read data from
%
%% Function Body 
funClock = tic; % function clock
% Set defaults as needed if not user-specific by inputs
if ~exist('targetFS','var')
    targetFS = 3000; %default
end

%% Memory mapping and data grabbing
FID = fopen(filename);
fprintf('Loading data in\n%s...\n',filename);
data = fread(FID,'int16=>int16',14);
samplerate = 30000; % assumes 30kHz sampling rate. NOT ALWAYS TRUE

%% Load raw data from .mat and resample
tsVec = (1:length(data))'-1;                    % create time vector
dsFactor = floor(samplerate / targetFS);        % downsampling factor to achieve targetFS
finalFS = samplerate / dsFactor;                % calculate ultimate sampling frequency to be used
EEGdata = double(data(1:dsFactor:end));                 % subsample raw data
EEGtime = tsVec(1:dsFactor:end)/samplerate;   % subsample the time vector at dsFactor
EEGidx = tsVec(1:dsFactor:end)+1;               % indices to EEG times 

%% Create output structure and assign values to fields
EEG = struct('data',EEGdata,...
    'time',EEGtime,...
    'finalFS',finalFS,...
    'idx',EEGidx);

fprintf('Loading data took %.2f seconds\n',toc(funClock));

end % function end