function [dataClean]=uh_badtrials(cfg,data)
% give it fieldtrip data and it will find bad trials

% examples:
% calculate mean absolute value per trial and exclude trials with values
% greater than 3 SD over the median trial
% cfg.method='abs';
% cfg.criterion='sd';
% cfg.critval=3;
% [good,bad]=uh_badTrials(cfg,data,1)

% calculate variance for each trial and exclude trials exceeding a fixed threshold of 1e-25

% cfg.method='var';
% cfg.criterion='fixed';
% cfg.critval=1e-25;
% [good,bad]=uh_badTrials(cfg,data,1)

% with criterion='median' you choose what part of the median (e.g. cfg.critval=0.5) to add to
% the median for noise threshold. this worked well
Nchans = length(data.label);

if nargin==1
    data=cfg;
    cfg=[];
    plotdata = 1;
end
if isempty(cfg)
    cfg.method='absmed';
end
if ~isfield(cfg,'method')
    cfg.method='absmed';
end
if ~isfield(cfg,'criterion')
    cfg.criterion='mad';
end
if ~isfield(cfg,'critval')
    cfg.critval = 2;
end
if ~isfield(cfg,'channelmajority')
    cfg.channelmajority = floor(0.5 * Nchans);
end

chi=1:size(data.trial{1},1);
if isfield(cfg,'badChan')
    badChani=find(ismember(data.label,cfg.badChan));
    chi(badChani)=[]; %#ok<*FNDSB>
end
%{
switch cfg.method
    case 'abs'
        trials = zeros(length(data.trial),1);
        for chani=1:length(data.trial)
            trials(chani)=mean(mean(abs(data.trial{1,chani}(chi,:))));
        end
    case 'var'
        trials = zeros(length(data.trial),1);
        for chani=1:length(data.trial)
            trials(chani)=var(reshape(data.trial{1,chani}(chi,:),1,length(chi)*size(data.trial{1,1},2)));
        end
end
switch cfg.criterion
    case 'sd'
        thr=median(trials)+cfg.critval*std(trials);
    case 'fixed'
        thr=cfg.critval;
    case 'median'
        thr=median(trials).*(1+cfg.critval);
end

good=find(trials<thr);
bad=find(trials>thr);
badn=num2str(length(bad));
display(['rejected ',badn,' trials']);
%}
% define parameters
switch cfg.method
    case 'absmed'
        Tparameters = zeros(length(data.trial),1);
        for triali=1:length(data.trial)
            % select channels for a particular trial
            selectedchans = data.trial{1,triali};
            % take the median absolute value of each channel per trial
            Tparameters(triali,1:Nchans) = median(abs(selectedchans),2);
        end
    case 'absmax'
        Tparameters = zeros(length(data.trial),1);
        for triali=1:Ntrials
            % select channels for a particular trial
            selectedchans = data.trial{1,triali};
            % take the maximum absolute value of each channel per trial
            Tparameters(triali,1:Nchans) = max(abs(selectedchans),[],2);
        end
    case 'var'
        Tparameters = zeros(length(data.trial),1);
        for triali=1:length(data.trial)
            % select channels for a particular trial
            selectedchans = data.trial{1,triali};
            % take the variance of each channel per trial
            Tparameters(triali,1:Nchans) = var(selectedchans,0,2);
        end
end
figure; plot_epochstats(Tparameters, data.label, data.elec.elecpos, cfg.method);

switch cfg.criterion
    case 'mad'
        Tthr = median(Tparameters,2) + cfg.critval * mad(Tparameters,1,2);
    case 'sd'
        Tthr = median(Tparameters,2) + cfg.critval * std(Tparameters,0,2);
    case 'fixed'
        Tthr = cfg.critval;
    case 'median'
        Tthr = median(Tparameters,2) .* (1 + cfg.critval);
end
figure; plot_epochstatsYthreshold(Tparameters', Tthr, data.label, ...
    data.elec.elecpos, cfg.method); % needs to be trasposed to sort by channels first

% use parameters for deciding which channels to reject
    TrialReject = [];
for chani=1:length(data.trial)
    trialrejecti = find(Tparameters(:,chani) > Tthr);
    TrialReject = [TrialReject, trialrejecti];
end
% find unique trial numbers
uniqueTR = unique(TrialReject);
% count number of repeated trials
countOfTR = hist(TrialReject,uniqueTR);
% find repeated count of trials that are greater than 'majorityvote'
indexToRepeatedValue = (countOfTR >= cfg.channelmajority);
% and find the trial numbers the indices correspond to
badtrials = uniqueTR(indexToRepeatedValue);
badn=num2str(length(badtrials));
display(['rejected ',badn,' trials']);

% if plotdata
%     figure;
%     plot(trials,'o')
%     hold on
%     plot(bad,trials(bad),'r.')
%     xlim([-5 length(trials)+5])
% end

trialsToKeep = 1:length(data.trial); % initialize vector with all trial indices
trialsToKeep(badtrials) = []; % remove the trials that should go
dataClean = ft_selectdata(data, 'rpt', trialsToKeep);
dataClean.cfg.conditionlabel(badtrials) = [];
dataClean.cfg.trl(badtrials,:) = [];
dataClean.cfg.thresholds = Tthr;
dataClean.cfg.parameters = Tparameters;
dataClean.cfg.badparameters = TrialReject;
%% %% Jumps in data: - perform after segmentation
% It is very important to remove all jump and muscle artifacts before running your ICA,
% otherwise they may change the results you get. To remove artifacts on the example dataset, use:
% jump:
% channel selection, cutoff and padding:
%     cfg_jump.trl        = dataTrl.cfg.trl;
%     cfg_jump.continuous = 'yes';
%     cfg_jump.artfctdef.zvalue.channel    = 'EEG';
%     cfg_jump.artfctdef.zvalue.cutoff     = 10;
%     cfg_jump.artfctdef.zvalue.trlpadding = 0;
%     cfg_jump.artfctdef.zvalue.artpadding = 0;
%     cfg_jump.artfctdef.zvalue.fltpadding = 0;
%
%     % algorithmic parameters
%     cfg_jump.artfctdef.zvalue.cumulative    = 'yes';
%     cfg_jump.artfctdef.zvalue.medianfilter  = 'yes';
%     cfg_jump.artfctdef.zvalue.medianfiltord = 6 ;
%     cfg_jump.artfctdef.zvalue.absdiff       = 'yes';
%
%     % make the process interactive
%     cfg_jump.artfctdef.zvalue.interactive = 'no';
%     [cfg_jump_output, artifact_jump]      = ft_artifact_zvalue(cfg_jump,dataTrl);
%
%     cfg_jump                         = [] ;
%     cfg_jump.artfctdef.reject        = 'complete'; %  'complete', use 'partial' if you want to do partial artifact rejection
%     cfg_jump.artfctdef.jump.artifact = artifact_jump ;
%     %cfg.artfctdef.muscle.artifact = artifact_muscle;
%     data_no_jumps = ft_rejectartifact(cfg_jump, dataTrl) ;
%     uhplot(data_no_jumps)
%