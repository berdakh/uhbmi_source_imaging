function elec = uh_importcaptrak(filename, startRow, endRow)
%IMPORTCAPTRAK 
% input - .txt file (x,y,z) coordinates 
% header information should be cleaned 
%% Initialize variables.
delimiter = '\t';
if nargin < 3
    endRow = 78;
end
if nargin < 2
    %% Format string for each line of text:
    formatSpecpre = '%s%[^\n\r]';

    %% Open the text file.
    fileIDpre = fopen(filename,'r');

    %% Read columns of data to find the Start Row
    dataArraypre = textscan(fileIDpre, formatSpecpre, 'Delimiter', '', 'WhiteSpace', '',  'ReturnOnError', false);
    findstartRow = zeros(1,length(dataArraypre{1}));
    for idx=1:78; findstartRow(idx)=double(~isempty(cell2mat(strfind(dataArraypre{1,1}(idx),'Electrode'))));end
    startRow = find(findstartRow==1)+1;
end

%% Format string for each line of text:
formatSpec = '%s%f%f%f%*s%*s%*s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
for block=2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end
%% Close the text file.
fclose(fileID);

%% Create output variable
dataArray([2, 3, 4]) = cellfun(@(x) num2cell(x), dataArray([2, 3, 4]), 'UniformOutput', false);
electrode = [dataArray{1:end-1}];

%% create FT structure 
elec.chanpos = cell2mat(electrode(:,2:4));
elec.elecpos = cell2mat(electrode(:,2:4));
elec.label = electrode(:,1);
elec.type = 'eeg1020';
elec.unit = 'mm';
elec.cfg = [];
%++++++++++++++++++++++++++++++++++++++++++++++++++
% change the labels for the ground and reference  
GND = ismember(elec.label, 'GND');
elec.label{GND} = 'AFz';
REF = ismember(elec.label, 'REF');
elec.label{REF} = 'FCz';
%++++++++++++++++++++++++++++++++++++++++++++++++++
% extract fiducials  
nas = ismember(elec.label, 'Nasion');
elec.fiducial.nas = elec.chanpos(nas,:);
%++++++++++++++++++++++++++++++++++++++++++++++++++
zpoint =ismember(elec.label, 'Cz');
elec.fiducial.zpoint = elec.chanpos(zpoint,:);
% %++++++++++++++++++++++++++++++++++++++++++++++++++
lpa = ismember(elec.label, {'A1','LPA'});
elec.fiducial.lpa = elec.chanpos(lpa,:);
%++++++++++++++++++++++++++++++++++++++++++++++++++
rpa = ismember(elec.label, {'A2','RPA'});
elec.fiducial.rpa = elec.chanpos(rpa,:);
end 

