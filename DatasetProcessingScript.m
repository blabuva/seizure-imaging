%% --- 0 Input files --- %%
dcimg_file = '/media/scott3X/SI_Data/Sakina Gria x GCaMP_server/20240930/20240930_22800001.dcimg';
eeg_filename = '/media/scott3X/SI_Data/Sakina Gria x GCaMP_server/20240930/20240930_228_0000.abf'; 
img_file = '/media/scott3X/SI_Data/Sakina Gria x GCaMP_server/20240930/20240930_22800001.imgbin'; 

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
reg_img = imageMorphing(brain_img,dca.labs,fixedPoints,movingPoints);

%% Load imaging data into workspace and reshape it for filtering below
sz = size(img.Data.frames);
mtx = reshape(img.Data.frames, sz(1)*sz(2),sz(3))'; % linearize pixels

%% Apply dF/F function and reshape data back into height x width x frames shape
Fs = 10; % sampling frequency (Hz)
dff = pixelFilter(mtx,Fs,.1);
dff = reshape(dff',ysz,xsz,zsz);        % reshape the imaging matrix back into (height x width x # of frames)

%% Segment image into separate cortical areas
% Iteration starts at 2 because 1 is 'root' (i.e. no brain region assigned)
% for ii = 2:numel(dca.labNames)
%     cmask = reg_img==ii; % current image mask
%     dft(ii,:) = cframe(cmask,:); % dF/F trace 
% end
%% 