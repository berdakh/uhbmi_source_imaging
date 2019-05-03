function data = uh_definetrial(shift,classinfo,data,trialdef,Fs)
%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% This function takes custom events and uses ft_redefinetrial to cut long
% continuous data in memory to segment in FT framework.
%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% It actually helps us to load full length data into FT and perform ICA,
% preprocessing and then cut up into pieces, whereas FT focuses only on
% cutting into pieces and performing all types of pre-processing.
%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% Inputs:
%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% data - eeg data loaded into memory
% event -
% trial - preStim(sample), onset(sample),postStim(sample),  preStimDuration(-1000), 2
%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% 3/18/2015 [mlearnx - to be improved]
%%
if ~exist('Fs','var')
    if any(strcmp('fsample',fieldnames(data)))
        Fs = data.fsample;
    elseif any(strcmp('fsample',fieldnames(data)))
        Fs = data.fs;
    else
        Fs = 1000;
    end
end

event = uh_event(classinfo,shift);
%% trial definitions
if nargin < 4
    trialdef = [];
end

if isempty(trialdef)
    trialdef.durationtype = 'prepostonset';
end
if ~isfield(trialdef,'durationtype')
    trialdef.durationtype = 'prepostonset';
end
if ~isfield(trialdef,'ntrials')
    trialdef.ntrials = inf;
end
    trialdef.eventtype = 'Stimulus';
if ~isfield(trialdef,'eventtype')
end
if ~isfield(trialdef,'eventvalue')
    trialdef.eventvalue = 'S2';
end
% toggle between the way trials should be segmented
switch trialdef.durationtype
    % this method segments trials based on time before and after the onset
    % of the event
    case 'prepostonset'
        if ~isfield(trialdef,'prestim')
            trialdef.prestim = 2;
        end
        if ~isfield(trialdef,'postim')
            trialdef.postim = 2;
        end
        % generate list trial information for FieldTrip
        trial = zeros(length(event),4);   conditionlabellist = cell(length(event),1);
        disp(['size of ''classinfo'' --> ',num2str(size(trial))])
        for ii = 1:length(event)
            if strncmp(event(ii).cond_name,'reach',5)
                trialdef.prestim_rch = 2;
                trialdef.postim_rch = 2;
                evntprestim = event(ii).sample-Fs*trialdef.prestim_rch;
                evntpostim = event(ii).sample+Fs*trialdef.postim_rch;
                trial(ii,:) = [evntprestim,evntpostim,...
                -(Fs*trialdef.prestim_rch), event(ii).condition];
                conditionlabellist{ii,1} = event(ii).cond_name;
            elseif strcmp(event(ii).cond_name,'rest')
                trialdef.prestim_r = 0;
                trialdef.postim_r = 4;
                N = event(ii).Stoptime - event(ii).sample;
                windowLength = Fs*(trialdef.prestim_r + trialdef.postim_r)+1;
                OL = 0; % percent overlap
                nonOLwL = round((1-OL)*windowLength);
                windowPosition = 1:nonOLwL:N; % sliding window
                numWindows = length(windowPosition);
                for wI = 1:numWindows,
                    windowPositionEnd = windowPosition(wI)+windowLength-1;
                    if windowPositionEnd >= N || windowLength > N,continue,end
                    evntprestim_r = event(ii).sample + windowPosition(wI) - 1;
                    evntpostim_r = event(ii).sample + windowPositionEnd - 1;
                    trial(ii,:) = [evntprestim_r,evntpostim_r,...
                    -(Fs*trialdef.prestim_r), event(ii).condition];
                    conditionlabellist{ii,1} = event(ii).cond_name;
                end
            else
                evntprestim = event(ii).sample-Fs*trialdef.prestim;
                evntpostim = event(ii).sample+Fs*trialdef.postim;
                trial(ii,:) = [evntprestim,evntpostim,...
                -(Fs*trialdef.prestim), event(ii).condition];
                conditionlabellist{ii,1} = event(ii).cond_name;
            end
        end 
        
    % this method segments trials based on the beginning and end of the event    
    case 'wholetrial'
        % generate list trial information for FieldTrip
        trial = zeros(length(event),4);   conditionlabellist = cell(length(event),1);
        disp(['size of ''classinfo'' --> ',num2str(size(trial))])
        for ii = 1:length(event)
            trial(ii,:) = [event(ii).sample, event(ii).Stoptime,...
                event(ii).offset, event(ii).condition];
            conditionlabellist{ii,1} = event(ii).cond_name;
        end        
end



%{
if ~exist('trdef','var')
    trialdef.prestim = 2;
    trialdef.postim = 2;
    trialdef.ntrials = inf;
    trialdef.eventtype = 'Stimulus';
    trialdef.eventvalue = 'S2';
else
    trialdef = trialdef;
end
%%
trial = zeros(length(event),4);   conditionlabellist = cell(length(event),1);
disp(['size of ''classinfo'' --> ',num2str(size(trial))])
for ii = 1:length(event)
    trial(ii,:) = [event(ii).sample-Fs*trialdef.prestim,... 
        event(ii).sample+Fs*trialdef.postim-10,...
        -(Fs*trialdef.prestim), event(ii).condition];
    conditionlabellist{ii,1} = event(ii).cond_name;
end
%}
%%
conditionlabellist(trial(:,2)==0,:) = [];
trial(trial(:,2)==0,:) = [];

cfg = [];
cfg.trialfun= @ft_trialfun_general;
% cfg.trialdef= trialdef;
cfg.showcallinfo='yes';
% cfg.debug='yes';
cfg.trackcallinfo='yes';
cfg.trackdatainfo='yes';
cfg.trackparaminfo='yes';
% cfg.event = event;
positiveidcs = find(trial(:,1) > 0);
cfg.conditionlabel = conditionlabellist(positiveidcs);
cfg.trl = trial(positiveidcs,:);
data = ft_redefinetrial(cfg, data); 

end
