function pb = splitLFPpower(varargin)
%% splitLFPpower Brief description of function
%
% INPUTS:
%   ----------------------Name-Value-Pairs----------------------   %
%   Name: 'name1'     Value: Description of value including default (default = NaN)
%   Name: 'name2'     Value: Description of value including default (default = NaN)
%   Name: 'name3'     Value: Description of value including default (default = NaN)
%   ------------------------------------------------------------   %
%
% OUTPUTS:
%   output1 - Description of output variable
%
% Written by Author
% Updated on Current Date

%   ------------------------------------------------------------   %
%% ---- Parameters for this function ---- %%%
plotFlag = 0;
bl = [0.5 8];
bh = [100 500];
lfp = varargin{1};

%% ---- Parameters for spectrogram ---- %%%
rng = [0 300]; % frequency range
step = .5; % step size (in seconds)

%% ---- Parameters for spectrogram ---- %%%
[spectrogram,t,f] = MTSpectrogram(lfp,...
    'range',rng,'step',step);
bands = SpectrogramBands(spectrogram,f,'broadLow',bl,'highGamma',bh);
pb.time = t;
pb.low = bands.broadLow;
pb.high = bands.highGamma;

%%
if plotFlag
    figure;
    ax(1) = subplot(211);
    plot(pb.time,pb.low,'b');
    ax(2) = subplot(212);
    plot(pb.time,pb.high,'g');
    linkaxes(ax,'x');
    xlim('tight');
end


end % function end