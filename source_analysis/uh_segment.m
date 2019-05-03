function segmri = uh_segment(segments,plotdata)
% This function takes the segmented mri and prepares FT structure
% Currently there are only three segments {'brain','skull','scalp'};
% % Prepare to extract segmentation compartments
% brain = 1; skull = 2; scalp = 3;
% 3/18/2015 / mlearnx
if exist('plotdata','var')
    plotdata =1;
end
%% Prepare FT structure
segmri.dim = segments.dim;
segmri.transform = segments.transform;
segmri.coordsys = 'mni';
segmri.threshold = [1,2,3];
% segmri.tissuelabel={'brain','skull','scalp','white','gray','csf'};
segmri.tissuelabel={'brain','skull','scalp'};
segmri.unit = 'mm';

for ii = 1:length(segmri.tissuelabel)
    switch segmri.tissuelabel{1,ii}
        case 'brain'
            segmri.brain = (segments.anatomy==segmri.threshold(1));
            segmri.brain(segmri.brain~=0) = 1;
            if plotdata
                cfg = [];
                cfg.funparameter = 'brain';
                ft_sourceplot(cfg,segmri);
            end
        case 'skull'
            segmri.skull = (segments.anatomy ==segmri.threshold(2));
            segmri.skull(segmri.skull~=0) = 1;
            if plotdata
                cfg = [];
                cfg.funparameter = 'skull';
                ft_sourceplot(cfg,segmri);
            end
        case 'scalp'
            segmri.scalp = (segments.anatomy==segmri.threshold(3));
            segmri.scalp(segmri.scalp~=0) = 1;
            if plotdata
                cfg = [];
                cfg.funparameter = 'scalp';
                ft_sourceplot(cfg,segmri);
            end
        case 'white'
            segmri.white = (segments.anatomy==segmri.threshold(4));
            segmri.white(segmri.white~=0) = 1;
            if plotdata
                cfg = [];
                cfg.funparameter = 'white';
                ft_sourceplot(cfg,segmri);
            end
        case 'gray'
            segmri.gray = (segments.anatomy==segmri.threshold(5));
            segmri.gray(segmri.gray~=0) = 1;
            if plotdata
                cfg = [];
                cfg.funparameter = 'gray';
                ft_sourceplot(cfg,segmri);
            end
        case 'csf'
            segmri.csf = (segments.anatomy==segmri.threshold(6));
            segmri.csf(segmri.csf~=0) = 1;
            if plotdata
                cfg = [];
                cfg.funparameter = 'csf';
                ft_sourceplot(cfg,segmri);
            end
    end
    disp(segmri); 
end
end