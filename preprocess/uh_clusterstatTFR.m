function [stat,figure1]=uh_clusterstatTFR(data1,data2,frequency,alpha, xlim,zlim,ttype) 
% independent sample ttest (two groups) using random permutation 
% reference: http://www.fieldtriptoolbox.org/tutorial/cluster_permutation_freq
%=================================
% INPUT: Time Frequency data obtained via [cfg.method = 'mtmconvol']
%        data1 = baseline (prestimulus)
%        data2 = condition (poststimulus)

%% parameter initialiation 
if ~exist('alpha','var')
    alpha=0.05;
end
if ~exist('frequency','var')
    frequency  = 9;
end 
% type of the test 
if ~exist('ttype','var')
%     ttype='paired-ttest';
   ttype = 'montecarlo';    
end
cfg=[];
if exist('zlim','var')
    cfg.zlim=zlim;
else
    cfg.zlim='maxmin';
end
if exist('xlim','var')
    cfg.xlim = xlim;
else 
    cfg.xlim = 'maxmin';
end 
%%

d = uh_filter(dataClean,[6 9])
%%
cfg = [];
cfg.toilim = [0 1.8];
d1 = ft_redefinetrial(cfg, d);

cfg = [];
cfg.toilim = [2 3.8];
d2 = ft_redefinetrial(cfg, d);

d2.time = d1.time;

%%
cfg = [];
cfg.output = 'pow';
cfg.channel = 'EEG';
cfg.method = 'wavelet';
% cfg.taper = 'hanning';
cfg.foi = 6:1:9;
% cfg.toi = [0.6:0.05:1.6];
cfg.t_ftimwin = 3./cfg.foi; %10 cycles
cfg.toi = 0.6:1/100:1.6;
cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.5;  % length of time window fixed at 0.5 sec
% cfg.toi          = -0.1:0.02:0.5;                    % time window "slides" from -0.1 to 0.5 sec in steps of 0.02 sec (20 ms)
cfg.tapsmofrq = cfg.foi*0.4;
cfg.keeptrials = 'yes';

df1 = ft_freqanalysis(cfg, d1);
df2   = ft_freqanalysis(cfg, d2) ;
%%

cfg = [];
cfg.xlim = [0.6:0.2:1.6];
cfg.comment = 'xlim';
cfg.commentpos = 'title';
cfg.showlabels = 'yes';
cfg.maskparameter = 'mask';
cfg.maskstyle = 'saturation';
% cfg.colormap = colormap('jet'); % default; blue to red
%cfg.colormap = colormap('hot'); % dark to light; better for b&w printers
cfg.contournum = 0;
% cfg.marker = 'labels';
% cfg.markerfontsize = 8;

[minval, minidx] = min(df1.powspctrm(:));
% [i, j, k, l] = ind2sub( size(df1), minidx );

% cfg.shading = 'interp';
% cfg.style = 'fill';
% cfg.roi = 'Fp1,Cz';
cfg.emarker = '.';
cfg.colorbar = 'yes';
cfg.zlim   = 'maxabs';
cfg.highlightsymbolseries = ['*','x','+','o','.'];
cfg.highlightcolorpos = [0.5 0 1];
cfg.highlightcolorneg = [0 0.5 0];
% cfg.ylim = [15 20];                  

cfg.layout = 'easycap_layout.mat';
figure; ft_topoplotTFR(cfg,df1);

%%
cfg=[];
cfg.method= 'montecarlo';
cfg.statistic= 'ft_statfun_actvsblT';
cfg.channel          = {'EEG'};
cfg.latency          = [0.1 1.2];
cfg.frequency        = 7;
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.elec        = df1.elec;
% cfg.minnbchan        = 2;
cfg.tail             = 0;
cfg.clustertail      = 0;
cfg.alpha            = 0.05;
cfg.numrandomization = 100;
 
% % prepare_neighbours determines what sensors may form clusters
cfg_neighb.method    = 'distance';
cfg_neighb.elec = elec1;
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
cfg.alpha  = 0.3;
cfg.parameter = 'stat';
cfg.showlabels = 'yes';
cfg.maskparameter = 'mask';
cfg.maskstyle = 'saturation';
cfg.avgoverfreq = 'yes';
cfg.contournum = 0;
cfg.emarker = '.';
% cfg.colorbar = 'yes';
cfg.zlim   = [-4 4];
cfg.comment = 'auto';
cfg.highlightsymbolseries = ['*','x','+','o','.'];
cfg.highlightcolorpos = [0.5 0 1];
cfg.highlightcolorneg = [0 0.5 0];
cfg.highlightchannel = find(stat.prob<alpha);

cfg.layout = 'easycap_layout.mat';
ft_clusterplot(cfg, stat);
%% permutations
cfgs.feedback='no';
if isfield(data1,'powspctrm')
   cfgs.frequency='all';
%     for permi=1:1
%         DATA1=data1;
%         DATA2=data2;
%         switchsub=find(round(rand(1,size(DATA1.powspctrm,1))));
%         DATA1.powspctrm(switchsub,:,:)=data2.powspctrm(switchsub,:,:);
%         DATA2.powspctrm(switchsub,:,:)=data1.powspctrm(switchsub,:,:);
%         [stat] = ft_freqstatistics(cfgs, DATA1,DATA2);
%         minp(permi)=min(stat.prob);
%         disp(['permutation no. ',num2str(permi)])
%     end
    [stat] = ft_freqstatistics(cfgs, data1,data2);
else
    cfgs.latency='all';
    [stat] = ft_timelockstatistics(cfgs, data1,data2);
end
%%
%load neighbours
% minp=sort(minp);

% critP=minp(1000*alpha); % one sided

% datadif=data1;
% if isfield(data1,'powspctrm')
%     if strcmp(ttype,'paired-ttest')
%         datadif.powspctrm=data1.powspctrm-data2.powspctrm;
%     else
%         datadif.powspctrm=mean(data1.powspctrm,1)-mean(data2.powspctrm,1);
%     end
% else
%     datadif.individual=data1.individual-data2.individual;
% end

% cfg.xlim=[xlim xlim]; 
cfg = [];
cfg.layout = 'easycap_layout.mat';
cfg.highlight = 'labels';
cfg.highlightchannel = find(stat.prob<alpha);
cfg.marker='labels';
colorbar;

figure1=figure('Units','normalized','Position',[0 0 1 1]);
subplot(1,2,1)
ft_topoplotER(cfg,data1)
% title(strrep(title1,'_',' '));
subplot(1,2,2)
ft_topoplotER(cfg,data2)

% title(strrep(title2,'_',' '));
% figure;ft_topoplotER(cfg,data1)
% title(strrep(title1,'_',' '));
% figure;ft_topoplotER(cfg,data2)
% title(strrep(title2,'_',' '));
% figure;ft_topoplotER(cfg, datadif);
% colorbar;
% title(strrep([title1,' - ',title2],'_',' '));

end
