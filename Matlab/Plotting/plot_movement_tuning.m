% plot_movement_tuning



%% get saccade-locked tuning (radial)
% set parameters
r_mov_par.figHand = figure();
r_mov_par.plotLoc = [0.05 0 .43 1];
r_mov_par.errBars = 0;
% create the radial perisaccadic time histogram with raster
PSTH_r_mov = radial_PSacTH(Trials, r_mov_par);
% identify the time point with the highest variability across the 8 radial
% activity bins
for i = 1:length(PSTH_r_mov), y_all(i,:) = PSTH_r_mov(i).y; end
[pstd_yall, pyi] = max(std(y_all));
x_at_peak_std = PSTH_r_mov(1).x(pyi);

% set the window size for integrating firing rate when we estimate the RF
win_size = 50;
% plot the integration window on the raster
hold on
plot([x_at_peak_std x_at_peak_std],ylim,'r--')
plot([x_at_peak_std-(win_size/2) x_at_peak_std-(win_size/2)],ylim,'k-')
plot([x_at_peak_std+(win_size/2) x_at_peak_std+(win_size/2)],ylim,'k-')
hold off



%% get estimate of movement RF
% Using x_at_peak from untuned temporal response, plot movement RF map
% set parameters
params.dt=10;
params.x_at_peak=x_at_peak_std;
params.x_at_peak=0;
params.win_size=win_size;
params.xwidth=40;
params.ywidth=30;
params.pad = 20;
params.fig_Handle = r_mov_par.figHand;
params.axes_Handle = [0.53 0.2 .42 .6];
% create RF
moveRF_preview(Trials,params);



