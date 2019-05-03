function output = uh_freqStat_allband(d,plot,statmethod,foi,method)
% Perform time-frequency analysis and identify relative power changes with
% respect to the pre-defined baseline (this could also be considered as
% ERD/ERS.
% output freq contains the following fields
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
% Let the trial length be [-3 +2], and the baseline period is from [-3 -1]
% and the task segment to be in [-1 +1]
% then we can calculate the relative of absolute change of freq response
% with respect to the baseline.
if ~exist('foi','var')
    foi = 0.1:0.2:50;
end
if ~exist('statmethod','var')
    statmethod = 'montecarlo';
end
if ~exist('plot','var')
    plot = 0;
end
if ~exist('method','var')
    method = 'multitaper';
end
%% Single-trial time-frequency response analysis for statistical test
if strcmp('multitaper',method)
    %%
    cfg              = [];
    cfg.output       = 'pow';
    cfg.channel      = 'EEG';
    cfg.keeptrials   = 'yes';
    cfg.method       = 'mtmconvol';
    cfg.taper = 'dpss';
    cfg.foi          = foi(1):0.1:foi(end);
    cfg.toi = min(d.time{1}):0.01:max(d.time{1}); % time window "slides" from -start to end sec in steps of 0.1 msec (10 ms)
    cfg.t_ftimwin= ones(length(cfg.foi))*0.2;  % length of time window fixed at 0.2 sec
    cfg.tapsmofrq = ones(length(cfg.foi),1).*11; % spectral smoothing = +/- 11 Hz
    cfg.pad = 'maxperlen';
    freq   = ft_freqanalysis(cfg, d);    
    %% Extract frequency discriptives
    %     cfg = [];
    %     cfg.channel = 'EEG';
    %     freq1 = ft_freqdescriptives(cfg,freq);
    %% Grand average
    %     cfg = [];
    %     cfg.channel = 'EEG';
    %     freqavg = ft_freqgrandaverage(cfg,freq);
    %% ERD/ERS computation
    cfg = [];
    cfg.channel = 'EEG';
    cfg.baseline = [-3 -1];
    cfg.baselinetype = 'relative';
    freqERD = ft_freqbaseline(cfg,freq);
elseif strcmp('wavelet',method)
    %% Wavelets
    cfg = [];
    cfg.output = 'pow';
    cfg.channel = 'EEG';
    cfg.method = 'wavelet';
    cfg.keeptrials   = 'yes';
    cfg.foi   = foi(1):0.5:foi(end);
    timewindow = ones(size(cfg.foi))*0.1;  % length of time window fixed at 0.5 sec
    cfg.t_ftimwin= timewindow;
    cfg.tapsmofrq = cfg.foi*0.1;
    cfg.toi = min(d.time{1}):0.2:max(d.time{1}); % time window "slides" from -start to end sec in steps of 0.1 msec (10 ms)
    freq      = ft_freqanalysis(cfg,d);
    %[trial x channel x freq x time] - the output structure looks like this
    %% ERD/ERS computation
    cfg = [];
    cfg.channel = 'EEG';
    cfg.baseline = [-3 -1];
    cfg.baselinetype = 'relative';
    freqERD = ft_freqbaseline(cfg,freq);
end
%{
%To obtain percentage values for ERD/ERS,
% the power within the frequency band of interest in the period after
% the event is given by A whereas that of the preceding base-
% line or reference period is given by R. ERD or ERS is
% defined as the percentage of power decrease or increase,
% respectively, according to the expression [ERD = (freqPost - Ref)/Ref*100]
% freqPre.time = freqPost.time;
% freqRef.time = freqPost.time;
%
% cfg           = [];
% cfg.parameter = 'powspctrm';
% cfg.operation = '(x2-x1)./x1';
% freqPreERD = ft_math(cfg, freqPre1,freqRef);
% freqPostERD = ft_math(cfg, freqPost1,freqRef);
% freqPre.powspctrm = freqPreERD.powspctrm;
% freqPost.powspctrm = freqPostERD.powspctrm;
% %% Log-transform the single-trial power
%   cfg           = [];
%   cfg.parameter = 'powspctrm';
%   cfg.operation = 'log10';
%   freqERD = ft_math(cfg, freqERD);
%}
%% STAT TEST
cfg = [];
cfg.toilim = [-1.4 -0.4];% reference (duration 2 sec)
freqPre = ft_selectdata(cfg, freqERD);
cfg.toilim = [-0.5 0.5];% preSegment (duration 2 sec)
freqPost = ft_selectdata(cfg, freqERD);
freqPre.time = freqPost.time;
%% Compute the neighbours
cfg           = [];
cfg.channel   = 'EEG';
cfg.method    = 'triangulation';
cfg.elec      = freqPost.elec;
cfg.feedback  = 'no';
neighbours    = ft_prepare_neighbours(cfg);
% Compute the statistics
cfg = [];
cfg.channel   = 'EEG';
cfg.statistic = 'indepsamplesT';
cfg.ivar      = 1;
cfg.design    = zeros(1,size(freqPost.trialinfo,1));
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
    stat = ft_freqstatistics(cfg, freqPre,freqPost);

elseif strcmp(statmethod,'fdr')
    cfg.method    = 'analytic';
    cfg.correctm  = 'fdr';
    stat = ft_freqstatistics(cfg, freqPre,freqPost);

elseif strcmp(statmethod,'montecarlo')
    cfg.method            = 'montecarlo';
    cfg.correctm          = 'cluster';
    cfg.numrandomization  = 1000; % 1000 is recommended, but takes longer
    cfg.neighbours        = neighbours;
    stat = ft_freqstatistics(cfg, freqPre,freqPost);

end
%% prepare the output
output.freqPre = freqPre;
output.freqPost = freqPost;
output.stat = stat;
output.statmethod = statmethod;
%% Visualise the results
if plot
    %% stat grid plot
    load chan_label;
    figure(1);
    set(gcf,'units','normalized','outerposition',[0 0 1 1],'color','w'); % full screen
    for ii = 1:length(label)
        cfg               = [];
        cfg.marker        = 'on';
        cfg.layout = 'easycap_layout.mat';
        cfg.channel       = 'EEG';
        cfg.parameter     = 'stat';  % plot the t-value
%         cfg.maskparameter = 'mask';  % use the thresholded probability to mask the data
%         cfg.maskstyle     = 'saturation';
        cfg.interactive = 'no';
        cfg.colormap = colormap(othercolor('BuOr_8'));
        if ii == length(label)
            cfg.colorbar = 'no'; % change to 'yes'
            % cfg.colormap = colormap('gray');
        else
            cfg.colorbar = 'no';
        end
        cfg.channel = label{ii};
      [maxval, maxidx] = max(stat.stat(:));
%       [minval, minidx] = min(stat.stat(:));
        cfg.zlim = [maxval-3.5,maxval]; 
        subplot(6,6,ii)
        ft_singleplotTFR(cfg, stat);
        a = get(gca,'XTickLabel');
        set(gca,'XTickLabel',a,'FontName','Times','fontsize',5);
    end
    tightfig;saveppt2('ERD_ERS_analysis.ppt','notes','This is a note','comments','Permutation Stats [0.1 50]Hz','visible');
    %%
    %plot the average
    figure(2);
    set(gcf,'units','normalized','outerposition',[0 0 1 1],'color','w'); % full screen
    cfg.channel = label;
    cfg.colorbar = 'yes';
%        cfg.maskparameter = 'mask';  % use the thresholded probability to mask the data
%         cfg.maskstyle     = 'saturation';
        [maxval, maxidx] = max(stat.stat(:));
%       [minval, minidx] = min(stat.stat(:));
%         cfg.zlim = [0,maxval]; 
        cfg.colormap = colormap(othercolor('BuOr_8'));
    ft_singleplotTFR(cfg, stat);
    tightfig
    tightfig;saveppt2('ERD_ERS_analysis.ppt','notes','This is a note','comments','Averaged Permutation Stats [0.1 50]Hz','visible');
    %% frequency grid plot
    figure(3);
    set(gcf,'units','normalized','outerposition',[0 0 1 1],'color','w'); % full screen
    for ii = 1:length(label)
        cfg              = [];
        cfg.marker       = 'on';
        cfg.layout = 'easycap_layout.mat';
        cfg.channel       = 'EEG';
        cfg.parameter     = 'powspctrm';  % plot the t-value
        cfg.maskstyle     = 'saturation';
        cfg.colormap = colormap(othercolor('BuOr_8'));
        if ii == length(label)
            cfg.colorbar = 'yes';            
        else
            cfg.colorbar = 'no';
        end
        cfg.channel = label{ii};
        % [maxval, maxidx] = max(stat2.stat(:))
        % [minval, minidx] = min(stat2.stat(:))        
        subplot(6,6,ii)
        ft_singleplotTFR(cfg, freqPost);
    end
    tightfig;saveppt2('ERD_ERS_analysis.ppt','notes','This is a note','comments','ERD/ERS Grid [0.1 50]Hz','visible');
    %%
    figure(4);
    set(gcf,'units','normalized','outerposition',[0 0 1 1],'color','w'); % full screen
    cfg.channel = label;
    ft_singleplotTFR(cfg, freqPost);
    tightfig;saveppt2('ERD_ERS_analysis.ppt','notes','This is a note','comments','Averaged ERD/ERS [0.1 50]Hz','visible');

    %% Frequency Topoplot
    cfg = [];
    cfg.xlim = [freqPost.time(1):0.1:freqPost.time(end)];
    cfg.comment = 'xlim';
    cfg.commentpos = 'title';
    cfg.colormap = colormap(othercolor('BuOr_8'));
    % cfg.showlabels = 'yes';
    cfg.maskparameter = 'mask';
    cfg.maskstyle = 'saturation';
%     cfg.contournum = 0.5;
    cfg.marker = 'labels';
    cfg.shading = 'interp';
    %cfg.style = 'fill';
    %cfg.roi = 'Fp1,Cz';
    cfg.markersymbol = 'o';
    %cfg.zlim   = [minval, minidx/2] ;
    cfg.highlightsymbolseries = ['*','x','+','o','.'];
    cfg.highlightcolorpos = [0.5 0 1];
    cfg.highlightcolorneg = [0 0.5 0];
    cfg.highlight = 'on';
    cfg.highlightchannel = find(stat.prob>0.8);
    %cfg.xlim         = [0 0.4];
    %cfg.zlim         = [minval, minidx];
    %cfg.ylim         = [freq.freq(1) freq.freq(end)];
    cfg.marker       = 'on';
    cfg.layout       = 'easycap_layout.mat';
    cfg.channel      = 'EEG';
    cfg.colorbar         = 'yes';
    figure(5); set(gcf,'units','normalized','outerposition',[0 0 1 1],'color','w'); % full screen
    pause(1); ft_topoplotTFR(cfg, freqPost);
    tightfig; saveppt2('ERD_ERS_analysis.ppt','notes','This is a note','comments','This is a textbox','comments','This is the comment','visible');    
%%
% make a plot
% cfg = [];
% cfg.highlightsymbolseries = ['*','*','.','.','.'];
% cfg.layout       = 'easycap_layout.mat';
% cfg.contournum = 0;
% cfg.markersymbol = '.';
% cfg.alpha = 0.05;
% cfg.parameter='stat';
% cfg.zlim = [-5 5];
% ft_clusterplot(cfg,stat);
    %%
    figure(6); set(gcf,'units','normalized','outerposition',[0 0 1 1],'color','w'); % full screen
    %cfg.xlim = [freqPost.time(1):0.3:freqPost.time(end)];
    [maxval, maxidx] = max(freqPost.powspctrm(:));
    %[i, j, k, l] = ind2sub( size(df1), minidx );
    cfg.emarker = 'o';
    %cfg.marker = 'labels';
    cfg.roi = label;
    %cfg.markerfontsize = 8;
    cfg.highlightchannel = find(freqPost.powspctrm==maxval/2);
    %cfg.marker='labels';
    cfg.markersymbol = 'o';
    cfg.colormap = colormap(othercolor('BuOr_8'));
    ft_topoplotTFR(cfg, freqPost);
    tightfig; saveppt2('ERD_ERS_analysis.ppt','notes','This is a note','comments','This is a textbox','comments','This is the comment','visible');    
end