function [d, neighbours] = uh_removechannel(data,option,badchans,misChanFlag,elec)
% This function does 3-changes to the data structure
% option [remove,replace_labels,interpolate] - badchannels
% in case of label replacement the badchans should contain
% {'oldLabel','oldLabel','newLabel','newLabel'}
% badchans = {'Fz', 'Cz'}; %channelList;

if strcmp(option,'remove_peripheral') % REMOVE CHANNELS
    if ~exist('badchans','var')
        badchans = {'FT10','TP10','PO10','PO9','TP9','FT9'};
    end
    if ~exist('elec','var')
        load elec_aligned;
    end
    data.label = elec.label;
    data.elec = elec; % load digitized electrode positions
    allchans = data.label;
    %%
    idx = ismember(allchans, badchans);
    new_chanlist = allchans(~idx);
    %% update structure
    data.label = new_chanlist;
    data.elec.label = new_chanlist;
    data.elec.chanpos = data.elec.chanpos(~idx,:,:);
    data.elec.elecpos = data.elec.elecpos(~idx,:,:);
    data.elec.label = new_chanlist;
    %%
    for jj = 1:length(data.trial);
        data.trial{jj} = data.trial{jj}(~idx,:);
    end
    ft_plot_sens(data.elec,'style','sk','label','on');
    d = data;
    %% another example/way to do it
    % allchan = ft_read_header(dataset);
    % (preprocess)
    %% allchan.label = [allchan.label; implicitref];
    % (after artifact rejection/ICA/etc.)
    % badchan  = ft_channelselection('gui', allchan.label);
    % This gives me the channel labels for all channels, with the implicitref
    % added back in (normally this is removed), then a gui which lets me remove
    % bad channels manually after preprocessing/artifact rejection/ICA/etc.
    
elseif strcmp(option,'replace') % REPLACE CHANNEL LABELS
    for ii = 1:length(badchans)/2
        chanindx = strcmp(data.label,badchans{ii});
        data.label{chanindx} = badchans{ii+length(badchans)/2};
    end
    d = data;
elseif strcmp(option,'interpolate') % Channel Replace - get nearest neighbours
    if misChanFlag == 1
        missingchans = badchans;
        badchans = {};
    else
        missingchans = {};
    end
    cfg                      = [];
    cfg.method               = 'triangulation';
    cfg.layout               = 'easycap_layout.mat';
    cfg.neighbourdist        = 0.3;
    [neighbours]             = ft_prepare_neighbours(cfg,data);
    % Interpolate and put into new data structure
    %%
    cfg                      = [];
    cfg.badchannel           = badchans;
    cfg.missingchannel       = missingchans;
    cfg.layout               = 'easycap_layout.mat';
    cfg.method               = 'spline';
    cfg.neighbours           = neighbours;
    cfg.neighbourdist        = 0.3;
    d = ft_channelrepair(cfg,data);
elseif strcmp(option,'exclude') && ~isempty(badchans) % Remove Channels and Labels
    if ~exist('elec','var')
        load easycap64_elec;
    end
    data.label = elec.label;
    data.elec = elec; % load digitized electrode positions
    allchans = data.label;
    
    idx = ismember(allchans, badchans);
    new_chanlist = allchans(~idx);
    
    %% update structure
    data.cfg.badchannel = badchans;
    data.label = new_chanlist;
    data.elec.label = new_chanlist;
    data.elec.chanpos = data.elec.chanpos(~idx,:,:);
    data.elec.elecpos = data.elec.elecpos(~idx,:,:);
    data.elec.label = new_chanlist;
    %%
    for jj = 1:length(data.trial);
        data.trial{jj} = data.trial{jj}(~idx,:);        
    end
    ft_plot_sens(data.elec,'style','sk','label','on');
    d = data;
elseif isempty(badchans)
    %% MMM : If there are no bad channels return data, set the default value for d
    d = data;
    return;
else
    %% MMM : If there are no bad channels return data set the default value for d
    d = data;
    return;
end
if exist('d','var'); disp(d); end
end

% old one

%{
% if strcmp(option,'remove_peripheral') % REMOVE CHANNELS
%     if ~exist('badchans','var')
%         badchans = {'FT10','TP10','PO10','PO9','TP9','FT9'};
%     end
%     allchans = data.label;
%     %
%     idx = ismember(allchans, badchans);
%     new_chanlist = allchans(~idx);
%     % update structure
%     data.label = new_chanlist;
%     data.elec.label = new_chanlist;
%     data.elec.chanpos = data.elec.chanpos(~idx,:,:);
%     data.elec.elecpos = data.elec.elecpos(~idx,:,:);
%     data.elec.label = new_chanlist;
%     %
%     for jj = 1:length(data.trial);
%         data.trial{jj} = data.trial{jj}(~idx,:);
%     end
%     ft_plot_sens(data.elec,'style','sk','label','on');
%     d = data;
%     % another example/way to do it
%     allchan = ft_read_header(dataset);
%     (preprocess)
%     % allchan.label = [allchan.label; implicitref];
%     (after artifact rejection/ICA/etc.)
%     badchan  = ft_channelselection('gui', allchan.label);
%     This gives me the channel labels for all channels, with the implicitref
%     added back in (normally this is removed), then a gui which lets me remove
%     bad channels manually after preprocessing/artifact rejection/ICA/etc.
%
% elseif strcmp(option,'replace') % REPLACE CHANNEL LABELS
%     for ii = 1:length(badchans)/2
%         chanindx = strcmp(data.label,badchans{ii});
%         data.label{chanindx} = badchans{ii+length(badchans)/2};
%     end
%     d = data;
% elseif strcmp(option,'interpolate') % Channel Replace - get nearest neighbours
%     cfg                      = [];
%     cfg.method               = 'distance';
%     cfg.layout               = 'easycap_layout.mat';
%     cfg.neighbourdist        = 0.2;
%     [neighbours]             = ft_prepare_neighbours(cfg,data);
%
%     Interpolate and put into new data structure
%     %
%     cfg                      = [];
%     cfg.badchannel           = badchans;
%     cfg.layout               = 'easycap_layout.mat';
%     cfg.method               = 'nearest';
%     cfg.neighbours           = neighbours;
%     cfg.neighbourdist        = 0.13;
%     d = ft_channelrepair(cfg,data);
% else
%     return;
% end
% disp(d)
% end
%}