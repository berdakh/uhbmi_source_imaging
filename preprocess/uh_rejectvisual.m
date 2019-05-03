function data_clean =uh_rejectvisual(data,method,viewmode)
% visual rejection of artifacts 
% method - 'trial' or 'summary'
if nargin < 3
    viewmode = 'butterfly';
end
if nargin <2
    method = 'trial';
end 
    cfg          = [];
    cfg.method   = method;
    cfg.viewmode = viewmode;
    cfg.method   = method;
%     cfg.alim     = 1e-12;
%     cfg.megscale = 1;
%     cfg.eogscale = 5e-8;
    data_clean     = ft_rejectvisual(cfg,data);
end