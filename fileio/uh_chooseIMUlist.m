function [ imu_id_list ] = uh_chooseIMUlist( filename )
%UH_CHOOSEIMULIST chooses which list of IMU name-ID pairs to use
%   This list is specific to the infant project
% Created by: Zachary Hernandez, University of Houston, 2015
%% specify which text file of IMU ID numbers to use 
IMUlist_filename = 'IMUSensorIDNumbers_2013.txt';

%% open and save into variable the list of sensor ID numbers
fileID = fopen(IMUlist_filename,'r');
imu_id_list = textscan(fileID,'%s %s','Delimiter','\t');
fclose(fileID);

end

