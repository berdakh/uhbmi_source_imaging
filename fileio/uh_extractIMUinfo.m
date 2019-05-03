function [data] = uh_extractIMUinfo( filename, imu_id_list )
%ORGANIZEOPALSBYSENSOR will take information from a HDF5 file and extract
% information from each OPAL sensor
%   Input: filename --> name of the .h5 file that contains kinematics info
%       imu_id_list --> list of all IMUs recorded in the .h5 file. 
%                       Column 1 contains the body part sensor was mounted 
%                       to (i.e. forehead). 
%                       Column 2 contains the ID number of the sensor (i.e.
%                       SI-773).
%  Output:     data --> data structure that contains a field for each
%                       sensor.
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Within each sensor field are the following subfields:
%   annotat_tstamps -> timestamps where each trigger was applied
%   ts_tstamps      -> timestamps for whole recording session
%   accel_calib 	-> calibrated acceleration recorded from triaxial 
%                      accelerometer
%   ang_velo_calib  -> calibrated angular velocity recorded from triaxial
%                      gyroscope
%   magn_flux_calib -> calibrated magnetic flux recorded from triaxial
%                      magnetometer
%   quaternion      -> orientation information expressed as quaternions
%   sensor_id       -> ID number of the sensor (i.e. SI-773)
%   sensor_name     -> body part sensor was mounted to (i.e. forehead)
%   fs              -> sampling rate of all recorded data signals 
%   trigger_times_128hz -> times each trigger was applied, referenced to
%                          start of recording and sampled at 128 
%                          samples/second
%   trigger_times_1000hz -> times each trigger was applied, referenced to
%                           start of recording and sampled at 1000 
%                           samples/second
%   Tb2n            -> body-tonavigation frame of reference transformation
%                      matrix
%   accel_gravcomp  -> calibrated acceleration that has had the effects of
%                      acceleration due to gravity (9.81 m/s^2) removed
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Created by: Zachery Hernandez, University of Houston, 2015
%
%% To add the Quaternion Toolbox directory path from lab server to host computer
addpath(genpath('\\bmi-nas-01\Contreras-UH\Lab software and hardware\Custom matlab functions\quaternions'))

%% initialize data structure
data = struct(); 

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

%% If format is valid then read in each sensor ID
sensorIdList = hdf5read(filename,'/CaseIdList');

%% ... and extract information for each sensor 
for SI = 1:size(sensorIdList,1);
    % read sensor ID numbers and place as a directory path string
    SensorIDNumbers = ['/' sensorIdList(SI).data];

    % read in measurement directory paths
    Accelerations_Path = [SensorIDNumbers '/Calibrated/Accelerometers']; %Data path to be read
    Gyroscopes_Path = [SensorIDNumbers '/Calibrated/Gyroscopes']; %Data path to be read
    Magnetometers_Path = [SensorIDNumbers '/Calibrated/Magnetometers']; %Data path to be read
    Orientation_Path  = [SensorIDNumbers '/Calibrated/Orientation']; %Data path to be read
    Time_Path  = [SensorIDNumbers '/Time']; %Data path to be read

    % and use paths to acquire measurements into Matlab data structure
    data(SI).annotat_tstamps = h5read(filename,'/Annotations');
    data(SI).ts_tstamps = h5read(filename,Time_Path);
    data(SI).accel_calib = h5read(filename, Accelerations_Path)';       %Transposed to make Nx3 in MATLAB}
    data(SI).ang_velo_calib  = h5read(filename, Gyroscopes_Path)';     %Transposed to make Nx3 in MATLAB}
    data(SI).magn_flux_calib  = h5read(filename, Magnetometers_Path)';  %Transposed to make Nx3 in MATLAB}
    data(SI).quaternion = hdf5read(filename, Orientation_Path)';  %Transposed to make Nx4 in MATLAB}


    % check if "quaternion" matrix is empty or contains NaNs
    if isempty(data(SI).quaternion) || any(isnan(data(SI).quaternion(:))) || all(data(SI).quaternion(:) == 0)
        continue % move on to the next sensor type
    end

    % add to data structure other information....
    data(SI).sensor_id = sensorIdList(SI).data;
    data(SI).fs = double(h5readatt(filename, SensorIDNumbers, 'SampleRate'));
    if ~exist('imu_id_list','var'); 
        data(SI).sensor_name = ['IMU sensor ',num2str(SI)]; 
    else
        data(SI).sensor_name = imu_id_list{1}{strcmp(data(SI).sensor_id,imu_id_list{2})};
    end
    
    % acquire event markers (triggers) from "Annotation Time Stamps
    trigger_edges = data(SI).annotat_tstamps.Time;
    TrigFallEdge = zeros(floor(length(trigger_edges)/2),1);
    microSec = 1;
    for FallEdge = 2:2:length(trigger_edges); 
         TrigFallEdge(microSec,1)=trigger_edges(FallEdge)-min(data(SI).ts_tstamps);
         microSec = microSec + 1;
    end
    
    % re-format so that onset values are in 128 Hz samples
    data(SI).trigger_times_128hz = double(round(TrigFallEdge.*(128/1e+6)));
    
    % re-format so that onset values are in 1000 Hz samples
    data(SI).trigger_times_1000hz = double(round(TrigFallEdge.*(1000/1e+6)));
    
    % re-order quaternions s.t.:   data(SI).quaternion = q2*i + q3*j + q4*k + q1
    quaternion_reorder = [data(SI).quaternion(:,2) data(SI).quaternion(:,3) ...
        data(SI).quaternion(:,4) data(SI).quaternion(:,1)];

    % calculate navigation-to-body frame rotation (or transformation)
    % matrix from quaternions (NOTE: requires Quaternion Toolbox)
    Tn2b = q2dcm(quaternion_reorder); 

    % apply gravity compensation
    for i = 1:length(Tn2b)
        % take transpose to take navigation-to-body frame into body-to-navigation frame
        data(SI).Tb2n(:,:,i) = Tn2b(:,:,i)';
        
        % transform acceleration from body to navigation frame
        data(SI).accel_gravcomp(i,:) = data(SI).Tb2n(:,:,i)*(data(SI).accel_calib(i,:)');
        
        % ...and subtract out the acceleration due to gravity (9.81  m/s^2)
        data(SI).accel_gravcomp(i,:) = data(SI).accel_gravcomp(i,:) - [0 0 9.81];
    end
    
    % use trapezoidal integration to find instantaneous velocity 
    acc_gc = data(SI).accel_gravcomp;
    t = (0:length(acc_gc)-1)/data(SI).fs;
    velo_raw = zeros(length(t),3);
     for j=1:length(t)-1
         velo_raw(j+1,:) = velo_raw(j,:) + (t(j+1)-t(j))/2*(acc_gc(j+1,:)+acc_gc(j,:));
     end
    % filtering to remove integration drifts
    % Design of High Pass Filter
    fc = 0.3;                    % Cutoff frequency in Hz
    Ts = (1/data(SI).fs);
    num = [1 -1];               
    den = [((2*pi*fc*Ts) + 2)/2 ((2*pi*fc*Ts) - 2)/2];
    data(SI).velo_hpf = filter(num, den, velo_raw, [], 1);
    
end

end  %EOF

