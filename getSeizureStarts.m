function x = getSeizureStarts(x)
%%
% INPUTS:
% x is seizures
%
% Written by Scott Kilianski
% Updated 1/10/2023

%% Function body here
fs = x(1).parameters{2,5}; %sampling frequency
lookBackWindow = 0.1; %seconds prior to 1st trough to search for seizure start time
lbi = fs*lookBackWindow; %lookback index

% figure;
% szax(1) = subplot(3,1,1);
% szax(2) = subplot(3,1,2);
% szax(3) = subplot(3,1,3);
% linkaxes(szax,'x');
for ki = 1:numel(x)
    if isempty(x(ki).trTimeInds)
        x(ki).trTimeInds = [];
        continue
    end
    %-----------------%
    pszi = [x(ki).trTimeInds(1)-lbi:x(ki).trTimeInds(1)]; %indices to pre-seizure period
%     xtime = x(ki).time(pszi);
    xeeg = x(ki).EEG(pszi);
    [~,inflPoint] = min(diff(xeeg,2));                % threshold for the inflection point
%     inflPoint = find(diff(xeeg,2)==inflThresh,1,'first');  % find the first point 2nd derivative to find change
    inflInd = x(ki).trTimeInds(1)-(lbi-inflPoint);                    % get the corresponding index
    x(ki).startTime = x(ki).time(inflInd);
%     plot(szax(1),xtime,xeeg,'k','linewidth',1.5); szax(1).Title.String = 'Raw EEG';
%     xtime(end) = [];
%     plot(szax(2),xtime,diff(xeeg,1),'k','linewidth',1.5); szax(2).Title.String = '1st derivative';
%     xtime(end) = [];
%     plot(szax(3),xtime,diff(xeeg,2),'k','linewidth',1.5); szax(3).Title.String = '2nd derivative';
%     axes(szax(1)); hold on
%     scatter(x(ki).time(inflInd),x(ki).EEG(inflInd),72,'green','filled','MarkerFaceAlpha',.75);
%     hold off
    %-----------------%
end

end %function end
