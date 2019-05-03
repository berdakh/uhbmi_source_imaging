function [vol, sens] = uh_electrode_coregister(elec,plotdata,method,vol,mri)
% This function performs co-registration between MRI and EEG sensor space
% This step is required right before computing the liedfield matrix
% Two options 
% option 1 (fiducial based): Automatic alignment 
% option 2 (interactive)   : Align electrode interactively
% optimal parameters for brainvision easycap 64
% ROTATE: 0 100 180
% SCALE:  1 0.9 0.77
% TRANSLATE 10 0 50
if ~exist('plotdata','var')
    plotdata =1;
end
if ~exist('method','var')
    method = 'interactive';
end
%%
switch method
    case 'fiducial'
        %% Fiducial alignment        
        % Load MRI data       
        % Get landmark coordinates
        nas=mri.cfg.fiducial.nas;
        lpa=mri.cfg.fiducial.lpa;
        rpa=mri.cfg.fiducial.rpa;    
        transm=mri.transform;        
        
        nas=ft_warp_apply(transm,nas, 'homogenous');
        lpa=ft_warp_apply(transm,lpa, 'homogenous');
        rpa=ft_warp_apply(transm,rpa, 'homogenous');
        
        % create a structure similar to a template set of electrodes
        fid.chanpos       = [nas; lpa; rpa];       % neuromag-coordinates of fiducials
        fid.label         = {'Nasion','A1','A2'};    % same labels as in elec
        fid.unit          = 'mm';                  % same units as mri        
        
        % Alignment
        cfgin               = [];
        cfgin.method        = 'fiducial';
        cfgin.template      = fid;                   % see above
        cfgin.elec          = elec;
        cfgin.fiducial      = {'Nasion','A2','A1'};    % same labels as in elec
        elec = ft_electroderealign(cfgin);        
        
    case 'interactive'
        %% Interactive alignment         
        cfgin           = [];
        cfgin.method    = 'interactive';
        cfgin.elec      = elec;
        if isfield(vol, 'skin_surface')
             cfgin.headshape = vol.bnd(vol.skin_surface);
         else
            cfgin.headshape = vol.bnd(1);
         end
        elec  = ft_electroderealign(cfgin);       
end
[vol, sens] = ft_prepare_vol_sens(vol, elec);

%%
if plotdata
    figure
    ft_plot_sens(sens,'style','sk','label','on');hold on;
    ft_plot_mesh(vol.bnd(3),'facealpha', 0.75, 'edgecolor', 'none', 'facecolor', [0.65 0.65 0.65]); %scalp
end
end