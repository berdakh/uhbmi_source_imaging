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
dmu = uh_classextract(datafinal);
% -----------------------------------------------------------------------
d = dmu{2};
%%
% divide data trials into pre and post stimulus (or onset of a behavior)
cfg = [];
cfg.toilim = [min(d.time{1}) d.time{1}(round((length(d.time{1})/2)-1))];
d1 = ft_redefinetrial(cfg, d);

cfg = [];
cfg.toilim = [d.time{1}(round((length(d.time{1})/2)+1)) max(d.time{1})];
d2 = ft_redefinetrial(cfg, d);
d1.time = d2.time;
%%
%  cfg = [];
%  cfg.trials = 1;
%  trial = ft_selectdata(cfg,d);
%  trial = uh_filter(trial,[6 9]);
 %% Wavelet transformation 
cfg = [];
cfg.output = 'pow';
cfg.channel = 'EEG';
cfg.method = 'wavelet';
cfg.width      = 3; %'width', or number of cycles, of the wavelet (default = 7)
cfg.foi = 0.1:0.05:40; %6:0.05:9;
cfg.toi = min(d1.time{1}):0.02:max(d1.time{1}); % time window "slides" from START to END in steps of 0.02 sec (20 ms)
cfg.keeptrials = 'yes';
df1 = ft_freqanalysis(cfg, d1);
df2 = ft_freqanalysis(cfg, d2) ;
%% log transform 
cfg           = [];
cfg.parameter = 'powspctrm';
cfg.operation = 'log10';
df2    = ft_math(cfg, df1);

%% multiplot
cfg = [];
cfg.showlabels = 'yes';	
cfg.layout     = 'easycap_layout.mat';
cfg.zlim = 'maxabs';
cfg.colorbar   = 'yes';
figure; 
ft_multiplotTFR(cfg, df1)

%% single plot
cfg = [];
cfg.channel ={'Cz','Fp1'};%'all'; 
% cfg.zlim = 'maxabs';
figure
ft_singleplotTFR(cfg, df1);

%% topoplot 
cfg = [];
cfg.xlim = [0.2:0.2:1.6];
cfg.comment = 'xlim';
cfg.commentpos = 'title';
cfg.showlabels = 'yes';
cfg.maskparameter = 'mask';
cfg.maskstyle = 'saturation';
% cfg.colormap = colormap('jet'); % default; blue to red
%cfg.colormap = colormap('hot'); % dark to light; better for b&w printers
cfg.contournum = 0.4;
% cfg.marker = 'labels';
% cfg.markerfontsize = 8;
[minval, minidx] = min(df1.powspctrm(:));
% [i, j, k, l] = ind2sub( size(df1), minidx );
% cfg.colorbar = 'yes';
cfg.shading = 'interp';
% cfg.style = 'fill';
% cfg.roi = 'Fp1,Cz';
cfg.emarker = '.';
% cfg.zlim   = 'maxabs';
% cfg.highlightsymbolseries = ['*','x','+','o','.'];
% cfg.highlightcolorpos = [0.5 0 1];
% cfg.highlightcolorneg = [0 0.5 0];
% cfg.ylim = [15 20];                  
cfg.layout = 'easycap_layout.mat';
figure; 
ft_topoplotTFR(cfg,df1);

%% 
cfg=[];
cfg.method= 'montecarlo';
cfg.statistic= 'ft_statfun_actvsblT';
cfg.channel          = {'EEG'};
% cfg.latency          = [0.1 1.2];
cfg.frequency        = 6;
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.02;
cfg.clusterstatistic = 'maxsum';
cfg.elec        = elec;
% cfg.minnbchan        = 2;
cfg.tail             = 0;
cfg.clustertail      = 0;
cfg.alpha            = 0.05;
cfg.numrandomization = 100;
 
% % prepare_neighbours determines what sensors may form clusters
cfg_neighb.method    = 'triangulation';
cfg_neighb.elec = elec;
cfg.neighbours       = ft_prepare_neighbours(cfg_neighb, df1);

% design matrix
ntrials = size(df1.powspctrm,1);
design  = zeros(2,2*ntrials);
design(1,1:ntrials) = 1;
design(1,ntrials+1:2*ntrials) = 2;
design(2,1:ntrials) = [1:ntrials];
design(2,ntrials+1:2*ntrials) = [1:ntrials];
cfg.design   = design;
cfg.ivar     = 1;
cfg.uvar     = 2;
[stat] = ft_freqstatistics(cfg, df1, df2);

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
cfg.colorbar = 'yes';
cfg.zlim   = [-4 4];
cfg.shading = 'interp';
% cfg.style = 'fill';
cfg.comment = 'auto';
cfg.highlightsymbolseries = ['*','x','+','o','.'];
cfg.highlightcolorpos = [0.5 0 1];
cfg.highlightcolorneg = [0 0.5 0];
cfg.highlightchannel = find(stat.prob<0.01);
cfg.layout = 'easycap_layout.mat';
ft_clusterplot(cfg, stat);

%%
% DESCRIPTION: 
% This function calculates event related perturbation (ERS/ERD) as the percentage of a 
% decrease or increase during a test interval (T), as compared to a reference interval (R). 
% The following formula is used: ERSP = (R-T)/R x 100.
cfg = [];
cfg.parameter = 'trial';
cfg.operation = 'd1^2'; 
d1 = ft_math(cfg, d1);

%%
cfg = [];
cfg.parameter = 'trial';
cfg.operation = 'x^2';
d2 = ft_math(cfg, d2);

%%
cfg = [];
cfg.parameter = 'trial';
cfg.operation = '(x1.^2-x2.^2)/(x1.^2*100)';
TFR_diff_MEG = ft_math(cfg, d1, d2);

 %%
cfg = [];
cfg.xlim         = [0.4 0.8];   
cfg.zlim         = [-0.4 0.4];
cfg.ylim         = [15 25];
cfg.marker       = 'on';
cfg.layout       = 'easycap_layout.mat';
cfg.channel      = 'Fp1';
 
figure;
ft_topoplotTFR(cfg, TFR_diff_MEG);
% print -dpng natmeg_freq7.png

cfg = [];
cfg.showlabels   = 'yes';	
cfg.layout       = 'easycap_layout.mat';
cfg.colorbar         = 'yes';
figure; 
ft_multiplotTFR(cfg, TFR_diff_MEG)
