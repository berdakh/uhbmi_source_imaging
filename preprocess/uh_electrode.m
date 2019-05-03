function elec = uh_electrode(elec,plotdata,method,vol,mri)
% Align electrode interactively
% And save it
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
        fid.chanpos       = [nas; lpa; rpa];       % ctf-coordinates of fiducials
        fid.label         = {'Nasion','A1','A2'};    % same labels as in elec
        fid.unit          = 'mm';                  % same units as mri        
        
        % Alignment
        cfgin               = [];
        cfgin.method        = 'fiducial';
        cfgin.template      = fid;                   % see above
        cfgin.elec          = elec;
        cfgin.fiducial      = {'Nasion','A1','A2'};    % same labels as in elec
        elec = ft_electroderealign(cfgin);        
        
    case 'interactive'
        %% Interactive alignment         
        cfgin           = [];
        cfgin.method    = 'interactive';
        cfgin.elec      = elec3;
        if isfield(vol, 'skin_surface')
             cfgin.headshape = vol.bnd(vol.skin_surface);
         else
            cfgin.headshape = vol.bnd(1);
         end
        elec  = ft_electroderealign(cfgin);       

end
%%
if plotdata
    ft_plot_sens(elec,'style','sk','label','on');hold on;
    ft_plot_mesh(vol.bnd(1),'facealpha', 0.75, 'edgecolor', 'none', 'facecolor', [0.65 0.65 0.65]); %scalp
end
end