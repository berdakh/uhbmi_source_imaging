function classstartstoptimes = uh_importRawEvent_wHandInfo(filename, startRow, endRow)
%IMPORTFILE Import numeric data from a text file as a matrix.
%   CLASSSTARTSTOPTIMES = IMPORTFILE(FILENAME) Reads data from text file
%   FILENAME for the default selection.
%
%   CLASSSTARTSTOPTIMES = IMPORTFILE(FILENAME, STARTROW, ENDROW) Reads data
%   from rows STARTROW through ENDROW of text file FILENAME.
%
% Example:
%   classstartstoptimes = importfile('class start-stop times.txt', 2, 136);
%
%    See also TEXTSCAN.

% Auto-generated by MATLAB on 2014/07/01 17:43:25

%% Initialize variables.
delimiter = '\t';
if nargin<=2
    startRow = 1;
    endRow = inf;
end

%% Read columns of data as strings:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%s%s%s%s%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Check if text file exists and if not return out of function
if fileID == -1
    disp('Warning: No ''class start-stop times'' text file exists in this folder');
    classstartstoptimes = {};
    return
end

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

%% Convert the contents of columns containing numeric strings to numbers.
% Replace non-numeric strings with NaN.
lastrow = find(strcmp(dataArray{1},'') == 1, 1 );
for col = 1:length(dataArray)
    dataArray{col} = dataArray{col}(1:lastrow-1);
end
raw = [dataArray{:,[1:4,6]}];
%%%  start MMM : This line of code is added to remove any lines before the header
%%%  like 'Synchorinziation' title that is added 
removefirstline = 0;
for i = 1:length(raw(1,:))
    if strcmp(raw(1,i), '')
        removefirstline  = 1;
    end
end
if removefirstline == 1
    raw(1,:) = [];
end
%%% end MMM
classstartstoptimes = raw;
%{
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[2,3,4]
    % Converts strings in the input cell array to numbers. Replaced non-numeric
    % strings with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1);
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData{row}, regexstr, 'names');
            numbers = result.numbers;
            
            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if any(numbers==',');
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(thousandsRegExp, ',', 'once'));
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric strings to numbers.
            if ~invalidThousandsSeparator;
                numbers = textscan(strrep(numbers, ',', ''), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch me
        end
    end
end

%% Split data into numeric and cell columns.
rawNumericColumns = raw(:, [2,3,4]);
rawCellColumns = raw(:, [1,5]);


%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

%% Create output variable
% classstartstoptimes = dataset;
classstartstoptimes{:,1} = rawCellColumns(:, 1);
classstartstoptimes{:,2} = (rawNumericColumns(:, 1));
classstartstoptimes{:,3} = (rawNumericColumns(:, 2));
classstartstoptimes{:,4} = (rawNumericColumns(:, 3));
%}