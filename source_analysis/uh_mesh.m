function [mesh] = uh_mesh(segmri,numvertices,plotdata)
% This function takes the segmenteds and generates meshes
% Currently there are only three segments {'brain','skull','scalp'};
% 3/18/2015 / mlearnx
%%
if ~exist('numvertices','var')
    numvertices = [3000,2000,1800];
    disp('++++++++++++++++++++++++++++++++++++++++++++++++++');
    disp('Default: Number of vertices selected');
    fprintf('Brain/Skull/Scalp - [%d, %d, %d]\n',numvertices(1),numvertices(2),numvertices(3))
    disp('++++++++++++++++++++++++++++++++++++++++++++++++++');
else
    disp('++++++++++++++++++++++++++++++++++++++++++++++++++');
    disp('User defined vertices selected');
    fprintf('Brain/Skull/Scalp - [%d, %d, %d]\n',numvertices(1),numvertices(2),numvertices(3))
    disp('++++++++++++++++++++++++++++++++++++++++++++++++++');
end

%% This mesh is computed for source mesh visualization in which the number of vertices for brain are very high
cfg = [];
cfg.tissue = segmri.tissuelabel;
cfg.numvertices = numvertices;
% cfg.shift  = 0.3;
cfg.method = 'projectmesh';
% cfg.method=string, can be 'interactive', 'projectmesh', 'iso2mesh', 'isosurface','headshape', 'hexahedral', 'tetrahedral'
mesh=ft_prepare_mesh(cfg,segmri);
%mesh_for_source_plotting_source = mesh;

%% Check and repair a surface mesh
% this mesh is saved for MRI plot only :)
%====================== fix intersecting mesh ========================================
[ mesh(1).pnt, mesh(1).tri] = meshresample(mesh(1).pnt, mesh(1).tri, numvertices(3)/size(mesh(1).pnt, 1));
[ mesh(2).pnt, mesh(2).tri] = meshresample(mesh(2).pnt, mesh(2).tri, numvertices(2)/size(mesh(2).pnt, 1));
[ mesh(3).pnt, mesh(3).tri] = meshresample(mesh(3).pnt, mesh(3).tri, numvertices(1)/size(mesh(3).pnt, 1));
for ii = 1:size( mesh),
    [mesh(ii).pnt, mesh(ii).tri] = meshcheckrepair(mesh(ii).pnt, mesh(ii).tri, 'dup');
    [mesh(ii).pnt, mesh(ii).tri] = meshcheckrepair(mesh(ii).pnt, mesh(ii).tri, 'isolated');
    [mesh(ii).pnt, mesh(ii).tri] = meshcheckrepair(mesh(ii).pnt, mesh(ii).tri, 'deep');
    [mesh(ii).pnt, mesh(ii).tri] = meshcheckrepair(mesh(ii).pnt, mesh(ii).tri, 'meshfix');
end
%% ---------------- plot ------------------------------
if plotdata
    ft_plot_mesh(mesh(1,1), 'facecolor',[0.1 0.1 0.1], 'facealpha', 0.3, 'edgecolor', [1 1 1], 'edgealpha', 0.05);
    hold on; ft_plot_mesh(mesh(1,2),'edgecolor','none','facealpha',0.4);
    hold on; ft_plot_mesh(mesh(1,3), 'facecolor',[0.1 0.1 0.3], 'facealpha', 0.5, 'edgecolor', [1 1 1], 'edgealpha', 0.05);
 end
   
end