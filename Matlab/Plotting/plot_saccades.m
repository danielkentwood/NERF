function plot_saccades(Trials, trialvec, sacc_cell, color)



for i = 1:length(trialvec)
    ct = trialvec(i);
    t = Trials(ct).Signals(1).Time;
    x = Trials(ct).Signals(1).Signal;
    y = Trials(ct).Signals(2).Signal;
    
    for s = sacc_cell{i}
        t_start = find(t==Trials(ct).Saccades(s).t_start_sacc);
        t_end   = find(t==Trials(ct).Saccades(s).t_end_sacc);

        hold on
        plot(x(t_start:t_end), y(t_start:t_end),'-','Color',color)
        plot(x(t_start), y(t_start),'k.','markersize',12)
        plot(x(t_end), y(t_end),'g.','markersize',12)
    end
end

