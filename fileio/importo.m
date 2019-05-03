function data = importo(filename)
%% Import a continuous file from a disk and apply a band-pass filter 
% default definition: Butterworth second order;

% must provide same order of channels because the order of channels found  
% within each infant EEG recording is not neccessarily true
load('BrainVision_1020_64ChannelOrder.mat') 
cfg = []; 
cfg.dataset = filename;
cfg.detrend = 'yes';
data_orig = ft_preprocessing(cfg);
data_orig.label = channelOrder'; % re-name labels of each EEG channel

%% Band pass filter
data = uh_filter(data_orig); 