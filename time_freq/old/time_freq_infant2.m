% We are often using the following approach
% -----------------------------------------------------------------------
% 1) Calculate time-frequency representations (TFRs) of power for planar
% gradients
% 2) Combined the planar gradient for each orientation
% 3) Average over subjects in sensors space
% 4) Use randomization statistics to identify clusters of difference
% 5) Use the beamformer to estimate power in source space for time and
% freq tiles identified in 4) in individual subjects
% 6) Morph the results of beamformed power to a standard brain
% 7) Average morphed power representations in source space
% -----------------------------------------------------------------------
% Time Frequency Analysis of Infant Data
d = uh_filter(datafinal,[6 9]);
dmu = uh_classextract(d);
% -----------------------------------------------------------------------
d = dmu{2};
%% divide data trials into pre and post stimulus (or onset of a behavior)
cfg = [];
cfg.toilim = [min(d.time{1}) -0.1];
d1 = ft_redefinetrial(cfg, d);

cfg = [];
cfg.toilim = [0 max(d.time{1}-0.09)];
d2 = ft_redefinetrial(cfg, d);
d1.time = d2.time;
% 
%%     30    58    13   134
% d = 
% 
%     sampleinfo: [30x2 double]
%      trialinfo: [30x1 double]
%           elec: [1x1 struct]
%        fsample: 1.0000e+03
%          trial: {1x30 cell}
%           time: {1x30 cell}
%          label: {58x1 cell}
%            cfg: [1x1 struct]
% 
% x = 
% 
%         label: {58x1 cell}
%                 trial-channel-freq-time 
%        dimord: 'rpt_chan_freq_time'
%          freq: [1x13 double]
%          time: [1x134 double]
%     powspctrm: [4-D double]
%     cumtapcnt: [30x13 double]
%          elec: [1x1 struct]
%     trialinfo: [30x1 double]
%           cfg: [1x1 struct]
%%
tmpcfg = [];
tmpcfg.channel = 'EEG';
tmpcfg.trials = 'all';
tmpcfg.output = 'pow';% 'powandcsd' is used instead of 'pow' for source analysis purposes
tmpcfg.method = 'mtmconvol';
tmpcfg.keeptrials = 'yes';
tmpcfg.taper = 'hanning';
tmpcfg.foi   = 6:1:9; % perform analysis around the mean frequency in the "foilim" band
% tmpcfg.t_ftimwin = ones(length(tmpcfg.foi),1).*0.5;   % length of time window = 0.5 sec
% tmpcfg.tapsmofrq = cfg.foilim(end) - tmpcfg.foilim(end);
tmpcfg.pad = 'maxperlen'; % this means the analysis will be performed in highest frequenct resolution possible according to trials length: 1/length(in sec)
tmpcfg.t_ftimwin = 4./tmpcfg.foi; % consider using cfg.foi instead. ###################### Consider changing 4
% tmpcfg.tapsmofrq =
% tmpcfg.t_ftimwin = 4 / cfg.foilim(end);
tmpcfg.toi = min(d.time{1}):0.1:max(d.time{1}); % time window "slides" from -0.1 to 0.5 sec in steps of 0.02 sec (20 ms)

freq1 = ft_freqanalysis(tmpcfg,d);
% freq2 = ft_freqanalysis(tmpcfg,d2);

%%
cfg = [];
% cfg.baseline     = [min(d.time{1}) -0.1];
cfg.channel ='all'; %{'Cz','Fp1'};
cfg.xlim          = [0.1 1.6];
% cfg.ylim = [15 20];
% cfg.zlim = [-1e-27 1e-27];
cfg.layout = 'easycap_layout.mat';
ft_multiplotTFR(cfg, freq2)

%%
cfg = [];
cfg.output = 'pow';
cfg.channel = 'EEG';
cfg.method = 'wavelet';
% cfg.taper = 'hanning';
% cfg.baseline     = [-2 -0.1];
% cfg.baselinetype = 'db';
cfg.width      = 6; %'width', or number of cycles, of the wavelet (default = 7)
cfg.foi = 6:0.5:9;
cfg.toi = min(d.time{1}):0.02:max(d.time{1}); % time window "slides" from -0.1 to 0.5 sec in steps of 0.02 sec (20 ms)
% cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.1;  % length of time window fixed at 0.5 sec
% cfg.tapsmofrq = cfg.foi*0.4;
% cfg.keeptrials = 'yes';
TFbaseline = ft_freqanalysis(cfg, d1);
TFactivation = ft_freqanalysis(cfg, d2);

%%
cfg = [];
% cfg.baseline     = [-0.5 -0.1];
% cfg.baselinetype = 'absolute';
% cfg.zlim         = 'maxabs';
% cfg.ylim=[1 40];
cfg.showlabels   = 'yes';
% cfg.shading = 'interp';
% cfg.zlim = 'minzero';
cfg.layout       = 'easycap_layout.mat';
cfg.colorbar         = 'yes';
figure
figure(1); ft_multiplotTFR(cfg, TFbaseline)
figure(2); ft_multiplotTFR(cfg, TFactivation)

%%
cfg = [];
cfg.channel ='all'; %{'Cz','Fp1'};
% cfg.zlim = 'maxabs';
figure
figure(1); ft_singleplotTFR(cfg, TFbaseline);
figure(2); ft_singleplotTFR(cfg, TFactivation);

%%
cfg = [];
% cfg.xlim = [df1.time(1):0.2:df1.time(end)];
cfg.comment = 'xlim';
cfg.commentpos = 'title';
% cfg.showlabels = 'yes';
cfg.maskparameter = 'mask';
cfg.maskstyle = 'saturation';
% cfg.colormap = colormap('jet'); % default; blue to red
%cfg.colormap = colormap('hot'); % dark to light; better for b&w printers
cfg.contournum = 0;
% cfg.marker = 'labels';
% cfg.markerfontsize = 8;
[minval, minidx] = min(df1.powspctrm(:));
% [i, j, k, l] = ind2sub( size(df1), minidx );
% cfg.colorbar = 'yes';
cfg.shading = 'interp';
% cfg.style = 'fill';
% cfg.roi = 'Fp1,Cz';
cfg.markersymbol = 'o';
cfg.zlim   = [minval, minidx/2] ;
cfg.highlightsymbolseries = ['*','x','+','o','.'];
cfg.highlightcolorpos = [0.5 0 1];
cfg.highlightcolorneg = [0 0.5 0];
% cfg.ylim = [15 20];
cfg.layout = 'easycap_layout.mat';
figure(1); ft_topoplotTFR(cfg, TFbaseline);
figure(2); ft_topoplotTFR(cfg, TFactivation);

%%
cfg=[];
cfg.method= 'montecarlo';
cfg.statistic= 'ft_statfun_actvsblT';
cfg.channel          = {'EEG'};
cfg.latency          = [0.1 1.9];
cfg.frequency        = 7;
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.elec        = elec;
% cfg.minnbchan        = 2;
cfg.tail             = 0;
cfg.clustertail      = 0;
cfg.alpha            = 0.05;
cfg.numrandomization = 100;
cfg.clustercritval = 0.05;
% % prepare_neighbours determines what sensors may form clusters
cfg_neighb.method    = 'distance';
cfg_neighb.elec = elec;
cfg.neighbours       = ft_prepare_neighbours(cfg_neighb, df1);

% design matrix
ntrials = size(TFbaseline.powspctrm,1);
design  = zeros(2,2*ntrials);
design(1,1:ntrials) = 1;
design(1,ntrials+1:2*ntrials) = 2;
design(2,1:ntrials) = [1:ntrials];
design(2,ntrials+1:2*ntrials) = [1:ntrials];
cfg.design   = design;
cfg.ivar     = 1;
cfg.uvar     = 2;
[stat] = ft_freqstatistics(cfg, TFbaseline, TFactivation);

%%
cfg = [];
cfg.alpha  = 0.2;
cfg.parameter = 'stat';
cfg.showlabels = 'yes';
cfg.maskparameter = 'mask';
cfg.maskstyle = 'saturation';
cfg.avgoverfreq = 'yes';
cfg.contournum = 0;
% cfg.emarker = 'x';
% cfg.colorbar = 'yes';
cfg.zlim   = [-4 4];
cfg.shading = 'interp';
% cfg.style = 'fill';
cfg.comment = 'auto';
cfg.highlightsymbolseries = ['*','x','+','o','.'];
cfg.highlightcolorpos = [0.5 0 1];
cfg.highlightcolorneg = [0 0.5 0];
% cfg.highlightchannel = find(stat.prob<0.2);
cfg.layout = 'easycap_layout.mat';

ft_clusterplot(cfg, freqStatistics);
