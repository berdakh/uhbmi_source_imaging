function [ EEG_ASRcleaned ] = uh_runASR( filename,filepath )
%% Using Artifact Subspace Reconstruction (ASR) to remove artifacts
% adding a file path for the 'clean_rawdata' folder
addpath('C:\Users\zrhernan\Documents\MATLAB\eeglab\plugins\clean_rawdata0_31')
tic;
EEG = pop_loadbv(filepath,filename);   % load EEG data

EEG.gain = 0.1;      % add gain for changing amplitude order of magnitude

%     FlatlineCriterion : Maximum tolerated flatline duration. In seconds. If a channel has a longer
arg_flatline= -1;      %  flatline than this, it will be considered abnormal. Default: 5 
        
%             Highpass : Transition band for the initial high-pass filter in Hz. This is formatted as
arg_highpass= [0.05 0.1]; % [transition-start, transition-end]. Default: [0.25 0.75].
         
%     ChannelCriterion : Minimum channel correlation. If a channel is correlated at less than this
arg_channel = -1;     %  value to a reconstruction of it based on other channels, it is considered
%                        abnormal in the given time window. This method requires that channel
%                        locations are available and roughly correct; otherwise a fallback criterion
%                        will be used. (default: 0.85)
% 
%     LineNoiseCriterion : If a channel has more line noise relative to its signal than this value, in
arg_noisy = -1;         %  standard deviations based on the total channel population, it is considered
%                          abnormal. (default: 4)
% 
%     BurstCriterion   :   Standard deviation cutoff for removal of bursts (via ASR). Data portions whose
arg_burst = 3;          %  variance is larger than this threshold relative to the calibration data are
%                          considered missing data and will be removed. The most aggressive value that can
%                          be used without losing much EEG is 3. For new users it is recommended to at
%                          first visually inspect the difference between the original and cleaned data to
%                          get a sense of the removed content at various levels. A quite conservative
%                          value is 5. Default: 5.
% 
% 
%     WindowCriterion :  Criterion for removing time windows that were not repaired completely. This may
arg_window = -1;      %  happen if the artifact in a window was composed of too many simultaneous
%                        uncorrelated sources (for example, extreme movements such as jumps). This is
%                        the maximum fraction of contaminated channels that are tolerated in the final
%                        output data for each considered window. Generally a lower value makes the
%                        criterion more aggressive. Default: 0.25. Reasonable range: 0.05 (very
%                        aggressive) to 0.3 (very lax).  
EEG_temp = clean_rawdata(EEG, arg_flatline, arg_highpass, arg_channel, arg_noisy, arg_burst, arg_window);   
EEG_ASRcleaned = EEG_temp.data';
disp('____EEG data cleaned with ASR')
disp('--------------------------------------------------')
timecompute(toc)
disp('--------------------------------------------------')

end