% convert from old saccades format
function Trials = convertOldSaccades(Trials)

for i = 1:length(Trials)
    if isempty(Trials(i).Saccades)
        todelete(i)=1;
        continue
    else todelete(i)=0;
    end

    xPos = Trials(i).Signals(1).Signal;
    yPos = Trials(i).Signals(2).Signal;
    eyeTime = Trials(i).Signals(1).Time;
    
    Saccades = [];
    sacc_starts=[];
    sacc_ends=[];
    for ss = 1:length(Trials(i).Saccades)
        sacc_starts(ss)=find(eyeTime == Trials(i).Saccades(ss).saccade_start_time);
        sacc_ends(ss)=find(eyeTime == Trials(i).Saccades(ss).saccade_end_time);
    end
    
    for s = 1:length(Trials(i).Saccades)

        Saccades(s).trial=i;
        Saccades(s).sacc_num=Trials(i).Saccades(s).saccade_number;
        Saccades(s).t_start_sacc = Trials(i).Saccades(s).saccade_start_time;
        Saccades(s).t_end_sacc = Trials(i).Saccades(s).saccade_end_time;
        Saccades(s).peak_vel = Trials(i).Saccades(s).peak_velocity;
        Saccades(s).t_peak_vel = Trials(i).Saccades(s).peak_velocity_time;
        Saccades(s).x_sacc_start = Trials(i).Saccades(s).horizontal_position_start;
        Saccades(s).x_sacc_end = Trials(i).Saccades(s).horizontal_position_end;
        Saccades(s).y_sacc_start = Trials(i).Saccades(s).vertical_position_start;
        Saccades(s).y_sacc_end = Trials(i).Saccades(s).vertical_position_end;

        if s==1
            Saccades(s).t_start_prev_fix = eyeTime(1);
            Saccades(s).meanX_prev_fix = nanmean(xPos(1:sacc_starts(1)));
            Saccades(s).meanY_prev_fix = nanmean(yPos(1:sacc_starts(1)));
            Saccades(s).t_start_next_fix = eyeTime(sacc_ends(s));
            if length(Trials(i).Saccades)>1
                Saccades(s).meanX_next_fix = nanmean(xPos(sacc_ends(1):sacc_starts(2)));
                Saccades(s).meanY_next_fix = nanmean(yPos(sacc_ends(1):sacc_starts(2)));
            else
                Saccades(s).meanX_next_fix = nanmean(xPos(sacc_ends(1):length(xPos)));
                Saccades(s).meanY_next_fix = nanmean(yPos(sacc_ends(1):length(yPos)));
            end
        elseif s==length(Trials(i).Saccades)
            Saccades(s).t_start_prev_fix = eyeTime(sacc_ends(s-1));
            Saccades(s).meanX_prev_fix = nanmean(xPos(sacc_ends(s-1):sacc_starts(s)));
            Saccades(s).meanY_prev_fix = nanmean(yPos(sacc_ends(s-1):sacc_starts(s)));
            Saccades(s).t_start_next_fix = eyeTime(sacc_ends(s));
            
            endNextFix = sacc_ends(s)+50;
            if endNextFix>length(eyeTime)
                endNextFix = length(eyeTime);
            end
            Saccades(s).meanX_next_fix = nanmean(xPos(sacc_ends(s):endNextFix));
            Saccades(s).meanY_next_fix = nanmean(yPos(sacc_ends(s):endNextFix));   
        else
            Saccades(s).t_start_prev_fix = eyeTime(sacc_ends(s-1));
            Saccades(s).meanX_prev_fix = nanmean(xPos(sacc_ends(s-1):sacc_starts(s)));
            Saccades(s).meanY_prev_fix = nanmean(yPos(sacc_ends(s-1):sacc_starts(s)));
            Saccades(s).t_start_next_fix = eyeTime(sacc_ends(s));
            Saccades(s).meanX_next_fix = nanmean(xPos(sacc_ends(s):sacc_starts(s+1)));
            Saccades(s).meanY_next_fix = nanmean(yPos(sacc_ends(s):sacc_starts(s+1)));
        end
    end
    
    Trials(i).Saccades = Saccades;
        
end
Trials(logical(todelete))=[];
