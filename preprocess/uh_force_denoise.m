function [ dataClean ] = uh_force_denoise( data,varargin )
%UH_FORCE_DENOISE This function will run the FORCe method on each trial of 
% EEG data organized in the FieldTrip data structure
%   Input:       data --> data structure that contains a trial-segmented 
%                         EEG data.
%  Output:  dataClean --> new data structure that contains the denoised, or
%                         artifact-removed EEG trial data along with the
%                         types of values used for determining thresholds 
%                         for IC removal (field 'tVariables') 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Created by: Zach Hernandez, University of Houston, 2016

%% Add these directory paths
load( '\\bmi-nas-01\Contreras-UH\Infantdata\Infantdata\code\Zachs_Infant_decoding_files\BrainVision_1020_64ChanLocs.mat' );
addpath('\\bmi-nas-01\Contreras-UH\Infantdata\Infantdata\Source-Estimation\uh_fieldtrip\FORCe')
addpath('\\bmi-nas-01\Contreras-UH\Infantdata\Infantdata\code\Zachs_Infant_decoding_files')
    
%% Some Initializations
if nargin < 2
    fs = 500;                                                 % Sample rate (500Hz)
else
    fs = varargin{1};
end

chanlabels = data.label;                                  % EEG channel labels only
chans = chanLocs(ismember({chanLocs.labels},chanlabels)); % EEG channel locations, normally loaded via
                                                          % the 'readlocs' function in EEGlab.           
useAcc = 0;                                               % We don't have accelerometer data.

%% Use the FORCe to clean data for each segmented trial
disp( 'Using FORCe method...' );

dataClean = data;  % preallocate
EEG_clean = cell(1,length(data.trial)); % preallocate
Tvar = cell(1,length(EEG_clean)); % preallocate
dat_temp = zeros(numTrls,length(ts));
for trl=1:length(data.trial)
    dat_temp(trl,:,:)=data.trial{trl};
end
parfor trl = 1:length(data.trial)
    EEG_orig = transpose(dat_temp(trl,:,:));%data.trial{trl});    % EEG data
    tic;
    [EEG_cleanT, TvarT] = FORCe_wThrPars( EEG_orig', fs, chans, useAcc );
    disp(['Time taken to clean EEG trial ' num2str(trl) ' ...... ' num2str(toc) 's.']);
    EEG_clean{trl} = EEG_cleanT;
    Tvar{trl} = TvarT{1};
end %repeat for each trial
dataClean.trial = EEG_clean;
dataClean.tVariables = Tvar;

end  %EOF

