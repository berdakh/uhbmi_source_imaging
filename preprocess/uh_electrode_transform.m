function electrode = uh_electrode_transform(channel) 
% 3/17/2015 --- mlearnx 

% FieldTrip - electrode structure
%     chanpos: [68x3 double]
%     elecpos: [68x3 double]
%       label: {68x1 cell}
%        type: 'egi64'
%        unit: 'cm'
% Brainstorm electrode structure  
%        Name: 'Fp1'
%     Comment: ''
%        Type: 'EEG'
%         Loc: [3x1 double]
%      Orient: []
%      Weight: 1

chanpos = zeros(length(channel),3);
label = cell(length(channel),1);

for ii = 1:length(channel)
    chanpos(ii,:) = channel(ii).Loc.*700';    
    label{ii,:} = channel(ii).Name;  
end

electrode.chanpos = chanpos;
electrode.elecpos = chanpos;
electrode.label = label;
electrode.type = 'eeg1020';
electrode.unit = 'mm';
end 