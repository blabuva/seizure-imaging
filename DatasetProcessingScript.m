%% 1 Convert to .imgbin
filename = ''; % full filepath to object
dcimgToBin(filename);

%% 2 Image registration and segmentation
% img_file = '/media/scott3X/SI_Data/Sakina Gria x GCaMP_server/20240930/20240930_22800001.imgbin'; 
img_file = 'V:\SI_Data\Sakina Gria x GCaMP_server\20240930\20240930_22800001.imgbin';
% brain_img = imread('/media/scottX/Random/SI_017_20230209_BrightnessEnhanced.png');
img = imgbinRead(img_file);     % read in the imaging data
frame1 = img.Data.frames(:,:,1);
brain_img = im2uint8(frame1);
atlas_img = imread('atlas_noOB_binary.png');
% brain_img = imread('Z:\Random\SI_017_20230209_BrightnessEnhanced.png');
cph = cpselect(atlas_img,brain_img);

%% 2.1 
reg_img = imageMorphing(brain_img,atlas_img,fixedPoints,movingPoints);

%% 3. 
imshow(reg_img)