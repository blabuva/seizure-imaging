%% --- 0 Input files --- %%
dcimg_file = '/media/scott3X/SI_Data/Sakina Gria x GCaMP_server/20241002/20241002_23000001.dcimg';
eeg_filename = '/media/scott3X/SI_Data/Sakina Gria x GCaMP_server/20241002/20241002_230_0000.abf'; 
img_file = '/media/scott3X/SI_Data/Sakina Gria x GCaMP_server/20241002/20241002_23000001.imgbin'; 
pointsFile = '/media/scott3X/SI_Data/Sakina Gria x GCaMP_server/20241002/20241002_230_mappedPoints.m';

%% --- 1 Check for dropped frames --- %%
ndf = droppedFrameCheck(eeg_filename,dcimg_filename);

%% --- 2 Convert to .imgbin --- %%
dcimgToBin(dcimg_file);

%% --- 3 Manually map points on image to dorsal cortex atlas --- %%
load('dorsalCortexAtlas.mat','dca');    % load the atlas data
img = imgbinRead(img_file);             % read in the imaging data
frame1 = img.Data.frames(:,:,1);        % get the first frame
brain_img = im2uint8(frame1);           % convert to uint8 for morphing
cph = cpselect(label2rgb(dca.labs),...
    brain_img);                         % select matching points in image and atlas

%% --- 4 Apply image morphing to register image to atlas --- %%
% load(pointsFile,'fixedPoints','movingPoints');
reg_img = imageMorphing(brain_img,dca.labs,fixedPoints,movingPoints);

%% --- 5 Generate dF/F trace for all pixels --- %%
sz = size(img.Data.frames); 

% -- Load imaging data into workspace and reshape it for filtering below -- %
mtx = reshape(img.Data.frames, sz(1)*sz(2),sz(3))'; % linearize pixels
% --------------------------------------------------------------------------%

[FT, Fs, EEG, tv] = getFrameTimes(eeg_filename,sz(3)); % get frame times and Fs
lowPass = .1; % low pass frequency (Hz)
dff = pixelFilter(mtx,Fs,lowPass);       % Apply dF/F function
dff = reshape(dff',sz(1),sz(2),sz(3));    % reshape the imaging matrix back into (height x width x # of frames)

%% --- 6 Use register image as mask to segment image series into discrete regions --- %%
% Iteration starts at 2 because 1 is 'root' (i.e. no brain region assigned)
fprintf('Segmenting image series into discrete regions...\n')
segClock = tic;
segWait = waitbar(0,'Segmenting image series...'); 
for ii = 2:numel(dca.labNames)
    cmask = repmat(reg_img==ii, 1, 1, sz(3)); % current image mask
    dft(ii,:) = sum(dff.*cmask,[1,2])./sum(cmask,[1,2]); % mean dF/F trace with the current mask
    waitbar(ii/(numel(dca.labNames)-1));
end
close(segWait);
fprintf('Segmenting took %.2f minutes \n',toc(segClock)/60); 


% --- Make output structure to save --- %
pd.dft = dft;
pd.FT = FT; 
pd.reg_img = reg_img;
pd.labNames = dca.labNames;
pd.eeg.data = EEG; 
pd.eeg.tv = tv; % time vector for EEG
