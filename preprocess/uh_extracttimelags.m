function [ eeglags, classlabel, eeglaglabels ] = uh_extracttimelags( classdata, classlabel, lag )
% This function extracts features of EEG where time is shifted about w
%   INPUT:  shift       --> time sample that indicates the start of the
%                           experiment session
%           classinfo   --> list of trials where the class name, start time
%                           sample, end time sample, and class label are 
%                           indicated for each trial row (i.e. N trials X
%                            4 class attributes)
% Created by: Zach Hernandez, University of Houston, 2015

if nargin < 3
    fs = classdata.fsample;
    lag = round((0:0.010:0.090)*fs);
end

max_lag=length(lag);
eeg = classdata.trial{1}(:,1:length(classlabel))';

eeglags = timelag(eeg, lag);     % generate feature matrix
classlabel = classlabel(max_lag:end);     % truncate target vector to maintain same number of rows

eeglaglabels = struct(); % define data structure of feature labels
for el = 1:length(lag);
    for chn = 1:length(classdata.label);
        eeglaglabels( (chn*length(lag)) - (length(lag)-el) ).Chan = classdata.label{chn};
        eeglaglabels( (chn*length(lag)) - (length(lag)-el) ).Lag = lag(el);
    end
end

end  %EOF