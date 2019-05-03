function [dComp, dataClean] = uh_ica(data,option)
% perform ICA and plot topography

%%
cfg= [];
cfg.method = 'runica';
dComp = ft_componentanalysis(cfg, data);
%---------------------------------------------------------
% PLOT ICA COMPONENT
cfg = [];
cfg.component = [1:10];       % specify the component(s) that should be plotted
cfg.layout = 'easycap_layout.mat'; % specify the layout file that should be used for plotting
cfg.continuous = 'no';
cfg.comment = 'no';
cfg.viewmode = 'component';
ft_databrowser(cfg, dComp);
warning('off')

%{
% compute a frequency decomposition of all components and the ECG
cfg            = [];
cfg.method     = 'mtmfft';
cfg.output     = 'pow';
cfg.foi        = [0:0.1:40];
cfg.taper      = 'hanning';
cfg.pad        = 'maxperlen';
freqdComp      = ft_freqanalysis(cfg, dComp);

% PLOT Frequency Analysis Results
figure;  imagesc(freqdComp.freq,(1:length(freqdComp.label)),freqdComp.powspctrm);
set(gca,'YTick',(1:length(freqdComp.label)),'YTickLabel',freqdComp.label);

figure;  plot(freqdComp.freq,freqdComp.powspctrm);
legend(freqdComp.label);
%}

    if strcmp(option,'reject')    
        %% REJECT BAD ICA COMPONENTS
        % remove the bad components and backproject the data
        component = [];
        while true
            comp = input('input bad component (to exit enter 0):');
            component = [component, comp];
            if comp == 0
                break;
            end
        end    
        cfg = [];
        cfg.component = component; 
        dataClean = ft_rejectcomponent(cfg, dComp, data);    
    end
%% declare that you completed the pre-processing step 
cfg = [];
cfg.trialdef.eventtype      = 'STATUS';
cfg.artifact.reject         = 'complete';
cfg.channel                 = 'EEG';
dataClean = ft_preprocessing(cfg, dataClean);


