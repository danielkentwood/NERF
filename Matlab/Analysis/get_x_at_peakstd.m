function x = get_x_at_peakstd(Trials)
    params.plotflag = 0;
    params.errBars = 0;
    % create the radial perisaccadic time histogram with raster
    PSTH_r_mov = radial_PSacTH(Trials, params);
    for i = 1:length(PSTH_r_mov), y_all(i,:) = PSTH_r_mov(i).y; end
    [~, pyi] = max(std(y_all));
    x = PSTH_r_mov(1).x(pyi);
end