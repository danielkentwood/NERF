
%% load stuff
if exist('sessList','var') && ~exist('Trials','var')
    Trials = open_merged(sessList);
end


%% get saccades
% clean up the data behavioral data
Trials = saccade_detector(Trials);   
Trials = cleanTrials(Trials);


%% plot all the saccade vectors and fixations
% plotTargsAndFixations(Trials);




%% plot radial PSTH for movement
r_mov_par.plotflag=1;
r_mov_par.errBars=0;
PSTH_r_mov = radial_PSacTH(Trials, r_mov_par);
for i = 1:length(PSTH_r_mov), y_all(i,:) = PSTH_r_mov(i).y; end
[pstd_yall, pyi] = max(std(y_all));
x_at_peak_std = PSTH_r_mov(1).x(pyi);
% Using x_at_peak from untuned temporal response, plot movement RF map
params.dt=10;
params.x_at_peak=x_at_peak_std;
params.x_at_peak=-100;
params.win_size=40;
params.xwidth=40;
params.ywidth=30;
params.pad = 20;
moveRF_preview(Trials,params);
polar_tuning(Trials, params);


%% plot untuned temporal response for movement
PSTH_tu_mov = temporal_untuned_pSacTH(Trials); 
[mx, mxid] = max(PSTH_tu_mov.y);
x_at_peak = PSTH_tu_mov.x(mxid);


%% Using x_at_peak from untuned temporal response, plot movement RF map
params.dt=10;
params.x_at_peak=x_at_peak;
params.win_size=40;
params.xwidth=40;
params.ywidth=30;
moveRF_preview(Trials,params);


%% plot radial PSTH for probes
% PSTH_r_probe = radial_PProbeTH(Trials, 'single');
PSTH = radial_PProbeTH_v2(Trials);



%% plot ununed temporal response for probes
PSTH_tu_probe = temporal_untuned_pProbeTH(Trials);

%% plot visual RF maps
params.dt=10;
params.x_at_peak=100;
params.win_size=40;
params.xwidth=40;
params.ywidth=30;
probeRF_preview(Trials,params);