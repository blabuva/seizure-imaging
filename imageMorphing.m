function reg_img = imageMorphing(brain_img, atlas_img, fixedPoints, movingPoints)
%%
% atlas_img = imread('atlas_noOB_binary.png');
% brain_img = imread('Z:\Random\SI_017_20230209_BrightnessEnhanced.png');
% brain_img = im2uint8(brain_img);
% cph = cpselect(atlas_img,brain_img);

%%
source_pts = fixedPoints;
target_pts = movingPoints;
%%
% Compute the TPS transformation
[D, C] = size(brain_img);
tps = tpaps(source_pts', target_pts', 1);

% Create a grid of points in the new image
[X, Y] = meshgrid(1:C, 1:D);
new_pts = [X(:) Y(:)];

% Apply the TPS transformation to the new points
warped_pts = fnval(tps, new_pts');

% Reshape the warped points into a grid
U = reshape(warped_pts(1,:), [D, C]);
V = reshape(warped_pts(2,:), [D, C]);

% Use Matlab's built-in function to warp the original image
reg_img = interp2(single(atlas_img), U, V,'nearest');
reg_img(isnan(reg_img)) = 1; % set all unmorphed regions to 1 (i.e. root label)

%%
figure;
I1 = imagesc(brain_img);
colormap(gray);
hold on
I2 = imagesc(label2rgb(reg_img));
I2.AlphaData = 0.25;