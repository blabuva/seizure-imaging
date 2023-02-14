%%
vfn = 'C:\Users\Scott\Desktop\testVid.avi';
writerObj  = VideoWriter(vfn);
writerObj.FrameRate = 5; % frame rate
open(writerObj);

%%
filepath = 'Y:\Cortical_Spreading_Depression\20230210\SKP24_2023021000001.imgbin';
img = imgbinRead(filepath);
%%
imageFig = figure; 
baseFrame = flipud(img.Data.frames(:,:,1));
baseImage = image(baseFrame,'CDataMapping','scaled');
colormap(gray);
clim([0 6000]);
hold on
ovFrame = repmat(zeros(size(baseFrame)),1,1,3); % set up current frame to be plotted
plotColorChan = 2; % color channel to display changes in (1=red, 2=green, 3=blue)
ovImage = image(ovFrame,'AlphaData',ovFrame(:,:,plotColorChan));
img_txt = text(1600,200,'0','color','w','FontSize',24);

%% Loop
% cf = 500;
for cf = 500:25:1600
ovFrame(:,:,plotColorChan) = flipud(img.Data.frames(:,:,cf));
ovFrame = ovFrame./max(ovFrame,[],'all');
% cf_AlphaData = flipud(img.Data.frames(:,:,cf));
% ovImage.CData = ;
% ovImage.AlphaData = cf_AlphaData./max(cf_AlphaData,[],'all');
% y = image(colorFrame,'AlphaData',ovFrame(:,:,plotColorChan));
% ovImage = image(ovFrame,'AlphaData',ovFrame(:,:,2));
set(ovImage,'CData',ovFrame,'AlphaData',ovFrame(:,:,plotColorChan));
set(img_txt,'String',sprintf('%.1f',cf/10));
drawnow;
F = getframe(imageFig);
writeVideo(writerObj, F);
disp(cf);
end
close(writerObj);



