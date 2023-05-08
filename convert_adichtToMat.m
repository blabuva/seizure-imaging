function [d, dt] = convert_adichtToMat(varargin)
%% convert_adichtToMat Brief description of function
%
% INPUTS:
%   filepath (optional) - full filepath (including .adicht extension) in string format
%
% OUTPUTS:
%   d - Data matrix. Each 
%   dt - sampling interval
% Written by Scott Kilianski
% Updated on 4/18/2023

%   ------------------------------------------------------------   %
%% ---- Function Body Here ---- %%%
if nargin < 1
    [fn,fp] = uigetfile('*.adicht');    % UI to select data
    [~,fn,fext] = fileparts(fullfile(fp,fn));
else
    [fp,fn,fext] = fileparts(varargin{1});
end
if ~strcmp(fext,'.adicht')
    error('Wrong file type. Use .adicht files only');
end
ad = adi.readFile(fullfile(fp,[fn,fext]));     % loads .adicht files
dt = ad.records(end).tick_dt;           % samling interval 
rc = numel(ad.records);                 % records
recLen = ad.records(end).n_ticks;       % recording length (in # of samples)
d = zeros(recLen,ad.n_channels);        % data matrix
for nc = 1:ad.n_channels
    d(:,nc) = ad.getChannelData((nc),rc)';  % get each channel of data and store in matrix
end
outFile = sprintf('%s%s%s.m',fp,'\',fn);
fprintf('Saving output to %s...\n',outFile);
save(outFile,'d','dt','-v7.3');
end % function end