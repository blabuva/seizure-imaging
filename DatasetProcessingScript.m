%% 1 Convert to .imgbin
filename = ''; % full filepath to object
dcimgToBin(filename);

%% Manually map points on image to dorsal cortex atlas
img_file = '/media/scott3X/SI_Data/Sakina Gria x GCaMP_server/20240930/20240930_22800001.imgbin'; 
load('dorsalCortexAtlas.mat','dca');
% img_file = 'V:\SI_Data\Sakina Gria x GCaMP_server\20240930\20240930_22800001.imgbin';
% brain_img = imread('/media/scottX/Random/SI_017_20230209_BrightnessEnhanced.png');
img = imgbinRead(img_file);     % read in the imaging data
frame1 = img.Data.frames(:,:,1);
brain_img = im2uint8(frame1);% atlas_img = imread('atlas_noOB_binary.png');
% brain_img = imread('Z:\Random\SI_017_20230209_BrightnessEnhanced.png');
% cph = cpselect(atlas_img,brain_img);
cph = cpselect(label2rgb(dca.labs),brain_img);

%% Apply image morphing to register image to atlas
% reg_img = imageMorphing(brain_img,atlas_img,fixedPoints,movingPoints);
reg_img = imageMorphing(brain_img,dca.labs,fixedPoints,movingPoints);

%% Load imaging data into workspace and reshape it for filtering below
sz = size(img.Data.frames);
mtx = reshape(img.Data.frames, sz(1)*sz(2),sz(3))'; % linearize pixels

%% Apply dF/F function and reshape data back into height x width x frames shape
Fs = 10; % sampling frequency (Hz)
dff = pixelFilter(mtx,25,.1);
dff = reshape(dff',ysz,xsz,zsz);        % reshape the imaging matrix back into (height x width x # of frames)

%% Segment image into separate cortical areas
% Iteration starts at 2 because 1 is 'root' (i.e. no brain region assigned)
% for ii = 2:numel(dca.labNames)
%     cmask = reg_img==ii; % current image mask
%     dft(ii,:) = cframe(cmask,:); % dF/F trace 
% end
%% 