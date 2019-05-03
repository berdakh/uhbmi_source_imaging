function grid = uh_leadfield(vol,elec,gridresolution, plotdata)
% This function prepares the leadfield matrix using volumetric data and
% electrode positions
% 3/18/2015 / mlearnx
%   stage.headmodel
%   stage.electrodes
%   stage.leadfield
if ~exist('gridresolution','var')
    gridresolution = 'Lsurf10mm';
end
if ~exist('plotdata','var')
    plotdata = 0;
end
%%
%% prepare cfg
cfg = [];
cfg.vol = vol;
cfg.elec = elec;
cfg.normalize='yes';
cfg.reducerank = 2;
% Set up leadfield config for a source grid 
cfg.grid = sourcegrid(gridresolution);
%% Compute leadfield
[grid] = ft_prepare_leadfield(cfg);

%% PLOT options
if plotdata
    plot3(grid.pos(:,1),grid.pos(:,2),grid.pos(:,3),'.');
    % hold on,  ft_plot_vol(anat.vol, 'edgecolor', 'none');
    hold on, ft_plot_sens(elec);
end

%%
 function [grid] = sourcegrid(gridresolution)
        switch gridresolution
            case 'Lsurf10mm';
                grid.resolution = 10;
                grid.unit = 'mm';%
            case 'L1cm'
                grid.resolution = 1;
                grid.unit = 'cm';
            case 'L1mm'
                resolution = 1;
                grid.xgrid = -60:resolution:110;
                grid.ygrid = -70:resolution:60;
                grid.zgrid = -10:resolution:120;
                % grid.resolution = 10;
                grid.unit = 'mm';
            case 'L5mm'
                resolution = 5;
                grid.xgrid = -60:resolution:110;
                grid.ygrid = -70:resolution:60;
                grid.zgrid = -10:resolution:120;
                % ft_prepare_leadfield.grid.resolution = 5;
                grid.unit = 'mm';
            case 'L10mm'
                resolution = 10;
                grid.xgrid = -60:resolution:110;
                grid.ygrid = -70:resolution:60;
                grid.zgrid = -10:resolution:120;
                % grid.resolution = 10;
                grid.unit = 'mm';
            case 'Llinx10mm'
                % The lead field is on a linear grid in the x direction with 10mm
                % spacing
                grid.xgrid = -100:1:100;
                grid.ygrid = 0;
                grid.zgrid = 10;
                % grid.resolution = 10;
                grid.unit = 'mm';
            case 'Lliny10mm'
                % The lead field is on a linear grid in the y direction with 10mm
                % spacing
                grid.xgrid = -50;
                grid.ygrid = -100:10:100;
                grid.zgrid = 50;
                % grid.resolution = 10;
                grid.unit = 'mm';
            case 'Lliny1mm'
                % The lead field is on a linear grid in the y direction with 10mm
                % spacing
                grid.xgrid = -50;
                grid.ygrid = -100:1:100;
                grid.zgrid = 50;
                % grid.resolution = 10;
                grid.unit = 'mm';
        end
 end
end 
