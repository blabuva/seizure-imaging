%% --- 0 Input files --- %%
% topDir = 'X:\SI_Data\Sakina Gria x GCaMP_server\20250227_GriaxGCaMP\273\';
topDir = uigetdir;
dd = dir(topDir);
fnames = {dd.name};
dcimg_file = fullfile(topDir,dd(contains(fnames,'.dcimg')).name);
eeg_filename= fullfile(topDir,dd(contains(fnames,'.abf')).name);
img_file= fullfile(topDir,dd(contains(fnames,'.imgbin')).name);
% dcimg_file = 'X:\SI_Data\Sakina Gria x GCaMP_server\20250227_GriaxGCaMP\273\20250227_27300002.dcimg';
% % eeg_filename = '/media/scott3X/SI_Data/Sakina Gria x GCaMP_server/20241126/20241126_251_0001.abf'; 
% eeg_filename = 'X:\SI_Data\Sakina Gria x GCaMP_server\20250227_GriaxGCaMP\273\20250227_273_0000.abf';
% img_file = 'X:\SI_Data\Sakina Gria x GCaMP_server\20250227_GriaxGCaMP\273\20250227_27300002.imgbin'; 
% pointsFile = '/media/scott3X/SI_Data/Sakina Gria x GCaMP_server/20241002/20241002_230_mappedPoints.m';
% tlimFile = 'X:\SI_Data\Sakina Gria x GCaMP_server\20250227_GriaxGCaMP\273\tlim.mat';

%% --- Get time limits for imaging epoch --- %% 
tlim = pick_tlims(eeg_filename); 

%%
load(fullfile(topDir,'tlim.mat'),'tlim');
hdcimg = dcimgmex('open',dcimg_file);                     % open the original .dcimg file
nof = dcimgmex('getparam',hdcimg,'NUMBEROF_FRAME');     % retrieve the total number of frames in the session
dcimgmex('close',hdcimg);

[FT, FS, EEG, tv] = getFrameTimes(eeg_filename,nof,tlim);

%% --- 2 Convert to .imgbin --- %%
% === THIS CAN ONLY BE DONE ON WINDOWS OS === %
dcimgToBin(dcimg_file);

%% --- 2.5 temporary, motion correct the image series --- %%
img = imgbinRead(img_file);             % read in the imaging data

Y = single(img.Data.frames);                 % convert to single precision 
siz = size(img.Data.frames);
Y = Y - min(Y(:));                          % baseline (minimum) subtraction
%%
% set parameters
options_rigid = NoRMCorreSetParms('d1',siz(1),'d2',siz(2),'bin_width',200,'max_shift',15,'us_fac',50,'init_batch',200);
% perform motion correction - rigid
tic; [M1,shifts1,template1,options_rigid] = normcorre_mm(Y,options_rigid); toc
clear Y % to save on memory
save(fullfile(topDir,'template.mat'),'template1','-v7.3');

%% --- 3 Manually map points on image to dorsal cortex atlas --- %%
load('dorsalCortexAtlas.mat','dca');    % load the atlas data
img = imgbinRead(img_file);             % read in the imaging data
frame1 = img.Data.frames(:,:,1);        % get the first frame
brain_img = im2uint8(frame1);           % convert to uint8 for morphing
brain_img = rot90(brain_img,2);         % rotate 180degrees so it's anterior-poster from top-bottom
% --- convert first frame to uint8 --- % 
% brain_img = M1(:,:,1);
% brain_img = template1; 
% A_norm = brain_img - min(brain_img(:));
% A_norm = A_norm / max(A_norm(:));
% brain_img = uint8(A_norm * 255);

topClim = 50;
img_scaled = brain_img * (255 / topClim);

% Clip any potential out-of-bounds values (optional safety)
img_scaled = min(max(img_scaled, 0), 255);

% Convert back to uint8 if needed
img_uint8 = uint8(round(img_scaled));

% brain_img = im2uint8(M1(:,:,1));
% brain_img = M1(:,:,1); % -- DO I NEED TO CONVERT TO UINT8 SOMEHOW????
cph = cpselect(label2rgb(dca.labs),...
    img_rotated);                         % select matching points in image and atlas

%% --- 4 Apply image morphing to register image to atlas --- %%
% load(pointsFile,'fixedPoints','movingPoints');
reg_img = imageMorphing(rot90(brain_img,2),dca.labs,fixedPoints,movingPoints);
reg_img = rot90(reg_img, 2); % rotating back to original orientation

%% --- 5 Generate dF/F trace for all pixels --- %%
sz = size(img.Data.frames); 
% sz = size(M1);

% -- Load imaging data into workspace and reshape it for filtering below -- %
mtx = reshape(img.Data.frames, sz(1)*sz(2),sz(3))'; % linearize pixels
% mtx = reshape(M1, sz(1)*sz(2),sz(3))'; % linearize pixels
% --------------------------------------------------------------------------%

% [FT, Fs, EEG, tv] = getFrameTimes(eeg_filename,sz(3),tlim); % get frame times and Fs
lowPass = .1; % low pass frequency (Hz)
dff = pixelFilter(mtx,FS,lowPass);       % Apply dF/F function
dff = reshape(dff',sz(1),sz(2),sz(3));    % reshape the imaging matrix back into (height x width x # of frames)

%% --- 6 Use registered image as mask to segment image series into discrete regions --- %%
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
