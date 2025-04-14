%% Peri-seizure time histogram
szfn = 'X:\SI_Data\Sakina Gria x GCaMP_server\20250205\20250205_283_0000_Ch01_seizures_curated_20250410_19_44_58.mat'; % path to seizure file
pdfn = 'X:\SI_Data\Sakina Gria x GCaMP_server\20250205\20250205_283_pd.mat'; % path to processed imaging data file

load(szfn,'seizures');
load(pdfn,'pd');
%%
sz = seizures; 
rmLog = strcmp({sz.type},'3');
sz(rmLog) = [];

%%
ppInt = 2; %pre/post interval to look (seconds)
FTfs = 10; % camera sampling frequency
idxInt = ppInt*FTfs; % number of samples to look ahead or behind

for szi = 1:numel(sz)
    szStart = sz(szi).time(sz(szi).trTimeInds(1));
    szEnd = sz(szi).time(sz(szi).trTimeInds(end));
    f1 = find(pd.FT>szStart,1,'first');
    f2 = find(pd.FT<szEnd,1,'last');
    meanF(:,szi) = mean(pd.dft(:,f1:f2),2);

    pre1 = f1-1-idxInt; 
    pre2 = f1-1;
    preMeanF(:,szi) = mean(pd.dft(:,pre1:pre2),2);
    post1 = f2 +1;
    post2 = f2+1+idxInt;
    postMeanF(:,szi) = mean(pd.dft(:,post1:post2),2);
end
