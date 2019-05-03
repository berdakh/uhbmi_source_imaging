function ERD = uh_freqERD(d,plot,baseline,foi,method)
% DESCRIPTION: 
% This function calculates event related perturbation (ERS/ERD) as the percentage of a 
% decrease or increase during a test interval (T), as compared to a reference interval (R). 
% The following formula is used: ERSP = (R-T)/R x 100.
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

if ~exist('foi','var')
    foi = 6:0.1:9;
end
if ~exist('baseline','var')
    baseline = [-1.5 -0.5];
end
if ~exist('plot','var')
    plot = 0;
end
if ~exist('method','var')
    method = 'wavelet';
end
%%
cfg = [];
cfg.toilim = baseline;
dPre = ft_redefinetrial(cfg, d); % extract preTrigger baseline 

cfg.toilim = [0 max(d.time{1}-0.09)];
dPost = ft_redefinetrial(cfg, d); % extract postTrigger (activation)
% dPre.time = dPost.time; 

%% input - data structure [prestimulus |onset| poststimulus]
%{
% it is assumed that the prestimulus period is a baseline one
% configuration
% %% Multitapering
% cfg           = [];
% cfg.output    = 'pow';
% cfg.method    = 'mtmconvol';
% cfg.taper     = 'hanning';
% cfg.toi       = min(dPre.time{1}):0.1:max(dPre.time{1}); % time window "slides" from -start to end sec in steps of 0.1 msec (10 ms)
% cfg.foi       = 6:0.08:9;
% timewindow = ones(size(cfg.foi))*0.4;  % length of time window fixed at 0.5 sec
% cfg.t_ftimwin= timewindow;
% freq  = ft_freqanalysis(cfg, d);
% %{
% % freqPre = label: {58x1 cell}
% %        dimord: 'chan_freq_time'
% %          freq: [5.2604 5.7864 6.3125 6.8385 7.3645 7.8906 8.4166 8.9427 9.4687 9.9947]
% %          time: [1x20 double]
% %     powspctrm: [58x10x20 double]
% %          elec: [1x1 struct]
% %           cfg: [1x1 struct]
%
% %% Compute contrast between response hands
% cfg = [];
% cfg.parameter = 'powspctrm';
% cfg.operation = '(x1-x2)/(x1+x2)';
% freq_diff      = ft_math(cfg, freqPost, freqPre);
% %%
% cfg = [];
% cfg.marker  = 'on';
% cfg.layout = 'easycap_layout.mat';
% [maxval, minidx] = max(freq_diff.powspctrm(:));
% % cfg.zlim         = [maxval/100, maxval];
%
% % cfg.channel = 'EEG';
% f1 = figure; set(f1,'color','white')
% ft_multiplotTFR(cfg, freq_diff); tightfig
%}
%%
if strcmp('multitaper',method)
    cfg              = [];
    cfg.output       = 'pow';
    cfg.channel      = 'all';
    cfg.method       = 'mtmconvol';
    cfg.taper        = 'hanning';
    cfg.toi = min(d.time{1}):0.1:max(d.time{1}); % time window "slides" from -start to end sec in steps of 0.1 msec (10 ms)
    cfg.foi          = foi(1):0.1:foi(2);
    timewindow = ones(size(cfg.foi))*0.5;  % length of time window fixed at 0.5 sec
    cfg.t_ftimwin= timewindow;
    freq     = ft_freqanalysis(cfg, d);
    cfg.toi = min(dPre.time{1}):0.1:max(dPre.time{1}); % time window "slides" from -start to end sec in steps of 0.1 msec (10 ms)
    freqPre      = ft_freqanalysis(cfg, dPre);
    freqPost     = ft_freqanalysis(cfg, dPost);
    
elseif strcmp('wavelet',method)
    %% Wavelets
    cfg = [];
    cfg.output = 'pow';
    cfg.channel = 'EEG';
    cfg.method = 'wavelet';
    cfg.foi   = foi(1):0.1:foi(2);
    timewindow = ones(size(cfg.foi))*0.5;  % length of time window fixed at 0.5 sec
    cfg.t_ftimwin= timewindow;
    cfg.toi = min(d.time{1}):0.1:max(d.time{1}); % time window "slides" from -start to end sec in steps of 0.1 msec (10 ms)
    cfg.tapsmofrq = cfg.foi*0.4;
    % % cfg.keeptrials = 'yes';
    freq = ft_freqanalysis(cfg, d);
    
    cfg.toi = min(dPre.time{1}):0.2:max(dPre.time{1}); % time window "slides" from -start to end sec in steps of 0.1 msec (10 ms)
    freqPre      = ft_freqanalysis(cfg, dPre);
    freqPost     = ft_freqanalysis(cfg, dPost);

    % freqPost     = ft_freqanalysis(cfg, dPost);
end
% The following formula is used: ERSP = (Reference-Test)/Reference x 100.
cfg           = [];
cfg.parameter = 'powspctrm';
cfg.operation = '(x1-x2)./x1';
ERD = ft_math(cfg, freqPre,freqPost);
%%
if plot
    %% % frequency grid plot
    load chan_label;
    figure(1);    
    set(gcf,'units','normalized','outerposition',[0 0 1 1],'color','w'); % full screen
    for ii = 1:length(label)
        cfg              = [];
        cfg.baseline     = baseline;
        cfg.baselinetype = 'relative'; 
        cfg.marker       = 'on';
        cfg.layout = 'easycap_layout.mat';
        cfg.channel       = 'EEG';
        cfg.parameter     = 'powspctrm';  % plot the t-value
        %         cfg.maskparameter = 'mask';  % use the thresholded probability to mask the data
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
        % cfg.zlim = 'zeromax';
        subplot(6,6,ii)
        ft_singleplotTFR(cfg, freq);
    end
    tightfig;
    print -dpng freq_grid.png
    %%
    figure(2);
    set(gcf,'units','normalized','outerposition',[0 0 1 1],'color','w'); % full screen
    cfg.channel = label;
    ft_singleplotTFR(cfg, freq);
    print -dpng freq_grid_avg.png
    
    %% Frequency Topoplot
    cfg = [];
    cfg.xlim = [0:0.2:freq.time(end)];
    cfg.comment = 'xlim';
    cfg.commentpos = 'title';
    cfg.colormap = colormap(othercolor('BuOr_8'));
    cfg.baseline     = baseline;
    cfg.baselinetype = 'relative';   
    % cfg.showlabels = 'yes';
    cfg.maskparameter = 'mask';
    cfg.maskstyle = 'saturation';
    cfg.contournum = 0.5;
    % cfg.marker = 'labels';    
    cfg.shading = 'interp';
    % cfg.style = 'fill';
%   cfg.roi = 'Fp1,Cz';
    cfg.markersymbol = 'o';
    % cfg.zlim   = [minval, minidx/2] ;
    cfg.highlightsymbolseries = ['*','x','+','o','.'];
    cfg.highlightcolorpos = [0.5 0 1];
    cfg.highlightcolorneg = [0 0.5 0];
    % cfg.xlim         = [0 0.4];
    % cfg.zlim         = [minval, minidx];
    % cfg.ylim         = [freq.freq(1) freq.freq(end)];
    cfg.marker       = 'on';
    cfg.layout       = 'easycap_layout.mat';
    cfg.channel      = 'EEG';
    cfg.colorbar         = 'yes';
    %
    figure(3);
    set(gcf,'units','normalized','outerposition',[0 0 1 1],'color','w'); % full screen
    pause(2)
    ft_topoplotTFR(cfg, freq);
    tightfig;
    print -dpng freq_topo.png
    %%
    figure(4);
    cfg.xlim = [0 freq.time(end)];
    [maxval, maxidx] = max(freq.powspctrm(:));
    % [i, j, k, l] = ind2sub( size(df1), minidx );
    cfg.emarker = 'o';
    cfg.marker = 'labels';
    cfg.roi = label;
    cfg.markerfontsize = 8;
    cfg.highlightchannel = find(freq.powspctrm==maxval/2);
    cfg.marker='labels';
    cfg.markersymbol = 'o';
    set(gcf,'color','w'); % full screen
    ft_topoplotTFR(cfg, freq);
    
    print -dpng freq_topo_avg.png
    fprintf('Figures have been saved in the following directory: \n[%s]\n',pwd)
    
end