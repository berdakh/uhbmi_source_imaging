function d = uh_resample(data,srate_new)
%% This function will provide different options for filtering
% to be extended
if ~exist('srate_new','var')
    srate_new = 100;
    disp('===============================================');
    disp('Default sampling rate to resample to --> 100 Hz');
    disp('===============================================');
end
%%
cfg = [];
cfg.resamplefs = srate_new;
cfg.detrend = 'no';
cfg.demean = 'no';
cfg.feedback = 'textbar';
cfg.trials = 'all'; 
d = ft_resampledata(cfg,data);
%%
end