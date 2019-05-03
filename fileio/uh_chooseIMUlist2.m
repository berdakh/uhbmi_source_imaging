function [ imu_id_list ] = uh_chooseIMUlist2( infantfolder )
%UH_CHOOSEIMULIST chooses which list of IMU name-ID pairs to use
%   This list is specific to the infant project
% Created by: Zachary Hernandez and Jesus Cruz-Garza, University of
% Houston, 2016
%% specify which text file of IMU ID numbers to use 
% Specify which sensor ID set to use (depends on the year experiment was conducted)
DNinfant = datenum(infantfolder(end-9:end));

if datenum('01-01-2013') < DNinfant && DNinfant < datenum('12-31-2013')
    fileID = fopen('IMUSensorIDNumbers_2013.txt','r');
    imu_id_list = textscan(fileID,'%s %s','Delimiter','\t');
    fclose(fileID);    
elseif datenum('01-01-2014') < DNinfant && DNinfant < datenum('06-18-2015') 
    fileID = fopen('IMUSensorIDNumbers_2014to2015Jun18.txt','r');
    imu_id_list = textscan(fileID,'%s %s','Delimiter','\t');
    fclose(fileID);
elseif datenum('06-19-2014') < DNinfant && DNinfant < datenum('07-22-2015')
    fileID = fopen('IMUSensorIDNumbers_2015Jun19toJul22.txt','r');
    imu_id_list = textscan(fileID,'%s %s','Delimiter','\t');
    fclose(fileID);
elseif datenum('07-23-2014') < DNinfant && DNinfant < datenum('08-10-2015')
    fileID = fopen('IMUSensorIDNumbers_2015Jul23toAug10.txt','r');
    imu_id_list = textscan(fileID,'%s %s','Delimiter','\t');
    fclose(fileID);
elseif datenum('08-11-2014') < DNinfant && DNinfant < datenum('12-31-2016')
    fileID = fopen('IMUSensorIDNumbers_post2015Aug10.txt','r');
    imu_id_list = textscan(fileID,'%s %s','Delimiter','\t');
    fclose(fileID);
end

end

