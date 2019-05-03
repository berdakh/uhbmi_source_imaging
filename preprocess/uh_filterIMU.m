function d = uh_filterIMU(data,lowpass)
%% This function will provide different options for filtering
% to be extended
% Providing a low pass at 6 Hz to be consistent with literature
% Rihar et al. Journal of NeuroEngineering and Rehabilitation 2014, 11:133
if ~exist('lowpass','var')
    lowpass = 6;
    disp('=================================');
    disp('Default low pass selected at 6 Hz');
    disp('=================================');
end
%%
cfg = [];
cfg.lpfilter = 'yes';
cfg.lpfilttype = 'but';
cfg.lpfreq = lowpass; 
cfg.lpfiltdir = 'twopass';
cfg.lpfiltord = 2;
cfg.lpinstabilityfix = 'reduce';
d = ft_preprocessing(cfg,data);
%%
end