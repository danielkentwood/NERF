% convert to absolute time (within a session)
function Trials = convert_to_absolute_time(Trials)

for i = 1:length(Trials)
    t_start = Trials(i).absolute_StartTime;
    
    for s = 1:length(Trials(i).Signals)
        Trials(i).Signals(s).Time = Trials(i).Signals(s).Time + t_start;
    end
    for e = 1:length(Trials(i).Electrodes)
       for u = 1:length(Trials(i).Electrodes(e).Units)
           Trials(i).Electrodes(e).Units(u).Times = Trials(i).Electrodes(e).Units(u).Times + t_start;
       end
    end
    for ev = 1:length(Trials(i).Events)
        Trials(i).Events(ev).Time = Trials(i).Events(ev).Time + t_start;
    end
    for sc = 1:length(Trials(i).Saccades)
        Trials(i).Saccades(sc).t_start_sacc = Trials(i).Saccades(sc).t_start_sacc + t_start;
        Trials(i).Saccades(sc).t_end_sacc = Trials(i).Saccades(sc).t_end_sacc + t_start;
        Trials(i).Saccades(sc).t_peak_vel = Trials(i).Saccades(sc).t_peak_vel + t_start;
        Trials(i).Saccades(sc).t_start_prev_fix = Trials(i).Saccades(sc).t_start_prev_fix + t_start;
        Trials(i).Saccades(sc).t_start_next_fix = Trials(i).Saccades(sc).t_start_next_fix + t_start;
    end
    
    Trials(i).probeXY_time(:,3) = Trials(i).probeXY_time(:,3) + t_start; 
end