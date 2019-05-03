function event = uh_event(a,shift)
%% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% input - any text file that contains useful event markers
%  +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%% output should contain the following structure:
% type: 'Stimulus'
% value: 'S  2'
% sample: 54843 --- onset of event in samples
% duration: 1
% offset: 0
%% a - structure looks like this
% 'Task',           StartTime,    StopTime,   TaskLabel;
% 'explore',        16720,        28560,         1;
% 'reach-offer',    29050,        30270,         6;
% 'attentive rest' ,31130,        39070,         7;
%+++++++++++++++++++++++++++++++++++++++++++++++++
% 3/18/2015 [mlearnx - to be improved]
% see also [a= importRawEvent(filename, startRow, endRow)]

% if ~exist('Fs','var'), Fs = 1000; end ;

eventlength = length(a(:,4))-1; % identify number of events to create BST structure
event = repmat(struct('type','','value','', 'duration',1,'offset',[],'Stoptime',[],'condition',[]), 1, eventlength); % create FT event structure

for ii = 1:eventlength
    event(1,ii).type = 'Stimulus';
    event(1,ii).value = a(ii+1,1); % I must change from integer to actual class labels
    event(1,ii).sample = str2double(a{ii+1,2})+shift; % Class Start Time in samples
    event(1,ii).duration = 2;
    event(1,ii).offset = 0;
    event(1,ii).Stoptime = str2double(a{ii+1,3})+shift; % Class Stop time in samples - here, the class means event
    event(1,ii).condition = str2double(a{ii+1,4});
    event(1,ii).cond_name = a{ii+1,1};
end


