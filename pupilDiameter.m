pathToFile = 'X:\PSR_Data\PSR_21\PSR_21_Rec3_231020_115805\eyeIM.mat';
load(pathToFile, 'eyeIM');
rMin = 8;
rMax = 25;
circSensitivity = .85;

%%

% Initialize image
eyeFig = figure;
MIPimage = imshow(min(eyeIM,[],3));
title('Draw circle over pupil here. Hit ENTER to proceed.')
uCircle = drawcircle;

% Wait for user to draw pupil
while ~strcmp('return',eyeFig.CurrentKey)
    pupCen = uCircle.Center;
    pupRad = uCircle.Radius;
    imMask = uint8(createMask(uCircle));
    waitforbuttonpress
end
close(eyeFig);

%%
circle_cxy = zeros(size(eyeIM,3),2);    % intialize circle centers matrix (# images, XY positions)
circle_radii = zeros(size(eyeIM,3),1);  % initialize circle radii vector (# images)

%% --- Set up plots --- %
figure;
rawAX = subplot(2,3,1);
enAX = subplot(2,3,4);
physAX = subplot(2,3,2:3);
title('Physiology Here');
pupildAX = subplot(2,3,5:6);
title('Pupil Data Here');
diamLine = plot(pupildAX,0,'r',"LineWidth",1.5);
hold on
yyaxis right
moveLine = plot(pupildAX,0,'k',"LineWidth",1.5);
hold off

%%
axes(rawAX);
eyeImage=imagesc(rawAX,eyeIM(:,:,1)); % initialize the eye image
colormap(gray);

% ------ Image Enhancement ------ %
sigma = .25;
se = strel('disk', 2);

% img = histeq(img);
% BW = imbinarize(img, 'adaptive', 'ForegroundPolarity', 'dark', 'Sensitivity', 0.99);
enIm = imgaussfilt(eyeIM(:,:,1), sigma);
enIm = uint8(255)-enIm;
enIm = imerode(enIm, se);
enIm = imdilate(enIm, se);
% level = graythresh(img);
% BW = imbinarize(img, 150);
enIm = enIm.*imMask;
enImage = imagesc(enAX,enIm);
colormap(gray);
% enImage = double(eyeIM(:,:,1));
[circcen, radi] = imfindcircles(enIm,[rMin rMax], ...
    'ObjectPolarity','bright', ...
    'Sensitivity', circSensitivity);
visc = viscircles(rawAX,circcen,radi,...
    'color','r','LineStyle','--');
visc2 = viscircles([],[]);
regCircles = viscircles([],[]);
mThresh = 8;

%% ------ Processing Loop ------ %
for eyei = 1:57000%size(eyeIM,3)
    delete(visc);
    delete(visc2);
    delete(regCircles);
    set(eyeImage,'CData',eyeIM(:,:,eyei));
    enIm = imgaussfilt(eyeIM(:,:,eyei), sigma);
    enIm = imerode(enIm, se);
    enIm = imdilate(enIm, se);
    enIm = uint8(255)-enIm;
    enIm = enIm .*imMask;
    % BW = imbinarize(enIm,'adaptive');
    thresh = multithresh(enIm,mThresh);
    labels = imquantize(enIm,thresh);
    BWen = imbinarize(labels,mThresh-1);
    % BWen = imdilate(BW, se);
    % figure; imshow(label2rgb(labels));
    set(enImage,'CData',BWen);
    % [circcen, radi] = imfindcircles(BWen,[rMin rMax], ...
    %     'ObjectPolarity','bright', ...
    %     'Sensitivity', circSensitivity);
    % [radi, Sind] = sort(radi,'descend');
    % circcen = circcen(Sind,:);
    stats = regionprops("table",BWen,"Centroid", ...
        "MajorAxisLength","MinorAxisLength","Area");
    [~,maxBlobInd] = max(stats.Area);

    if isempty(maxBlobInd)
        circle_cxy(eyei,:) = [NaN,NaN];
        circle_radii(eyei,1) = NaN;
        title(rawAX,sprintf('Image # %d, radius: None',...
            eyei));
    else
        for ci = 1:numel(radi)
            if sqrt(sum([pupCen - circcen(ci,:)].^2)) < pupRad % check if auto-detected circle center is within user-defined circle
                circle_cxy(eyei,:) = circcen(ci,:);
                circle_radii(eyei,1) = radi(ci);
                % visc = viscircles(rawAX,circle_cxy(eyei,:),circle_radii(eyei,1),...
                % 'color','r','LineStyle','--');
                % visc2 = viscircles(enAX,circle_cxy(eyei,:),circle_radii(eyei,1),...
                % 'color','r','LineStyle','--');
                title(rawAX,sprintf('Image # %d, radius: %.2f',...
                    eyei,radi(ci)));

                % --- Try with regionprops --- %
                stats = table2array(stats);
                centers = stats(maxBlobInd,2:3);
                diameters = mean([stats(maxBlobInd,4) stats(maxBlobInd,5)]);
                radii = diameters/2;
                regCircles = viscircles(rawAX,centers,radii,...
                    'Color','g');

                break
            end
        end
    end
    drawnow;
    pause(0.025);
end