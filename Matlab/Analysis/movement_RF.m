% plot_movement_tuning
function h = movement_RF(Trials, meta)


%% get saccade-locked tuning (radial)
% set parameters
r_mov_par.figHand = figure();
r_mov_par.plotLoc = [0.015 0 .43 1];
r_mov_par.errBars = 0;
% create the radial perisaccadic time histogram with raster
PSTH_r_mov = radial_PSacTH(Trials, r_mov_par);
% identify the time point with the highest variability across the 8 radial
% activity bins
for i = 1:length(PSTH_r_mov), y_all(i,:) = PSTH_r_mov(i).y; end
[pstd_yall, pyi] = max(std(y_all));
x_at_peak_std = PSTH_r_mov(1).x(pyi);

% set the window size for integrating firing rate when we estimate the RF
win_size = 40;
% plot the integration window on the raster
hold on
plot([x_at_peak_std-(win_size/2) x_at_peak_std-(win_size/2)],ylim,'k-')
plot([x_at_peak_std+(win_size/2) x_at_peak_std+(win_size/2)],ylim,'k-')
annotation('textbox', [.13, 0.91, 0.1, 0], 'string', meta.fname,'LineStyle','none','Interpreter','none')
hold off



%% get estimate of movement RF
% Using x_at_peak from untuned temporal response, plot movement RF map
% set parameters
params.dt=10;
params.x_at_peak=x_at_peak_std;
params.win_size=win_size;
params.xwidth=48;
params.ywidth=36;

[x, y, fr] = get_saccade_locked_activity(Trials, params);
plot_params.xwidth      = 48;
plot_params.ywidth      = 36;
plot_params.filtsize    = [10 10];
plot_params.filtsigma   = 2;
plot_params.fig_Handle = r_mov_par.figHand;
plot_params.axes_Handle = [0.53 0.2 .42 .6];
plotRF(x, y, fr, plot_params);

h = plot_params.fig_Handle;

end