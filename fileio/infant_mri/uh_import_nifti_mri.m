function output = uh_import_nifti_mri(MriFile,realign,fiducial)
% This function imports MRI or MRI segments from nifti file format
% 3/18/2015
%% READ MRI
fid = uh_nifti_open_hdr(MriFile);
if fid==-1, disp(sprintf('in_mri_nii : Error opening header file')); return; end
% Read file header
hdr = uh_nifti_read_hdr(fid);
if isempty(hdr), disp(sprintf('in_mri_nii : Error reading header file')); return; end
% Read image (3D matrix)
fseek(fid, double(hdr.dim.vox_offset), 'bof');
data = uh_nifti_read_img(fid, hdr);
fclose(fid);

if isempty(data), disp('in_mri_nii : Error reading image file'); return; end
dim = size(data);

%% ===== CREATE FT STRUCTURE =====
fileid = struct('inside',logical(data), 'anatomy', data,'dim',dim,...
    'transform',diag([1 1 1 1]),'unit','mm','cfg',hdr,'File_info',MriFile);
cfg=[];
% cfg.method='interactive';
cfg.coordsys='neuromag';
if realign == 1;
    %% Re-align to FT coordinate system
    output = ft_volumerealign(cfg,fileid);
    %         cfg =[];
    %         cfg.dim = [200 200 200];
    %         output1 = ft_volumereslice(cfg, mri);
elseif exist('fiducial','var')
    output = ft_volumerealign(fiducial,fileid);
else
    output = fileid;
end
end
