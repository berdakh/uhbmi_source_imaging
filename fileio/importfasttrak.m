function elec = importfasttrak(filename, startRow, endRow)
%IMPORTFASTRAK Import numeric data from a text file as a matrix.
% input - .elp file w/(x,y,z) coordinates 
% header information should be cleaned

% Example: to read the file 'test_electrode.elp', just type 
%           elec = importfasttrak('test_electrode_08262015.elp');
% Generated by: Zach Hernandez, University of Houston, 2015

%% Initialize variables.
delimiter = '\t';
if nargin<=2
    startRow = 9;
    endRow = inf;
end

%% Format string for each line of text:
%   column1: text (%s)
%	column2: text (%s)
%   column3: text (%s)
%	column4: text (%s)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%s%s%s%[^\n\r]';

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
elpfile = [dataArray{1:end-1}];

%% create FT structure 
elec.type = 'eeg1020';
elec.unit = 'mm';
elec.cfg = [];
%++++++++++++++++++++++++++++++++++++++++++++++++++
% extract channels (w/fiducials)
 j=1;
 for i=1:size(elpfile,1);     
     if strcmp(elpfile{i,1},'%F');
         switch j
             case 1
                 elec.label{1} = 'Nasion'; 
                 elec.chanpos(1,:) = str2double(elpfile(i,2:4));
                 elec.chanpos(1,:) = str2double(elpfile(i,2:4));
             case 2
                 elec.label{2} = 'A1'; 
                 elec.chanpos(2,:) = str2double(elpfile(i,2:4));
                 elec.chanpos(2,:) = str2double(elpfile(i,2:4));                 
             case 3
                 elec.label{3} = 'A2'; 
                 elec.chanpos(3,:) = str2double(elpfile(i,2:4));
                 elec.chanpos(3,:) = str2double(elpfile(i,2:4));
         end
         j=j+1;
     elseif strcmp(elpfile{i,1},'%N'); 
         elec.label{j} = strtrim(elpfile{i,2}); 
         elec.chanpos(j,:) = str2double(elpfile(i+1,1:3));
         elec.elecpos(j,:) = str2double(elpfile(i+1,1:3));
         j=j+1;
     end 
 end
%++++++++++++++++++++++++++++++++++++++++++++++++++
% extract fiducials  
nas = ismember(elec.label, 'Nasion');
elec.fiducial.nas = elec.chanpos(nas,:);
%++++++++++++++++++++++++++++++++++++++++++++++++++
zpoint =ismember(elec.label, 'Cz');
elec.fiducial.zpoint = elec.chanpos(zpoint,:);
%++++++++++++++++++++++++++++++++++++++++++++++++++
lpa = ismember(elec.label, 'A1');
elec.fiducial.lpa = elec.chanpos(lpa,:);
%++++++++++++++++++++++++++++++++++++++++++++++++++
rpa = ismember(elec.label, 'A2');
elec.fiducial.rpa = elec.chanpos(rpa,:); 
end  %EOF

