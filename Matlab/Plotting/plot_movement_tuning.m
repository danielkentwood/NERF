% plot_movement_tuning



%% get saccade-locked tuning (radial)
r_mov_par.figHand = figure();
r_mov_par.plotLoc = [0.05 0 .43 1];
PSTH_r_mov = radial_PSacTH(Trials, r_mov_par);

for i = 1:length(PSTH_r_mov), y_all(i,:) = PSTH_r_mov(i).y; end

[pstd_yall, pyi] = max(std(y_all));
x_at_peak_std = PSTH_r_mov(1).x(pyi);



%% get estimate of movement RF
% Using x_at_peak from untuned temporal response, plot movement RF map
params.dt=10;
params.x_at_peak=x_at_peak_std;
params.x_at_peak=0;
params.win_size=40;
params.xwidth=40;
params.ywidth=30;
params.pad = 20;
moveRF_preview(Trials,params);



