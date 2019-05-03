function dat = uh_classextract(data)
% THIS FUNCTION WAS WRITTEN IN RUSH THEREFORE IT MAY NOT BE THE OPTIMAL FOR
% GENERAL CLASS SEPERATION. IT IS USEFUL FOR FT PROCESSING PIPELINE
% USE THIS FUNCTION TO EXTRACT DIFFERENT CLASS/CONDITIONS
% 3/21/2015 - mlearnx

%% INPUT - IS THE ARTIFACT CLEANED DATA
selectedCls = unique(data.trialinfo);
for ii = 1:max(unique(data.trialinfo)) % IDENTIFY THE NUMBER OF CLASSES IN THE DATA
    if isempty(find(data.trialinfo == ii, 1));
        continue;
    elseif any(~ismember(ii,selectedCls))
        continue;
    else 
        class.index{ii} = find(data.trialinfo ==ii);
        class.sampleinfo{ii} = [data.sampleinfo(class.index{ii},1),data.sampleinfo(class.index{ii},1)];
        class.trialinfo{ii} = ones(length(data.sampleinfo(class.index{ii},1)),1)*ii;
        class.conditionlabel{ii} = data.cfg.conditionlabel{class.index{ii}};
    end
end
%%
dat = cell(1,length(class.index));
for ii = 1:length(class.index)
    if any(~ismember(ii,selectedCls))
        continue;
    else
    cfg = [];
    cfg.trials = class.index{ii};
    dat{ii} = ft_selectdata(cfg,data);
    dat{ii}.conditionlabel = class.conditionlabel{ii};
    end
end 
%%
% for jj = 1:length(unique(data.trialinfo))
%     event = repmat(struct('type','','value','', 'duration',1,'offset',[],'Stoptime',[],'Condition',[]), 1, length(class.index{jj}));
%     % create FT event structure
%     for ii = 1:length(class.index{jj})
%         % FIRST CREATE FT EVENT STRUCTURE
%         event(1,ii).type = 'Stimulus';
%         event(1,ii).value = class.trialinfo{jj}(ii,1); % Actual class labels
%         event(1,ii).sample = class.sampleinfo{jj}(ii,1); % Class Start Time in samples
%         event(1,ii).duration = 1;
%         event(1,ii).offset = 0;
%         event(1,ii).Stoptime = class.sampleinfo{jj}(ii,2); % Class Stop time in samples - here, the class means event
%         event(1,ii).condition = class.trialinfo{jj}(ii,1); % class labels
%         trl(ii,:) = [event(1,ii).sample,event(1,ii).Stoptime,0,class.trialinfo{jj}(ii,1)];
%     end
%     evento{jj} = event;
%     trial{jj} = trl;
%     clear trl;
% end
% dat = cell(1,length(evento));
% % CALL FT_REDEFINE FUNCTION WITH THE AFOREPREPARED EVENT MARKERS
% % THIS WILL RESULT IN DIFFERENT DATASETS SAVED IN CELL STRUCTURE
% for kk =1:length(evento)
%     cfg = [];
%     fprintf('Extracting class %d - from the data\n',kk);
%     %     cfg.trialfun= @ft_trialfun_general;
%     cfg.trialdef= trialdef;
%     cfg.callinfo= data.cfg.callinfo;
%     cfg.version = version;
%     cfg.trackconfig='off';
%     cfg.checkconfig=data.cfg.checkconfig;
%     cfg.checksize=data.cfg.checksize;
%     cfg.showcallinfo='yes';
%     cfg.debug='no';
%     cfg.trackcallinfo='yes';
%     cfg.trackdatainfo='yes';
%     cfg.trackparaminfo='yes';
%     cfg.elec = data.elec;
%     cfg.trials = 'all';
%     cfg.event = evento{kk};
%     cfg.trl =  trial{kk};
%     %     warning('off');
%     dat{kk} = ft_redefinetrial(cfg, data);
% end
end