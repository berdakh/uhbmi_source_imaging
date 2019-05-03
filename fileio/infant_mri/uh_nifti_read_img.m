function data = uh_nifti_read_img(fid, hdr)
    % Data type to read
    switch (hdr.dim.datatype)
        % Analyze-compatible codes
        case {1,2},   datatype = 'uint8';
        case 4,       datatype = 'int16';
        case 8,       datatype = 'int32';
        case 16,      datatype = 'single';
        case {32,64}, datatype = 'double';
        % NIfTI-specific codes
        case 256,     datatype = 'int8';
        case 512,     datatype = 'uint16';
        case 768,     datatype = 'uint32';
        case 1024,    datatype = 'int64';
        case 1280,    datatype = 'uint64';
        otherwise,    error('Unsupported data type');
    end

    % Dimensions of the MRI
    Nx = hdr.dim.dim(2);    % Number of pixels in X
    Ny = hdr.dim.dim(3);    % Number of pixels in Y
    Nz = hdr.dim.dim(4);    % Number of Z slices
    Nt = hdr.dim.dim(5);    % Number of time frames
    if (Nt == 0)
        Nt = 1;
    end
    % Read data
    data = repmat(cast(1, datatype),[Nx,Ny,Nz,Nt]);
    Nxy = Nx*Ny;
    for t = 1:Nt,
       for z = 1:Nz,
          [temp, cont] = fread(fid, [Nx,Ny], datatype);
          if (cont ~= Nxy) % ERROR
              data = [];
              return;
          end
          data(:,:,z,t) = temp;
       end
    end
end    