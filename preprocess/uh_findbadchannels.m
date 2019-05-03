function [badchans,Cparameters,Cthr,ChanReject]  = uh_findbadchannels(cfg,data)
%%=========================================================================
% Finds bad channels in given EEG/MEG data 
%=========================================================================   
% Input: Segmented data in trials 
% output: bad channel labels 
% 5/27/2015 

% pre-initialize (if no 'cfg' parameters given)
Nchans = length(data.label);
Ntrials = length(data.trial);

if nargin==1
    data = cfg;
    cfg = [];
end
if isempty(cfg)
    cfg.method = 'var';
end
if ~isfield(cfg,'method')
    cfg.method = 'var';
end
if ~isfield(cfg,'criterion')
    cfg.criterion = 'medsd';
end
if ~isfield(cfg,'critval')
    cfg.critval = 1;
end
if ~isfield(cfg,'trialmajority')
    cfg.trialmajority = floor(0.4 * Ntrials);
end
% define parameters
switch cfg.method
    case 'absmed'
        Cparameters = zeros(length(data.trial),1);
        for triali=1:Ntrials
            % select channels for a particular trial
            selectedchans = data.trial{1,triali};
            % take the median absolute value of each channel per trial
            Cparameters(triali,1:Nchans) = median(abs(selectedchans),2);
        end
    case 'absmax'
        Cparameters = zeros(length(data.trial),1);
        for triali=1:Ntrials
            % select channels for a particular trial
            selectedchans = data.trial{1,triali};
            % take the maximum absolute value of each channel per trial
            Cparameters(triali,1:Nchans) = max(abs(selectedchans),[],2);
        end
    case 'var'
        Cparameters = zeros(length(data.trial),1);
        for triali=1:Ntrials
            % select channels for a particular trial
            selectedchans = data.trial{1,triali};
            % take the variance of each channel per trial
            Cparameters(triali,1:Nchans) = var(selectedchans,0,2);
        end
end
figure; plot_epochstats(Cparameters, data.label, data.elec.elecpos, cfg.method);

switch cfg.criterion
    case 'mad'                 % median absolute deviation
        Cthr = median(Cparameters) + cfg.critval * mad(Cparameters,1);
    case 'sd'                  % standard deviation
        Cthr = median(Cparameters) + cfg.critval * std(Cparameters);
    case 'fixed'               % fixed constant
        Cthr = cfg.critval;
    case 'median'              % median
        Cthr = median(Cparameters) .* (1 + cfg.critval);
    case 'medsd'               % median-based standard deviation
        ms = sqrt(nanmean(power(Cparameters - repmat(nanmedian(Cparameters), size(Cparameters,1),1),2),1));
        Cthr = median(Cparameters) + cfg.critval .* ms; 
end

figure; plot_epochstatsYthreshold(Cparameters', Cthr, data.label, ...
    data.elec.elecpos, cfg.method); % needs to be trasposed to sort by channels first

% use parameters and thresholds for deciding which channels to reject
ChanReject = [];
for triali=1:length(data.trial)
    chanrejecti = find(Cparameters(triali,:) > Cthr);
    ChanReject = [ChanReject, chanrejecti];
end
%{
channels = length(dataTrl.label);
VAR=[]; VARm = []; badi = [];

for triali=1:length(dataTrl.trial)
    % select channels for a particular trial
    selectedchans = dataTrl.trial{1,triali};
    % take the variance of each channel per trial
    VAR(triali,1:channels) = var(selectedchans,0,2);
    % take the standard deviation of each channel per trial
    STD(triali,1:channels) = sqrt(VAR(triali,1:channels));
    % find the minimum variance
    VARm(triali,1:channels) = min(VAR(triali,:),[],1);
    % find channels that contain the minimum variance to N times the median
    badchans = find(VARm(triali,:)>8*median(VARm(triali,:)));
    badi = [badi, badchans];
end
%}
% find unique trial numbers
uniqueCR = unique(ChanReject);
% count number of repeated channels
countOfCR = hist(ChanReject,uniqueCR);
% find repeated count of trials that are greater than 'majorityvote'
indexToRepeatedValue = (countOfCR >= cfg.trialmajority);
% and find the trial numbers the indices correspond to
repeatedValues = uniqueCR(indexToRepeatedValue);
% for displaying purposes
badn=num2str(length(repeatedValues));
display(['rejected ',badn,' channels']);
% find the channel labels they correspond to and output
badchans = data.label(repeatedValues);

% cfg.dataset=source;
% cfg.trialdef.poststim=10;
% cfg.trialfun='trialfun_beg';
% cfg1=ft_definetrial(cfg);
% 
% str='{';for i=1:channels;str=[str,' ','''A',num2str(i),''''];end;str=[str,'}'];
% eval(['chans=',str,';']);
% 
% cfg1.channel='EEG';
% cfg1.hpfilter='yes';
% cfg1.hpfreq=3;
% 
% display('reading and filtering')
% data=ft_preprocessing(cfg1);
% 
% trial=zeros(size(dataTrl.trial{1,1}));
% 
% display('sorting channels')
% 
% for i=1:channels
%     for j=1:channels
%         if strcmp(['EEG',num2str(i)],data.label{j,1})
%             trial(i,:)=data.trial{1,1}(j,:);
%         end
%     end
% end
% 
% trial=trial.*10^12;
% % sd=median(std(trial'));
% sd=0.3;
% 
% firstChan=64;
% % for i=1:4;
%     lastChan=firstChan+61;
%     chans=firstChan:lastChan;
%     chart=zeros(62,size(data.trial{1,1},2));
%     for chan=1:62
%         ch=trial(chans(chan),:);
%         ch=ch-mean(ch); % BL correction
%         ch(ch>2)=2;
%         ch(ch<-2)=-2;
%         chart(chan,:)=ch-chan*sd*10;
%     end
%     ch=firstChan:7:lastChan;
% % end
% 
% % cfg1.hpfreq=55;
% % display('estimating noise')
% % data20hp=ft_preprocessing(cfg1);
% % noiseTrial=zeros(size(data.trial{1,1}));
% % display('sorting channels')
% % for i=1:channels
% %     for j=1:channels
% %         if strcmp(['A',num2str(i)],data20hp.label{j,1})
% %             noiseTrial(i,:)=data20hp.trial{1,1}(j,:);
% %         end
% %     end
% % end
% % noise=std(noiseTrial');sdnoise=find(noise>((median(noise))*2))
% end 