%%
[fn,fp,rv] = uigetfile('*.adicht;*.abf');
[~,~,fext] = fileparts(fn);

%% Loading file
if strcmp(fext,'.abf')
    [d, si] = abf2load(fullfile(fp,fn));
    dt = si * 10^-6; % convert time interval from microseconds to seconds
    time = (0:size(d,1)-1)*dt; %create time vector
    data = d(:,1);
elseif strcmp(fext,'.adicht')
    re = adiLoadEEG(filename,1,20000); % rotary encoder information
    data = re.data;
    time = re.time;
else
    error(['The file you selected does not have a .abf or .adicht ' ...
        'extension. This function only works with files that do.']);
end
lfp = [time',data];

%%
rng = [0 300];
step = .5;
[spectrogram,t,f] = MTSpectrogram(lfp,...
    'range',rng,'step',step);
figure;
% spectrogram = log(spectrogram);
I = imagesc(t,f,spectrogram);
set(gca,'ydir','normal');
colormap(jet);