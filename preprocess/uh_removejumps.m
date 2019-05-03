%% Jumps in data:
% It is very important to remove all jump and muscle artifacts before running your ICA,
% otherwise they may change the results you get. To remove artifacts on the example dataset, use:
% jump:
function  Data_NoJumps  = uh_removejumps(dataTrl)
%%
cfg_jump = [];
% channel selection, cutoff and padding:
% cfg_jump.trl        = dataTrl.cfg.trl;
% cfg_jump.continuous = 'no';
cfg_jump.artfctdef.zvalue.channel    = 'EEG';
cfg_jump.artfctdef.zvalue.cutoff     = 20;
cfg_jump.artfctdef.zvalue.trlpadding = 0;
cfg_jump.artfctdef.zvalue.artpadding = 0;
cfg_jump.artfctdef.zvalue.fltpadding = 0;

% algorithmic parameters
cfg_jump.artfctdef.zvalue.cumulative    = 'yes';
cfg_jump.artfctdef.zvalue.medianfilter  = 'yes';
cfg_jump.artfctdef.zvalue.medianfiltord = 9 ;
cfg_jump.artfctdef.zvalue.absdiff   = 'yes';

% make the process interactive
cfg_jump.artfctdef.zvalue.interactive = 'no';

[cfg_jump_output, artifact_jump] = ft_artifact_zvalue(cfg_jump,dataTrl);

cfg_jump                         = [] ;
cfg_jump.artfctdef.reject        = 'complete'; %  'complete', use 'partial' if you want to do partial artifact rejection
cfg_jump.artfctdef.jump.artifact = artifact_jump ;
% cfg.artfctdef.muscle.artifact = artifact_muscle;
Data_NoJumps = ft_rejectartifact(cfg_jump, dataTrl) ;
uhplot(Data_NoJumps)

end