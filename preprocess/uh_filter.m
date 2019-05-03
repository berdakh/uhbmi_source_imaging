function d = uh_filter(data,cfg)
%% This function will provide different options for filtering
% to be extended
if nargin==1
    cfg = [];
end

%% Intializations of 'cfg'
if ~isfield(cfg,'channel')
    cfg.channel = {'EEG'};
end
%cfg.continuous = 'yes';
% if ~isfield(cfg,'detrend')
%     cfg.detrend = 'yes';
% end
if ~isfield(cfg,'preproc')
    cfg.preproc.demean = 'yes';
else   % if 'cfg.preproc' exists
    if ~isfield(cfg.preproc,'demean')
        cfg.preproc.demean = 'yes';
    end    
end
if ~isfield(cfg,'bsfilter')
    cfg.bsfilter = 'yes';  % band stop filter - notch filter
end
if ~isfield(cfg,'bsfreq')
    cfg.bsfreq = [58 62];
end
if ~isfield(cfg,'bpfilter')
    cfg.bpfilter = 'yes';
end
if ~isfield(cfg,'bpfilttype')
    cfg.bpfilttype = 'but';
end
if ~isfield(cfg,'bpfreq')
    cfg.bpfreq = [0.1 60];
    disp('=========================================');
    disp('Default band pass range selected [0.1 60]');
    disp('=========================================');    
end
if ~isfield(cfg,'bpfiltdir')
    cfg.bpfiltdir = 'twopass';
end
if ~isfield(cfg,'bpfiltord')
    cfg.bpfiltord = 2;
end
if ~isfield(cfg,'bpinstabilityfix')
    cfg.bpinstabilityfix = 'reduce';
end

%% Perform filtering
d = ft_preprocessing(cfg,data);

end