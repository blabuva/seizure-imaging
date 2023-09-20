function motionCorrect(frames,varargin)
%% motionCorrect Perform motion correction and save as .mc files
%
% INPUTS:
%   frames (required) - a 3-D matrix where dimensions 1 & 2 are height and width, respectively. 3rd dimension is frame number
%
%   -----------------Name-Value-Pairs (Optional)----------------   %
%   Name: 'name1'     Value: Description of value including default (default = NaN)
%   Name: 'name2'     Value: Description of value including default (default = NaN)
%   Name: 'name3'     Value: Description of value including default (default = NaN)
%   ------------------------------------------------------------   %
%
% OUTPUTS:
%   NONE - but saves a .mc file with the motion corrected data
%
% Written by Scott Kilianski
% Updated on 8/29/2023
%   ------------------------------------------------------------   %
%% ---- Handle data ---- %%%
Y = single(frames);                 % convert to single precision 
T = size(Y,ndims(Y));
Y = Y - min(Y(:));

%% Non-rigid motion correction
options_nonrigid = NoRMCorreSetParms('d1',size(Y,1),'d2',size(Y,2),...
    'grid_size',[32,32],'mot_uf',4,'bin_width',200,'max_shift',25,...
    'max_dev',3,'us_fac',50,'init_batch',200);
tic; 
[M2,shifts2,template2,options_nonrigid] = normcorre_batch(Y,options_nonrigid); 
toc

%% Save to output data
foutID = fopen(foutN,'w');                                % fopen the fout file
[imgHeight, imgWidth, nof] = size(M2);
fwrite(foutID,nof,'int32','l');                           % write total number of frames as int32
fwrite(foutID,imgWidth,'int32','l');                      % write Width as int32
fwrite(foutID,imgHeight,'int32','l');                     % write Height as int32
fwrite(foutID,uint16(M2),'uint16','l');
fclose(foutID);

end % function end