%% for calling helper functions
addpath('\\bmi-nas-01\Contreras-UH\Infantdata\Infantdata\code\Zachs_Infant_decoding_files')
% addpath(genpath('C:\Users\zrhernan\Documents\MATLAB\fieldtrip'))

%% Generate List of Infant Data Folders
InfantDir = '\\172.27.216.40\Contreras-UH\Infantdata\Infantdata\Data\';
disp_flag = 0;
[InfantDataAnnotList,InfantID] = defineInfantFolders(InfantDir,disp_flag);

%%
freq = cell(1,length(InfantID));
freq_avg = cell(1,length(InfantID));
for ii=1:length(InfantID)
    disp('==================================================')
    disp('==================================================')
    disp('==================================================')
    disp('==================================================')
    disp(['Opening Opals recording of subject ',InfantID{ii}])
    disp([num2str((ii*100)/length(InfantID)),'% of subjects done.'])
    
    if any(ismember(InfantID{ii},{'HD14','N09'})), continue, end
    infantfolder = InfantDataAnnotList{ii};
    serverPath1 = [InfantDir,infantfolder,'\Kinematics\'];
    cd(serverPath1)
    %% load FT structure data
    fullFileName = 'resampled500HzKINEtrl.mat';
    if exist(fullFileName, 'file')
        disp([fullFileName,' exists. Loading file...'])
        load(fullFileName)
    else
        disp([fullFileName,' does not exist. Skipping to next subject...'])
        continue
    end
    % dClass = uh_classextract(datakineTrlresamp);
    d = datakineTrlresamp;  %dClass{2};
    %% Perform frequency analysis
    cfg              = [];
    cfg.output       = 'pow';
    cfg.channel      = d.label;
    cfg.keeptrials   = 'yes';
    cfg.method       = 'mtmfft';
    cfg.taper = 'dpss';
    cfg.foi          = 0.001:0.01:15;
    % cfg.toi = min(d.time{1}):0.01:max(d.time{1}); % time window "slides" from -start to end sec in steps of 0.1 msec (10 ms)
    % cfg.t_ftimwin= ones(length(cfg.foi))*0.2;  % length of time window fixed at 0.2 sec
    cfg.tapsmofrq = ones(length(cfg.foi),2).*1; % spectral smoothing = +/- 2 Hz
    cfg.pad = 'maxperlen';
    freq{ii}   = ft_freqanalysis(cfg, d);    
    %% Extract frequency discriptives
    cfg = [];
    cfg.variance = 'yes';
    freq_avg{ii} = ft_freqdescriptives(cfg,freq{ii});
end
%% Grand average
cfg = [];
freqavg = ft_freqgrandaverage(cfg,freq_avg{~cellfun(@isempty,freq_avg)});

%% Calculate Variance per sensor
cfg=[];
cfg.variance = 'yes';
freqvar = ft_freqdescriptives(cfg,freqavg);
%%
sbjIDX = find(~cellfun(@isempty,freq_avg));
sbjcntr = 1;
for sbj=sbjIDX
    
    sbjcntr = sbjcntr + 1;
end
%% Prepare a Layout
%{
cfg = [];
cfg.image = 'IMUsensorLayout.png';
cfg.layout = 'IMUsensorLayout.mat';
ft_layoutplot(cfg);
lay = ft_prepare_layout(cfg);
save IMUsensorLayout.mat lay
%}
%% Visualize the data using IMU topoplot
cfg = [];
cfg.parameter = 'powspctrm';
% cfg.image = 'IMUsensorLayout.png';
cfg.layout = 'IMUsensorLayout.mat';
cfg.hlim = [0 6];
% cfg.vlim = [0.00104 0.2];
cfg.showlabels    = 'yes';
ft_singleplotER(cfg, freqavg);

%% 
myfig = figure(33);
IMUlabels = freq_avg{1}.label;
agelist = zeros(length(InfantID),1);
colorlist = {'r','b','g','m','k'};
for ii=1:length(InfantID)
    if isempty(freq_avg{ii}), continue, end
    agelist(ii) = str2double(cellstr(InfantID{ii}(regexp(InfantID{ii},'\d'))));
    switch agelist(ii)
        case 6
            selectedcolor = colorlist{1};
        case {7,8,9}
            selectedcolor = colorlist{2};
        case {10,11,12}
            selectedcolor = colorlist{3};
        case {13,14,15,16,17,18}
            selectedcolor = colorlist{4};
        case {19,20,21,22,23,24}
            selectedcolor = colorlist{5};
    end

    for jj = 1:length(IMUlabels)
        subplot(6,3,jj)
        IMUidx = find(strcmp(freq_avg{ii}.label,IMUlabels{jj})==1);
        if isempty(IMUidx),continue,end

        shadedErrorBar(freq_avg{ii}.freq,freq_avg{ii}.powspctrm(IMUidx,:),freq_avg{ii}.powspctrmsem(IMUidx,:),selectedcolor,1)
        if jj==1,title('X-component'),end
        if jj==2,title('Y-component'),end
        if jj==3,title('Z-component'),end
        if ~mod(jj-1,3),ylabel(IMUlabels{jj}(1:end-6),'rotation',45,'horizontalalignment','right'),end
        hold on
    end
    clear selectedcolor
end

%% add legend
myfig=figure(99);
rect_x = (0.18:0.15:0.78);
text_x = [rect_x(1)-0.055 rect_x(2)-0.060 rect_x(3:5)-0.066];

rect_pos = {    [0.24 0.02 0.05 0.01]...
                [0.36 0.02 0.05 0.01]...
                [0.49 0.02 0.05 0.01]...
                [0.62 0.02 0.05 0.01]...
                [0.75 0.02 0.05 0.01]   };
rect_clr = {    [1 0 0]...
                [0 0 1]...
                [0 1 0]...
                [1 0 1]...
                [0 0 0]};
            
text_pos = {    [0.196 0.02 0.06 0.01]...
                [0.307 0.02 0.06 0.01]...
                [0.422 0.02 0.07 0.01]...
                [0.554 0.02 0.07 0.01]...
                [0.684 0.02 0.07 0.01]   };
text_str = {    '6 mo.'...
                '7-9 mo.'...
                '10-12 mo.'...
                '13-18 mo.'...
                '19-24 mo.'   };
    
for behvrs = 1:5
    % Create rectangle
annotation(myfig,'rectangle',[rect_x(behvrs) 0.02 0.05 0.01],...%rect_pos{behvrs}...
    'LineStyle','none',...
    'FaceColor',rect_clr{behvrs},...
    'Units','Normalized');

    % Create textbox
annotation(myfig,'textbox',[text_x(behvrs) 0.02 0.07 0.01],...%text_pos{behvrs},...
    'String',text_str{behvrs},...
    'LineStyle','none',...
    'HorizontalAlignment','center',...
    'VerticalAlignment','middle',...
    'FitBoxToText','off',...
    'Units','Normalized');
end
  
%%
filename = 'trialAvgPSDsbyAgeandIMUsensor.png';
cd(cd('\\bmi-nas-01\Contreras-UH\Infantdata\Infantdata\code\histogramstodetectoutliersmaxacc'))
print(myfig,'-dpng', filename, '-r600')