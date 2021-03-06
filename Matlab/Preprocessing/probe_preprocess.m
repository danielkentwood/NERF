% probe_preprocess
probe = make_probe_table(Trials);


%% FILTERS
% magnitude of saccades
saccmag = sqrt((probe.y_oneFixAhead-probe.y_curFix).^2 + (probe.x_oneFixAhead-probe.x_curFix).^2);
% intersaccadic interval 
t_fix=probe.t-probe.t_fix_lock;
t_sacc_start = probe.t-probe.t_sacc_start_lock;
saccisi = t_sacc_start-t_fix;
% saccade duration
t_sacc_end = probe.t-probe.t_sacc_end_lock;
saccdur = t_sacc_end-t_sacc_start;

% get ratio of velocity relative to expected velocity
relVel = probe.saccPeakVel ./ probe.expectedPeakVel;

% which direction was the upcoming saccade in?
saccdir = atan2d(probe.y_oneFixAhead-probe.y_curFix,probe.x_oneFixAhead-probe.x_curFix);
saccdir(saccdir<0)=saccdir(saccdir<0)+360;

% what was the direction of the target
dir2targ=atan2d(probe.y_targ-probe.y_curFix,probe.x_targ-probe.x_curFix);
dir2targ(dir2targ<0)=dir2targ(dir2targ<0)+360;
% what was the direction of the distractor
dir2dist=atan2d(probe.y_dist-probe.y_curFix,probe.x_dist-probe.x_curFix);
dir2dist(dir2dist<0)=dir2dist(dir2dist<0)+360;

% what was the distance of the saccade landing point to the target
dist2targ=sqrt((probe.x_oneFixAhead-probe.x_targ).^2 + (probe.y_oneFixAhead-probe.y_targ).^2);
% what was the distance of the saccade landing point to the distractor
dist2dist=sqrt((probe.x_oneFixAhead-probe.x_dist).^2 + (probe.y_oneFixAhead-probe.y_dist).^2);

toTarg = dist2targ<5;
toDist = dist2dist<5;







