function [fid, byteOrder] = uh_nifti_open_hdr(MriFile)
    % Open file for reading only (trying little endian byte order)
    [fid, message] = fopen(MriFile, 'r', 'ieee-le');
    if fid == -1, disp(sprintf('in_mri_nii : %s', message)); return; end
    % Detect data byte order (little endian or big endian)
    fseek(fid,40,'bof');
    dim_zero = fread(fid,1,'uint16');
    % dim_zero must be a number between 1 and 7, else try a big endian byte order
    if(dim_zero < 1 || dim_zero > 7)
        fclose(fid);
        fopen(MriFile, 'r', 'ieee-be');
        fseek(fid,40,'bof');
        dim_zero = fread(fid,1,'uint16');
        if(dim_zero < 1 || dim_zero > 7) % ERROR
            fid = -1;
            return;
        end
        byteOrder = 'ieee-be';
    else
        byteOrder = 'ieee-le';
    end
    fseek(fid,0,'bof');
end 

 