
function h = movement_RF_model(Trials, meta)

params.dt           = 10;
params.x_at_peak    = get_x_at_peakstd(Trials);
params.win_size     = 40;

[x, y, fr] = get_saccade_locked_activity(Trials, params);
plot_params.xwidth      = 48;
plot_params.ywidth      = 36;
plot_params.filtsize    = [10 10];
plot_params.filtsigma   = 2;
plot_params.fig_Handle = figure('position',[825 721 1068 596]);
plot_params.axes_Handle = [0.56 0.2 .42 .6];

plotRF(x, y, fr, plot_params);
hold on
title(meta.fname,'Interpreter','none')
hold off

plot_params.axes_Handle = [0.05 0.2 .43 0.6];
model.N = 6;
model.min_lambda = 'lambda_lse';
modelRF(x,y,fr,model,plot_params)
end