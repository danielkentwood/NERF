% clean up the Trials struct, add another struct that tracks performance
% and condition variables

numSessions = Trials(end).Session.num;
for i = 1:length(Trials),sessVec(i)=Trials(i).Session.num;end

for n = 1:numSessions
    curSessTrials = find(sessVec==n);
    
    all_tx=[];
    all_ty=[];
    all_rx=[];
    all_ry=[];
    for i = 1:length(curSessTrials)
        curTrial=curSessTrials(i);
        
        IDX.numSaccs(curTrial) = length(Trials(curTrial).Saccades);
        events = [Trials(curTrial).Events.Code];
        time   = [Trials(curTrial).Events.Time];
        
        % get target location
        targDX = find(events==12000);
        if isempty(targDX)
            tx=NaN;
            ty=NaN;
        else
            tx=events(targDX(1)+1)-12000;
            ty=events(targDX(1)+2)-12000;
        end
        
        all_tx(i) = double(tx);
        all_ty(i) = double(ty);
        
        % get eye position and apply REX factor of 1.5 to convert to dva
        Trials(curTrial).Signals(1).Signal = Trials(curTrial).Signals(1).Signal./1.5;
        Trials(curTrial).Signals(2).Signal = Trials(curTrial).Signals(2).Signal./1.5;
        for sc = 1:length(Trials(curTrial).Saccades)
            cursc = Trials(curTrial).Saccades(sc);
            Trials(curTrial).Saccades(sc).x_sacc_start = cursc.x_sacc_start./1.5;
            Trials(curTrial).Saccades(sc).x_sacc_end = cursc.x_sacc_end./1.5;
            Trials(curTrial).Saccades(sc).y_sacc_start = cursc.y_sacc_start./1.5;
            Trials(curTrial).Saccades(sc).y_sacc_end = cursc.y_sacc_end./1.5;
            Trials(curTrial).Saccades(sc).meanX_prev_fix = cursc.meanX_prev_fix./1.5;
            Trials(curTrial).Saccades(sc).meanY_prev_fix = cursc.meanY_prev_fix./1.5;
            Trials(curTrial).Saccades(sc).meanX_next_fix = cursc.meanX_next_fix./1.5;
            Trials(curTrial).Saccades(sc).meanY_next_fix = cursc.meanY_next_fix./1.5;
        end
        
        eyex=Trials(curTrial).Signals(1).Signal;
        eyey=Trials(curTrial).Signals(2).Signal;
        eyet=Trials(curTrial).Signals(1).Time;
        rwd = find(events==4090);
        
        % screen out trials where there is no reward
        if ~isempty(rwd)
            rwdtime=time(rwd);
            r_x=eyex(eyet==rwdtime);
            r_y=eyey(eyet==rwdtime);
            all_rx(i)=r_x;
            all_ry(i)=r_y;
        else
            all_rx(i)=NaN;
            all_ry(i)=NaN;
        end
    end
    
    % get the coefficient between the eye position at reward and the estimated
    % target location. This will make up for any extra error in the metrics
    % conversion between pixels and degrees.
    good=intersect(find(~isnan(all_rx)),find(~isnan(all_tx)));
    bx=polyfit(all_rx(good),all_tx(good),1);
    by=polyfit(all_ry(good),all_ty(good),1);
    
    for i = 1:length(Trials)
        events = [Trials(i).Events.Code];
        time   = [Trials(i).Events.Time];
        
        % get the probes
        probeDX = events==13000;
        IDX.numProbe(i) = sum(probeDX);
        probeDXF = find(probeDX);
        badpps=[];
        
        % update the probe location
        for pp = 1:sum(probeDX)
            Trials(i).probeXY_time(pp,1)=(double(events(probeDXF(pp)+1))-13000)./bx(1);
            Trials(i).probeXY_time(pp,2)=(double(events(probeDXF(pp)+2))-13000)./by(1);
            Trials(i).probeXY_time(pp,3)=time(probeDXF(pp)+1);
            
            % make sure the 1300 code is not the actual xy coordinate
            if any(events((probeDXF(pp)-2):(probeDXF(pp)-1))==13000)
                badpps=[badpps pp];
            end
        end
        if ~isempty(badpps)
            Trials(i).probeXY_time(badpps,:)=[];
        end
        
        % update target and distractor location
        distDX = find(events==11000);
        targDX = find(events==12000);
        if isempty(targDX) || isempty(distDX)
            Trials(i).Target.x=NaN;
            Trials(i).Target.y=NaN;
            Trials(i).Distractor.x=NaN;
            Trials(i).Distractor.y=NaN;
        else
            Trials(i).Target.x=(double(events(targDX(1)+1))-12000)./bx(1);
            Trials(i).Target.y=(double(events(targDX(1)+2))-12000)./bx(1);
            Trials(i).Distractor.x=(double(events(distDX(1)+1))-11000)./bx(1);
            Trials(i).Distractor.y=(double(events(distDX(1)+2))-11000)./bx(1);
        end
    end
    
end



IDX.withSaccs = logical(IDX.numSaccs);
IDX.withProbe = logical(IDX.numProbe);

clearvars -except Trials IDX

