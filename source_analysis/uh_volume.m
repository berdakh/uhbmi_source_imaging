function [vol, mesh] = uh_volume(segmri,conductivity,plotdata)
% This function takes the meshes and provides the volume (forward model)
% Currently there are only three segments {'brain','skull','scalp'};
% 3/18/2015 / mlearnx

%% output contains
% bnd: contains the geometrical description of the head model.
% cond: conductivity of each surface
% mat: matrix
% type: describes the method that was used to create the headmodel.
% unit: the unit of measurement of the geometrical data in the bnd field
% cfg: configuration of the function that was used to create vol

cfg = [];
cfg.method = 'iso2mesh';
cfg.numvertices = 10000;
mesh = ft_prepare_mesh(cfg, segmri);

%% Check and repair a surface mesh
[mesh(1).pnt, mesh(1).tri] = meshresample(mesh(1).pnt, mesh(1).tri, 1000/size(mesh(1).pnt, 1));
[mesh(2).pnt, mesh(2).tri] = meshresample(mesh(2).pnt, mesh(2).tri, 2000/size(mesh(2).pnt, 1));
[mesh(3).pnt, mesh(3).tri] = meshresample(mesh(3).pnt, mesh(3).tri, 3000/size(mesh(3).pnt, 1));
for ii = 1:size( mesh),
    [mesh(ii).pnt, mesh(ii).tri] = meshcheckrepair(mesh(ii).pnt, mesh(ii).tri, 'dup');
    [mesh(ii).pnt, mesh(ii).tri] = meshcheckrepair(mesh(ii).pnt, mesh(ii).tri, 'isolated');
    [mesh(ii).pnt, mesh(ii).tri] = meshcheckrepair(mesh(ii).pnt, mesh(ii).tri, 'deep');
    [mesh(ii).pnt, mesh(ii).tri] = meshcheckrepair(mesh(ii).pnt, mesh(ii).tri, 'meshfix');
end

if ~exist('plotdata','var')
    plotdata =1;
end
if ~exist('conductivity','var')
    conductivity = [0.33 0.33 0.033];   % order follows mesh.tissyelabel
end
%% prepare volume
cfg = [];
% % cfg.hdmfile = '';
cfg.method ='bemcp';
cfg.conductivity = conductivity;   % order follows mesh.tissyelabel
cfg.tissue = {'brain','skull','scalp'};
vol = ft_prepare_headmodel(cfg, mesh);
%%
if plotdata
    ft_plot_mesh(vol.bnd(1), 'facecolor',[0.1 0.1 0.1], 'facealpha', 0.3, 'edgecolor', [1 1 1], 'edgealpha', 0.05);
    hold on; ft_plot_mesh(vol.bnd(2),'edgecolor','none','facealpha',0.4);
    hold on; ft_plot_mesh(vol.bnd(3), 'facecolor',[0.1 0.1 0.3], 'facealpha', 0.5, 'edgecolor', [1 1 1], 'edgealpha', 0.05);
end
end