%% A script to process ECoG + imaging data from start to finish
% This code can be adjusted for many different parameters and include
% different analyses

%% Step 0
% Create dataset structure wherein information about the dataset will be stored
dsDir = uigetdir;
DS = struct;
save(fullfile(dsDir,'DS_struct.mat'),"DS",'-v7.3');

%% Step 1
% Convert .dcimg files to .imgbin files
% Conversion to .imgbin is necessary to work with data on Linux systems
% As such, this step can only be done on Windows systems


%% Dropped frame check

%% Step 2 - Motion correction
[fn,fp] = uigetfile('*.imgbin'); % UI to select .imgbin file
filename = fullfile(fp,fn);     % append to make full file path
img = imgbinRead(filename);     % read in the imaging data
nm470 = img.Data.frames(:,:,1:2:end);


%% USE ALL FRAMES OR EVERY OTHER
% SUBTRACT HEMODYNAMIC RESPONSE??
diffImage = double(nm470) - mean(nm470,3);
diffZero = max(diffImage,0);
divImage = (diffZero ./ mean(nm470,3));
finalMin = min(divImage(:));
finalMax = max(divImage(:));

%% SEGEMENT INTO DIFFERENT CORTICAL REGIONS???

%% MAKE MOVIES???
figure;
imgax = axes;
frameN = 2;
x = imagesc(flipud(divImage(:,:,frameN)));
imgax.CLim = [finalMin finalMax];
imgax.CLim = [0 .15];
imgax.Colormap = colormap(gray);
fhShape = drawfreehand;
msk = fhShape.createMask();
%% DO CORRELATIONS??
frameN = frameN + 1;

% bulk_dfTrace = squeeze(sum(divImage.*msk,[1 2]));
x.CData = flipud(divImage(:,:,frameN)).*msk;
imgax.Title.String = sprintf('Frame %d',frameN);

%%
fhShape = drawfreehand;