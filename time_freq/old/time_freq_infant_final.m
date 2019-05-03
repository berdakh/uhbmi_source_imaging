%%
% % Time Frequency Analysis of Infant Data
% d = uh_filter(datafinal,[6 9]);
% dmu = uh_classextract(d);
% % -----------------------------------------------------------------------
% d = dmu{2};
% %% divide data trials into pre and post stimulus (or onset of a behavior)
% cfg = [];
% cfg.toilim = [min(d.time{1}) -0.1];
% dbase = ft_redefinetrial(cfg, d);
% 
% cfg = [];
% cfg.toilim = [0 max(d.time{1}-0.09)];
% dact = ft_redefinetrial(cfg, d);
% dact.time = d2.time;
% %%
% cfg              = [];
% cfg.output       = 'pow'; 
% cfg.channel      = 'all';
% cfg.method       = 'mtmconvol';
% cfg.taper        = 'hanning';
% cfg.toi = min(dact.time{1}):0.10:max(dact.time{1}); % time window "slides" from -0.1 to 0.5 sec in steps of 0.02 sec (20 ms)
% cfg.foi          = 6:0.10:9;
% cfg.t_ftimwin    = ones(size(cfg.foi)) * 0.5;
% % cfg.trials       = find(data_MEG_responselocked.trialinfo(:,1) == 256);
% freqbase     = ft_freqanalysis(cfg, dbase);
% freqact     = ft_freqanalysis(cfg, dact);
% % cfg.trials       = find(data_MEG_responselocked.trialinfo(:,1) == 4096);
% % TFR_right_MEG    = ft_freqanalysis(cfg, d2);
% 
% %% TFR_left_MEG = 
% %  
% %         label: {464x1 cell}         % Channel names
% %        dimord: 'chan_freq_time'     % Dimensions contained in powspctrm, channels X frequencies X time
% %          freq: [1x40 double]        % Array of frequencies of interest (the elements of freq may be different from your cfg.foi input depending on your trial length) 
% %          time: [1x26 double]        % Array of time points considered
% %     powspctrm: [464x40x26 double]   % 3-D matrix containing the power values
% %          grad: [1x1 struct]         % Gradiometer positions etc
% %          elec: [1x1 struct]         % Electrode positions etc <fixme>
% %           cfg: [1x1 struct]         % Settings used in computing this frequency decomposition 
% % The field TFR_left_MEG.powspctrm contains the temporal evolution of
% % the raw power values for each specified frequency in the left response conditions.
% 
% % To visualize the event-related power changes, a normalization with respect 
% % to a baseline interval will be performed. There are two possibilities for normalizing:
% 
% % (a) subtracting, for each frequency, the average power in a baseline interval from all
% % other power values. This gives, for each frequency, the absolute change in power 
% % with respect to the baseline interval. 
% 
% %(b) expressing, for each frequency, 
% % the raw power values as the relative increase or decrease with respect 
% % to the power in the baseline interval. This means active period/baseline. 
% % Note that the relative baseline is expressed as a ratio; i.e. no change is represented by 1.
% 
% cfg = [];
% % cfg.baseline     = [min(freqbase.time) -0.1]; 
% % cfg.baselinetype = 'absolute'; 
% % cfg.zlim         = [-1e-26 1e-26];       
% cfg.showlabels   = 'yes';	
% cfg.layout       = 'easycap_layout.mat';
% % cfg.channel      = 'Cz*1';
% cfg.colorbar         = 'yes';
% figure;
% ft_multiplotTFR(cfg, freqbase);
% 
% 
% % Something interesting seems to happen at channel MEG1041. To make a plot of a single channel use the function ft_singleplotTFR:
% %%
% cfg = [];
% cfg.baseline     = [min(TFR_left_MEG.time) -0.1]; 
% cfg.baselinetype = 'absolute';  
% cfg.maskstyle    = 'saturation';	
% % cfg.zlim         = [-1e-26 1e-26];	        
% cfg.channel      = 'C4';
%  
% figure;
% ft_singleplotTFR(cfg, TFR_left_MEG);
% 
% %%
% % cfg = [];
% % cfg.baseline     = [min(TFR_left_MEG.time) -0.1]; 
% % cfg.baselinetype = 'absolute';
% % cfg.commentpos = 'title';
% % cfg.xlim         = [0 0.4];   
% % [minval, minidx] = min(TFR_left_MEG.powspctrm(:));
% % % cfg.zlim         = [minval, minidx];	        
% % cfg.ylim         = [6.5 7.5];
% % cfg.marker       = 'on';
% % 
% % cfg.layout       = 'easycap_layout.mat';
% % cfg.channel      = 'C4';
% % cfg.colorbar         = 'yes';
% % % figure;
% % ft_topoplotTFR(cfg, TFR_left_MEG);