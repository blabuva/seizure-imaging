%% Sample script to detect/curate seizures and output the times of the 1st trough of each seizure (an estimate of the seizure start time)
[fn,fp] = uigetfile('*.rhd',['Select an' ...
    ' RHD file in the recording you ' ...   
    'want to analyze']);                            % select any RHD file in the recording you want to analayze
filename = fullfile(fp,fn);                         % creates full file path 
ec = 1;                                             % EEG channel (usually channel 1, but that could change)
tfs = 100;                                          % target sampling frequency (100Hz should be sufficient)
seizures = findSeizures('filename',filename,...
    'eegChannel',ec,'targetFS',tfs);                % automatically detects seizures based primarily on LFP power in certain freq band (default 4-8Hz)

%% Manual curation step
curated_seizures = curateSeizures(seizures);        % manually curate seizures

%% Each element of firstTroughTimes is the time of the first trough of a detect seizure
%  The units of firstTroughTimes are in seconds from the very beginning of the recording
firstTroughTimes = [];
for si = 1:numel(curated_seizures)
    if isempty(curated_seizures(si).trTimeInds)
        continue
    else
        ftt = curated_seizures(si).time(curated_seizures(si).trTimeInds(1));
        firstTroughTimes = [firstTroughTimes;ftt];
    end
end

% save(fullfile(fp,'firstTroughTimes.mat'),...
% "firstTroughTimes");                                % save firstTroughTimes in the folder where the RHD files are