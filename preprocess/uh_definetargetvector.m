function [ classlabel ] = uh_definetargetvector( shift, classinfo )
% This function generates a class label vector using both start and 
% stop time segments of each trial
%   INPUT:  shift       --> time sample that indicates the start of the
%                           experiment session
%           classinfo   --> list of trials where the class name, start time
%                           sample, end time sample, and class label are 
%                           indicated for each trial row (i.e. N trials X
%                            4 class attributes)
% Created by: Zach Hernandez, University of Houston, 2015

%% Definitions
classinfo_double = str2double(classinfo(2:end, 2:end));
trialtimes = classinfo_double(:,1:2) + shift;
trialcodes = classinfo_double(:,3);
sessionlength = max(trialtimes(:));

%% generate target vector
classlabel = zeros(sessionlength,1);
for triali = 1:length(trialcodes)
    if trialtimes(triali,1) < 0 || trialtimes(triali,2) < 0 
        continue;
    else
        classlabel(trialtimes(triali,1):trialtimes(triali,2)) = trialcodes(triali,1);
    end
end

end  %EOF