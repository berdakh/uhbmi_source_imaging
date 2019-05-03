function output = uh_freqStat(d,plot,statmethod,foi,method)
% Perform time-frequency analysis and identify relative power changes with
% respect to the pre-defined baseline (this could also be considered as
% ERD/ERS.
%% output freq contains the following fields
%
%         label: {464x1 cell}         % Channel names
%        dimord: 'chan_freq_time'     % Dimensions contained in powspctrm, channels X frequencies X time
%          freq: [1x40 double]        % Array of frequencies of interest (the elements of freq may be different from your cfg.foi input depending on your trial length)
%          time: [1x26 double]        % Array of time points considered
%     powspctrm: [464x40x26 double]   % 3-D matrix containing the power values
%          grad: [1x1 struct]         % Gradiometer positions etc
%          elec: [1x1 struct]         % Electrode positions etc <fixme>
%           cfg: [1x1 struct]         % Settings used in computing this frequency decomposition

% The field freq.powspctrm contains the temporal evolution of the raw power values for each specified frequency in the left response conditions.

% To visualize the event-related power changes, a normalization with respect to a baseline interval will be performed.
%There are two possibilities for normalizing:

% (a) subtracting, for each frequency, the average power in a baseline interval from all
% other power values. This gives, for each frequency, the absolute change in power
% with respect to the baseline interval.

%(b) expressing, for each frequency,
% the raw power values as the relative increase or decrease with respect
% to the power in the baseline interval. This means active period/baseline.
% Note that the relative baseline is expressed as a ratio; i.e. no change is represented by 1.
%%
if ~exist('foi','var')
    foi = 6:0.1:9;
end
if ~exist('statmethod','var')
    statmethod = 'montecarlo';
end
if ~exist('plot','var')
    plot = 0;
end
if ~exist('method','var')
    method = 'wavelet';
end
%%
cfg = [];
cfg.toilim = [min(d.time{1}) -0.1];
dPre = ft_redefinetrial(cfg, d); % extract preTrigger baseline 
cfg.toilim = [0 max(d.time{1}-0.09)];
dPost = ft_redefinetrial(cfg, d); % extract postTrigger (activation)
dPre.time = dPost.time; 
%% Single-trial time-frequency response analysis for statistical test 
% cfg           = [];
% cfg.keeptrials   = 'yes';  % keep the TFR on individual trials
% cfg.output    = 'pow';
% cfg.method    = 'mtmconvol';
% cfg.taper     = 'hanning';
% cfg.toi       = min(dPre.time{1}):0.1:max(dPre.time{1}); % time window "slides" from -start to end sec in steps of 0.1 msec (10 ms)
% cfg.foi          = foi(1):0.1:foi(2);
% timewindow = ones(size(cfg.foi))*0.5;  % length of time window fixed at 0.5 sec
% cfg.t_ftimwin= timewindow;
% freqPre      = ft_freqanalysis(cfg, dPre);
% freqPost     = ft_freqanalysis(cfg, dPost);
if strcmp('multitaper',method)
    cfg              = [];
    cfg.output       = 'pow';
    cfg.channel      = 'all';
    cfg.keeptrials   = 'yes';
    cfg.method       = 'mtmconvol';
    cfg.taper        = 'hanning';
    cfg.foi          = foi(1):0.1:foi(2);
    timewindow = ones(size(cfg.foi))*0.5;  % length of time window fixed at 0.5 sec
    cfg.t_ftimwin= timewindow;
    cfg.toi = min(dPre.time{1}):0.1:max(dPre.time{1}); % time window "slides" from -start to end sec in steps of 0.1 msec (10 ms)
    freqPre      = ft_freqanalysis(cfg, dPre);
    freqPost     = ft_freqanalysis(cfg, dPost);
elseif strcmp('wavelet',method)
    %% Wavelets
    cfg = [];
    cfg.output = 'pow';
    cfg.channel = 'EEG';
    cfg.method = 'wavelet';
    cfg.keeptrials   = 'yes';
    cfg.foi   = foi(1):0.1:foi(2);
    timewindow = ones(size(cfg.foi))*0.5;  % length of time window fixed at 0.5 sec
    cfg.t_ftimwin= timewindow;
    cfg.tapsmofrq = cfg.foi*0.4;  
    cfg.toi = min(dPre.time{1}):0.2:max(dPre.time{1}); % time window "slides" from -start to end sec in steps of 0.1 msec (10 ms)
    freqPre      = ft_freqanalysis(cfg, dPre);
    freqPost     = ft_freqanalysis(cfg, dPost);
end
% % The following formula is used: ERSP = (Reference-Test)/Reference x 100.
% cfg           = [];
% cfg.parameter = 'powspctrm';
% cfg.operation = '(x1-x2)./x1';
% ERD = ft_math(cfg, freqPre,freqPost);

%% Log-transform the single-trial power
cfg           = [];
cfg.parameter = 'powspctrm';
cfg.operation = 'log10';
freqPre_logpow = ft_math(cfg, freqPre);
freqPost_logpow = ft_math(cfg, freqPost);

%% Compute the neighbours
cfg           = [];
cfg.channel   = 'EEG';
cfg.method    = 'triangulation';
cfg.elec      = freqPost.elec;
cfg.feedback  = 'no';
neighbours    = ft_prepare_neighbours(cfg);

%% Compute the statistics
cfg = [];
cfg.channel   = 'EEG';
cfg.statistic = 'indepsamplesT';
cfg.ivar      = 1;
cfg.design    = zeros(1, size(freqPost.trialinfo,1));
% design matrix
ntrials = size(freqPost.powspctrm,1);
design  = zeros(2,2*ntrials);
design(1,1:ntrials) = 1;
design(1,ntrials+1:2*ntrials) = 2;
design(2,1:ntrials) = [1:ntrials];
design(2,ntrials+1:2*ntrials) = [1:ntrials];
cfg.design   = design;

%%
if strcmp(statmethod,'bonferoni')
    cfg.method    = 'analytic';
    cfg.correctm  = 'bonferoni';
    stat = ft_freqstatistics(cfg, freqPre_logpow,freqPost_logpow);
elseif strcmp(statmethod,'fdr')
    cfg.method    = 'analytic';
    cfg.correctm  = 'fdr';
    stat = ft_freqstatistics(cfg, freqPre_logpow,freqPost_logpow);
elseif strcmp(statmethod,'montecarlo')
    cfg.method            = 'montecarlo';
    cfg.correctm          = 'cluster';
    cfg.numrandomization  = 500; % 1000 is recommended, but takes longer
    cfg.neighbours        = neighbours;
    stat = ft_freqstatistics(cfg, freqPre_logpow,freqPost_logpow);
end
%% prepare the output
output.freqPre = freqPre;
output.freqPost = freqPost;
output.stat = stat;
output.statmethod = statmethod;
%% Visualise the results
if plot
    load chan_label;
    %% stat grid plot
    figure(1);
    set(gcf,'units','normalized','outerposition',[0 0 1 1],'color','w'); % full screen
    for ii = 1:length(label)
        cfg               = [];
        cfg.marker        = 'on';
        cfg.layout = 'easycap_layout.mat';
        cfg.channel       = 'EEG';
        cfg.parameter     = 'stat';  % plot the t-value
        cfg.maskparameter = 'mask';  % use the thresholded probability to mask the data
        cfg.maskstyle     = 'saturation';
%         cfg.colormap = colormap(othercolor('PuBu8'));
        if ii == length(label)
            cfg.colorbar = 'no'; % change to 'yes'
            % cfg.colormap = colormap('gray');
        else
            cfg.colorbar = 'no';
        end
        cfg.channel = label{ii};
        [maxval, maxidx] = max(stat.stat(:));
        [minval, minidx] = min(stat.stat(:));
        cfg.zlim = [minval,maxval]; %'maxmin', 'maxabs', 'zeromax', 'minzero', or [zmin zmax] (default = 'maxmin')
        subplot(6,6,ii)
        ft_singleplotTFR(cfg, stat);
    end
    tightfig;
    print -dpng stat_freq.png
    %%
    %plot the average
%     figure(2);
%     set(gcf,'units','normalized','outerposition',[0 0 1 1],'color','w'); % full screen
%     cfg.channel = label;
% %     cfg.colorbar = 'yes';
%     ft_singleplotTFR(cfg, stat);
%     print -dpng stat_freq_avg.png
%     fprintf('Figures have been saved in the following directory: \n[%s]\n',pwd)
end