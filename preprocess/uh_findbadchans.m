function uh_findbadchans(eegdata, channels)
%find bad channels
eegdata = dataTrl
% cfg.dataset=eegdata;
cfg.trialdef.poststim=2;
cfg.trialfun='trialfun_beg';
cfg1=ft_definetrial(cfg,eegdata);

str='{';for i=1:channels;str=[str,' ','''Ch',num2str(i),''''];end;str=[str,'}'];
eval(['chans=',str,';']);

cfg1 = [];
cfg1.channel='EEG';
cfg1.hpfilter='yes';
cfg1.hpfreq=1;
display('reading and filtering')
eegdata=ft_preprocessing(cfg1,eegdata);
trial=zeros(size(eegdata.trial{1,1}));

display('sorting channels')
for i=1:channels
    for j=1:channels
        if strcmp(['A',num2str(i)],eegdata.label{j,1})
            trial(i,:)=eegdata.trial{1,1}(j,:);
        end
    end
end
trial=trial.*10^5;
% sd=median(std(trial'));
sd=0.3;

screen_size = get(0, 'ScreenSize');
firstChan=1;
% for i=1:4;
lastChan=58;
chans=firstChan:lastChan;
chart=zeros(58,size(eegdata.trial{1,1},2));
for chan=1:58
    ch=trial(chans(chan),:);
    ch=ch-mean(ch); % BL correction
    ch(ch>2)=2;
    ch(ch<-2)=-2;
    chart(chan,:)=ch-chan*sd*10;
end
ch=firstChan:2:lastChan;
%     for chTick=1:29
%         ticks{1,(10-chTick)}=['A',num2str(ch(chTick))];
%     end
%
figure1 = figure('XVisual','0x23 (TrueColor, depth 32, RGB mask 0xff0000 0xff00 0x00ff)','Position', [0 0 screen_size(3) screen_size(4) ]);
% axes1 = axes('Parent',figure1),'YTickLabel',ticks);
box('on');
hold('all');

plot(eegdata.time{1,1},chart,'Parent',axes1)

title(['Channels A',num2str(firstChan),' to A',num2str(lastChan)]);
%     firstChan=firstChan-62;
ylim([-190 0]);
% end
