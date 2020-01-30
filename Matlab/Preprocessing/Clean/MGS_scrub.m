function Trials=MGS_scrub(Trials)

amps=[];
dists=[];
% screen out saccades with amplitudes > 20 or < 3 deg, and with starting
% distances from center > 5
badTrials=[];
for i = 1:length(Trials)
    badSaccs=[];
    for s= 1:length(Trials(i).Saccades)
        curAmp=Trials(i).Saccades(s).sacc_amp;
        curx=Trials(i).Saccades(s).x_sacc_start;
        cury=Trials(i).Saccades(s).y_sacc_start;
        curdist = sqrt(curx.^2 + cury.^2);
        
        if curAmp>20 || curAmp<3 || curdist>5
            badSaccs(end+1)=s;
        else
            amps(end+1)=curAmp;
            dists(end+1)=curdist;
        end
    end
    Trials(i).Saccades(badSaccs)=[];
    if isempty(Trials(i).Saccades)
        badTrials(end+1)=i;
    end
end
Trials(badTrials)=[];

% grab the angle and eccentricity conditions, along with the x and y
% position of the saccade landing points (assuming the first saccade is the
% one we are interested in). 
for i = 1:length(Trials)
    events = [Trials(i).Events(:).Code];
    angCond(i) = events((events-3330)<10 & (events-3330)>=0)-3330;
    eccCond(i) = events((events-3320)<10 & (events-3320)>=0)-3320;
    x(i) = Trials(i).Target.x;
    y(i) = Trials(i).Target.y;
    xx(i) = Trials(i).Saccades(1).x_sacc_end;
    yy(i) = Trials(i).Saccades(1).y_sacc_end;
    rew(i) = Trials(i).Reward;
end

% fix all trials where the target location is erroneous
% also, plot all the rewarded fixations next to their target
for i=1:8
    for ii = 1:3
        % grab the most frequent x and y values for a given angle and
        % eccentricity. This will help us screen out erroneous values
        idx = angCond==i & eccCond==ii;
        mxy = mode([x(idx)' y(idx)']);
        x(idx)=mxy(1);
        y(idx)=mxy(2);
        
        % plot stuff
        hold all
        plot(xx(idx & rew),yy(idx & rew),'x')
        plot(x(idx),y(idx),'ko','linewidth',3)
        
        % fix the Trials struct with the correct x and y locations now
        fidx = find(idx);
        for fi=1:length(fidx)
            Trials(fidx(fi)).Target.x=mxy(1);
            Trials(fidx(fi)).Target.y=mxy(2);
        end
    end
end
