function d = uh_filterOPAL(data,bandpass)
%% This function will provide different options for filtering
% to be extended
if ~exist('bandpass','var')
    bandpass = [0.001 6];
    disp('=========================================');
    disp('Default band pass range selected [0.001 6]');
    disp('=========================================');
end
%%
cfg = [];
% cfg.channel = {'EEG'};
% cfg.continuous = 'yes';
% cfg.detrend = 'yes';
% cfg.preproc.demean = 'yes';
cfg.bpfilter = 'yes';
cfg.bpfilttype = 'but';
cfg.bpfreq = bandpass; 
cfg.bpfiltdir = 'twopass';
cfg.bpfiltord = 2;
cfg.bpinstabilityfix = 'reduce';
d = ft_preprocessing(cfg,data);
%%
end