function hdr = uh_nifti_read_hdr(fid)
    % ===== ANALYZE : Section 'header_key' =====
    key.sizeof_hdr    = fread(fid,1,'uint32');
    key.data_type     = char(fread(fid,[1,10],'uchar'));   
    key.db_name       = char(fread(fid,[1,18],'uchar'));
    key.extents       = fread(fid,1,'uint32'); 
    key.session_error = fread(fid,1,'uint16');
    key.regular       = char(fread(fid,1,'uchar'));
    key.hkey_un0      = char(fread(fid,1,'uchar'));

    % ===== ANALYZE : Section 'image_dimension' =====
    dim.dim        = fread(fid,[1,8],'uint16');
    dim.vox_units  = char(fread(fid,[1,4],'uchar'));
    dim.cal_units  = char(fread(fid,[1,8],'uchar'));
    dim.unused1    = fread(fid,1,'uint16');
    dim.datatype   = fread(fid,1,'uint16');
    dim.bitpix     = fread(fid,1,'uint16');
    dim.dim_un0    = fread(fid,1,'uint16');
    dim.pixdim     = fread(fid,[1,8],'float32');    % in disk it is a float !!!!!!
    dim.vox_offset = fread(fid,1,'float32');    % in disk it is a float !!!!!!
    dim.funused1   = fread(fid,1,'float32');      % in disk it is a float !!!!!!
    dim.funused2   = fread(fid,1,'float32');      % in disk it is a float !!!!!!
    dim.funused3   = fread(fid,1,'float32');      % in disk it is a float !!!!!!
    dim.cal_max    = fread(fid,1,'float32');       % in disk it is a float !!!!!!
    dim.cal_min    = fread(fid,1,'float32');       % in disk it is a float !!!!!!
    dim.compressed = fread(fid,1,'uint32');      
    dim.verified   = fread(fid,1,'uint32');      
    dim.glmax      = fread(fid,1,'uint32'); 
    dim.glmin      = fread(fid,1,'uint32');

    % ===== ANALYZE : Section 'image_dimensions' =====
    hist.descrip     = char(fread(fid,[1,80],'uchar'));
    hist.aux_file    = char(fread(fid,[1,24],'uchar'));
    hist.orient      = fread(fid,1,'uchar');
    hist.originator  = fread(fid,[1,5],'int16');
    hist.generated   = char(fread(fid,[1,10],'uchar'));
    hist.scannum     = char(fread(fid,[1,10],'uchar'));
    hist.patient_id  = char(fread(fid,[1,10],'uchar'));
    hist.exp_date    = char(fread(fid,[1,10],'uchar'));
    hist.exp_time    = char(fread(fid,[1,10],'uchar'));
    hist.hist_un0    = char(fread(fid,[1,3],'uchar'));
    hist.views       = fread(fid,1,'uint32');
    hist.vols_added  = fread(fid,1,'uint32');
    hist.start_field = fread(fid,1,'uint32');
    hist.field_skip  = fread(fid,1,'uint32');
    hist.omax        = fread(fid,1,'uint32');
    hist.omin        = fread(fid,1,'uint32');
    hist.smax        = fread(fid,1,'uint32');
    [hist.smin, cnt] = fread(fid,1,'uint32');
    if (cnt ~= 1)
        error('Error opening file : Incomplete header');
    end

    % ===== NIfTI-specific section =====
    % Read identification string
    fseek(fid, 344, 'bof');
    [nifti.magic, count] = fread(fid,[1,4],'uchar');
    % Detect file type
    isNifti = ismember(deblank(char(nifti.magic)), {'ni1', 'n+1'});
    % If file is a real NIfTI-1 file : read other values
    if isNifti
        nifti.dim_info = key.hkey_un0;
        fseek(fid, 56, 'bof');
        nifti.intent_p1 = fread(fid,1,'float32');
        nifti.intent_p2 = fread(fid,1,'float32');
        nifti.intent_p3 = fread(fid,1,'float32');
        nifti.intent_code = fread(fid,1,'uint16');
        nifti.slice_start = dim.dim_un0;
        nifti.scl_slope = dim.funused1;
        nifti.scl_inter = dim.funused2;
        fseek(fid, 120, 'bof');
        nifti.slice_end = fread(fid,1,'uint16');
        nifti.slice_code = fread(fid,1,'uchar');
        nifti.xyzt_units = fread(fid,1,'uchar');
        nifti.slice_duration = dim.compressed;
        nifti.toffset = dim.verified;
        fseek(fid, 252, 'bof');
        nifti.qform_code = fread(fid,1,'uint16');
        nifti.sform_code = fread(fid,1,'uint16');
        nifti.quatern_b = fread(fid,1,'float32');
        nifti.quatern_c = fread(fid,1,'float32');
        nifti.quatern_d = fread(fid,1,'float32');
        nifti.qoffset_x = fread(fid,1,'float32');
        nifti.qoffset_y = fread(fid,1,'float32');
        nifti.qoffset_z = fread(fid,1,'float32');
        nifti.srow_x = fread(fid,[1,4],'float32');
        nifti.srow_y = fread(fid,[1,4],'float32');
        nifti.srow_z = fread(fid,[1,4],'float32');
        nifti.intent_name = fread(fid,[1,16],'uchar');
    else
        nifti = [];
    end
    if (count ~= 4)
        error('Unknown error');
    end

    % ===== NIFTI ORIENTATION =====
    if ~isempty(nifti)
        % Sform matrix
        if ~isempty(nifti.srow_x) && ~isequal(nifti.srow_x, [0 0 0 0])
            nifti.sform = [...
                nifti.srow_x;
                nifti.srow_y;
                nifti.srow_z;
                0 0 0 1];
        else
            nifti.sform = [];
        end

        % Qform matrix - not quite sure how all this works,
        % mainly just copied CH's code from mriio.c
        b = nifti.quatern_b;
        c = nifti.quatern_c;
        d = nifti.quatern_d;
        x = nifti.qoffset_x;
        y = nifti.qoffset_y;
        z = nifti.qoffset_z;
        a = 1.0 - (b*b + c*c + d*d);
        if(abs(a) < 1.0e-7)
            a = 1.0 / sqrt(b*b + c*c + d*d);
            b = b*a;
            c = c*a;
            d = d*a;
            a = 0.0;
        else
            a = sqrt(a);
        end
        r11 = a*a + b*b - c*c - d*d;
        r12 = 2.0*b*c - 2.0*a*d;
        r13 = 2.0*b*d + 2.0*a*c;
        r21 = 2.0*b*c + 2.0*a*d;
        r22 = a*a + c*c - b*b - d*d;
        r23 = 2.0*c*d - 2.0*a*b;
        r31 = 2.0*b*d - 2*a*c;
        r32 = 2.0*c*d + 2*a*b;
        r33 = a*a + d*d - c*c - b*b;
        if(dim.pixdim(1) < 0.0)
            r13 = -r13;
            r23 = -r23;
            r33 = -r33;
        end
        qMdc = [r11 r12 r13; r21 r22 r23; r31 r32 r33];
        D = diag(dim.pixdim(2:4));
        P0 = [x y z]';
        nifti.qform = [qMdc*D P0; 0 0 0 1];

        % Build final transformation matrix
        if (nifti.sform_code ~= 0) && ~isempty(nifti.sform) && ~isequal(nifti.sform(1:3,1:3),zeros(3)) && ~isequal(nifti.sform(1:3,1:3),eye(3))
            nifti.vox2ras = nifti.sform;
        elseif (nifti.qform_code ~= 0) && ~isempty(nifti.qform) && ~isequal(nifti.qform(1:3,1:3),zeros(3)) && ~isequal(nifti.qform(1:3,1:3),eye(3))
            nifti.vox2ras = nifti.qform;
        else
            nifti.vox2ras = [];
        end
    end
    
    % ===== Test header values =====
    Ndim = dim.dim(1);  % Number of dimensions
    Nt = dim.dim(5);    % Number of time frames
    if ~(((Ndim == 4) && (Nt == 1)) || (Ndim == 3))
        error('Support only for 3D data set' );
    end
    
    % ===== Report results =====
    hdr.key = key;
    hdr.dim = dim;
    hdr.hist = hist;
    hdr.nifti = nifti;
end

