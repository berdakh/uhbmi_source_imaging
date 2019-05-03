function data = uh_importIMU2FT(OPALdata,varargin)
%% Import a IMU sensor data structure and convert into FieldTrip data structure
%   Input: OPALdata --> data structure that contains a field for each
%                       sensor.
%  Output:     data --> new data structure where each subfield is 
%                       configured for FieldTrip toolbox functions.
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Created by: Zach Hernandez, University of Houston, 2015
%% initialize data structure
data = struct();
%% Check optional inputs
if nargin == 2
    senslistIDX = varargin{1};
elseif nargin > 2
    senslistIDX = varargin{1};
    list_subfields = varargin{2};
else
    senslistIDX = 1:length(OPALdata);
    list_subfields = {'accel_gravcomp','velo_hpf'};
end
%{
%% specify which text file of IMU ID numbers to use 
% (depends on the year experiment was conducted)
     if ~isempty(strfind(filename,'2014')) || ~isempty(strfind(filename,'2015'));
         IMUlist_filename = 'IMUSensorIDNumbers_post2013.txt';
     elseif ~isempty(strfind(filename,'2013'));
         IMUlist_filename = 'IMUSensorIDNumbers_2013.txt';
     end

%% open and save into variable the list of sensor ID numbers
fileID = fopen(IMUlist_filename,'r');
imu_id_list = textscan(fileID,'%s%s','Delimiter','\t');
fclose(fileID);

%% extract information from each OPAL sensor
OPALdata = uh_extractIMUinfo(filename, imu_id_list);
%
%% for reading the HDF5 file format
try
    vers = h5readatt(filename,'/','FileFormatVersion');
catch ME
    try
        vers = h5readatt(filename,'/','File_Format_Version');
    catch ME
        error('Couldn''t determine file format');
    end
end
if vers< 2
    error('This example only works with version 2 or later of the data file')
end

caseIdList = hdf5read(filename,'/CaseIdList');      % Difficult to convert to h5read


for SI = 1:size(caseIdList,1);
    % read sensor ID numbers and place as a directory path string
    SensorIDNumbers = ['/' caseIdList(SI).data];

    % read in measurement directory paths
    Accelerations_Path = [SensorIDNumbers '/Calibrated/Accelerometers']; %Data path to be read
    Gyroscopes_Path = [SensorIDNumbers '/Calibrated/Gyroscopes']; %Data path to be read
    Magnetometers_Path = [SensorIDNumbers '/Calibrated/Magnetometers']; %Data path to be read
    Orientation_Path  = [SensorIDNumbers '/Calibrated/Orientation']; %Data path to be read
    Time_Path  = [SensorIDNumbers '/Time']; %Data path to be read

    % and use paths to acquire measurements into Matlab data structure
    OPALdata(SI).annotat_tstamps = h5read(filename,'/Annotations');
    OPALdata(SI).ts_tstamps = h5read(filename,Time_Path);
    OPALdata(SI).accel_calib = h5read(filename, Accelerations_Path)';       %Transposed to make Nx3 in MATLAB}
    OPALdata(SI).ang_velo_calib  = h5read(filename, Gyroscopes_Path)';     %Transposed to make Nx3 in MATLAB}
    OPALdata(SI).magn_flux_calib  = h5read(filename, Magnetometers_Path)';  %Transposed to make Nx3 in MATLAB}
    OPALdata(SI).quaternion = hdf5read(filename, Orientation_Path)';  %Transposed to make Nx4 in MATLAB}


    % check if "quaternion" matrix is empty or contains NaNs
    if isempty(OPALdata(SI).quaternion) || any(isnan(OPALdata(SI).quaternion(:))) || all(OPALdata(SI).quaternion(:) == 0)
        continue % move on to the next sensor type
    end

    % add to data structure other information....
    OPALdata(SI).sensor_id = caseIdList(SI).data;
    OPALdata(SI).sensor_name = imu_id_list{1}{strcmp(OPALdata(SI).sensor_id,imu_id_list{2})};
    OPALdata(SI).fs = double(h5readatt(filename, SensorIDNumbers, 'SampleRate'));

    % acquire event markers (triggers) from "Annotation Time Stamps
    trigger_edges = OPALdata(SI).annotat_tstamps.Time;
    TrigFallEdge = zeros(length(trigger_edges)/2,1);
    microSec = 1;
    for FallEdge = 2:2:length(trigger_edges); 
         TrigFallEdge(microSec,1)=trigger_edges(FallEdge)-min(OPALdata(SI).ts_tstamps);
         microSec = microSec + 1;
    end
    
    % re-format so that onset values are in 128 Hz samples
    OPALdata(SI).trigger_times_128hz = double(round(TrigFallEdge.*(128/1e+6)));
    
    % re-format so that onset values are in 1000 Hz samples
    OPALdata(SI).trigger_times_1000hz = double(round(TrigFallEdge.*(1000/1e+6)));
    
    % re-order quaternions s.t.:   data(SI).quaternion = q2*i + q3*j + q4*k + q1
    quaternion_reorder = [OPALdata(SI).quaternion(:,2) OPALdata(SI).quaternion(:,3) ...
        OPALdata(SI).quaternion(:,4) OPALdata(SI).quaternion(:,1)];

    % calculate navigation-to-body frame rotation (or transformation)
    % matrix from quaternions
    Tn2b = q2dcm(quaternion_reorder); 

    % apply gravity compensation
    for i = 1:length(Tn2b)
        % take transpose to take navigation-to-body frame into body-to-navigation frame
        OPALdata(SI).Tb2n(:,:,i) = Tn2b(:,:,i)';
        
        % transform acceleration into navigation frame
        OPALdata(SI).accel_gravcomp(i,:) = OPALdata(SI).Tb2n(:,:,i)*(OPALdata(SI).accel_calib(i,:)');
        
        % ...and subtract outthe acceleration due to gravity (9.81  m/s^2)
        OPALdata(SI).accel_gravcomp(i,:) = OPALdata(SI).accel_gravcomp(i,:) - [0 0 9.81];
    end
end
%}
%% Place into FieldTrip structure
usec2sec = (1./1e+6); % to convert from microsecond to second conversion

% for da = 1:length(list_subfields);
%     data(da)=cell(1);
% end
for da = 1:length(list_subfields);
    eval(['time_length = min(cellfun(''length'',{OPALdata.',list_subfields{da},'}));']);
    axesOffset = 1;
    for SN = senslistIDX
        eval(['data(da).trial(axesOffset:axesOffset+2,:) = transpose(OPALdata(SN).',list_subfields{da},'(1:time_length,:));']);
        data(da).label{axesOffset,1} = [OPALdata(SN).sensor_name,'-Xcomp'];
        data(da).label{axesOffset+1,1} = [OPALdata(SN).sensor_name,'-Ycomp'];
        data(da).label{axesOffset+2,1} = [OPALdata(SN).sensor_name,'-Zcomp'];
        axesOffset = axesOffset+3;
    end
    data(da).datatype = list_subfields{da};
    data(da).trial = mat2cell(data(da).trial,size(data(da).trial,1),size(data(da).trial,2));
    data(da).time = {double(OPALdata(1).ts_tstamps' - min(OPALdata(1).ts_tstamps)).*usec2sec}; % convert to time in seconds
    data(da).fsample = OPALdata(1).fs;
    data(da).sampleinfo = [1,length(data(da).time{1})];
end
