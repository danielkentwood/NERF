% clean up the Trials struct, add another struct that tracks performance
% and condition variables
function Trials = cleanTrialsStruct_v2(Trials)


numSessions = Trials(end).Session.num;
for i = 1:length(Trials),sessVec(i)=Trials(i).Session.num;end

for n = 1:numSessions
    curSessTrials = find(sessVec==n);
    
    
    % first, center the cloud of initial eye positions on [0,0]
    mx=[];my=[];
    for i = 1:length(curSessTrials)
        curTrial=curSessTrials(i);
        
        events = [Trials(curTrial).Events.Code];
        time   = [Trials(curTrial).Events.Time];
        eyex   = Trials(curTrial).Signals(1).Signal;
        eyey   = Trials(curTrial).Signals(2).Signal;
        eyet   = Trials(curTrial).Signals(1).Time;
        
        fix_off_time=time(events==4019);
        tgt_on_times=time(events==4020);
        tgt_on_time=tgt_on_times(end);
        
        if isempty(tgt_on_time)
            mx(i)=NaN;
            my(i)=NaN;
            continue
        end
        mx(i) = mean(eyex((find(eyet==tgt_on_time)-20):find(eyet==tgt_on_time)));
        my(i) = mean(eyey((find(eyet==tgt_on_time)-20):find(eyet==tgt_on_time)));
    end
    
    % Now create the Saccades field in the Trials struct. Contains metrics
    % for each identified saccade in a trial. 
    nmx = nanmedian(mx);
    nmy = nanmedian(my);
    for i = 1:length(curSessTrials)
        curTrial=curSessTrials(i);
        oldSig=Trials(curTrial).Signals;
        
        Trials(curTrial).Signals(1).Signal=oldSig(1).Signal-nmx;
        Trials(curTrial).Signals(2).Signal=oldSig(2).Signal-nmy;
        
        for sc = 1:length(Trials(curTrial).Saccades)
            cursc = Trials(curTrial).Saccades(sc);
            Trials(curTrial).Saccades(sc).x_sacc_start = cursc.x_sacc_start-nmx;
            Trials(curTrial).Saccades(sc).x_sacc_end = cursc.x_sacc_end-nmx;
            Trials(curTrial).Saccades(sc).y_sacc_start = cursc.y_sacc_start-nmy;
            Trials(curTrial).Saccades(sc).y_sacc_end = cursc.y_sacc_end-nmy;
            Trials(curTrial).Saccades(sc).meanX_prev_fix = cursc.meanX_prev_fix-nmx;
            Trials(curTrial).Saccades(sc).meanY_prev_fix = cursc.meanY_prev_fix-nmy;
            Trials(curTrial).Saccades(sc).meanX_next_fix = cursc.meanX_next_fix-nmx;
            Trials(curTrial).Saccades(sc).meanY_next_fix = cursc.meanY_next_fix-nmy;
            Trials(curTrial).Saccades(sc).rewarded = 0;
        end
        
        % note if the saccade was rewarded or not
        events = [Trials(curTrial).Events.Code];
        time   = [Trials(curTrial).Events.Time];
        rew_time = double(time(events==4090));
        if ~isempty(rew_time)
            sacc_offsets = double([Trials(curTrial).Saccades.t_end_sacc]);
            rew_sacc = find(sacc_offsets-rew_time<0,1,'first');
            if ~isempty(rew_sacc)
                Trials(curTrial).Saccades(rew_sacc).rewarded = 1;
            end
        end
    end
    
    
    
    
    
    
    
    
    % now, apply REX factor and fit to targ locations to minimize gain
    % inaccuracies
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
    
    for i = 1:length(curSessTrials)
        curTrial=curSessTrials(i);
        events = [Trials(curTrial).Events.Code];
        time   = [Trials(curTrial).Events.Time];
        
        % get the probes
        probeDX = events==13000;
        IDX.numProbe(curTrial) = sum(probeDX);
        probeDXF = find(probeDX);
        badpps=[];
        
        % update the probe location
        for pp = 1:sum(probeDX)
            Trials(curTrial).probeXY_time(pp,1)=(double(events(probeDXF(pp)+1))-13000)./bx(1);
            Trials(curTrial).probeXY_time(pp,2)=(double(events(probeDXF(pp)+2))-13000)./by(1);
            Trials(curTrial).probeXY_time(pp,3)=time(probeDXF(pp)+1);
            
            % make sure the 1300 code is not the actual xy coordinate
            if any(events((probeDXF(pp)-2):(probeDXF(pp)-1))==13000)
                badpps=[badpps pp];
            end
        end
        if ~isempty(badpps)
            Trials(curTrial).probeXY_time(badpps,:)=[];
        end
        
        % update target and distractor information
        distDX = find(events==11000);
        targDX = find(events==12000);
        if isempty(targDX) 
            Trials(curTrial).Target.x=NaN;
            Trials(curTrial).Target.y=NaN;
            Trials(curTrial).Target.isHoriz=NaN;
            Trials(curTrial).Target.onset=NaN;
        else
            Trials(curTrial).Target.x=(double(events(targDX(1)+1))-12000)./bx(1);
            Trials(curTrial).Target.y=(double(events(targDX(1)+2))-12000)./bx(1);
                        
            ordx = find([Trials(curTrial).Events.Code]==10000);
            if ~isempty(ordx)
                orient = Trials(curTrial).Events(ordx+1).Code-10000;
                if orient==17
                    Trials(curTrial).Target.isHoriz = 1;
                else
                    Trials(curTrial).Target.isHoriz = 0;
                end
            else Trials(curTrial).Target.isHoriz = NaN;
            end

            Trials(curTrial).Target.t_onset=Trials(curTrial).Events(targDX(1)).Time;
        end
        
        targOFF = find(events==4029);
        if isempty(targOFF)
            Trials(curTrial).Target.offset=NaN;
        else
            Trials(curTrial).Target.t_offset=Trials(curTrial).Events(targOFF(1)).Time;
        end
        
        if isempty(distDX)
            Trials(curTrial).Distractor.x=NaN;
            Trials(curTrial).Distractor.y=NaN;
        else
            Trials(curTrial).Distractor.x=(double(events(distDX(1)+1))-11000)./bx(1);
            Trials(curTrial).Distractor.y=(double(events(distDX(1)+2))-11000)./bx(1);
        end
        
        % get information about fixation onset and offset
        fixON = find(events==4010);
        if isempty(fixON)
            Trials(curTrial).Fixation.t_on = NaN;
        else
            Trials(curTrial).Fixation.t_on = Trials(curTrial).Events(fixON(1)).Time;
        end
        fixOFF= find(events==4019);
        if isempty(fixOFF)
            Trials(curTrial).Fixation.t_off= NaN;
        else
            Trials(curTrial).Fixation.t_off= Trials(curTrial).Events(fixOFF(1)).Time;
        end
    end
end


%% get main sequence (expected velocity relative to amplitude)
saccAmp=[];
pv=[];
for i = 1:length(Trials)
    for s = 1:length(Trials(i).Saccades)
        cs = Trials(i).Saccades(s);
        saccAmp = [saccAmp sqrt((cs.y_sacc_end-cs.y_sacc_start).^2 + (cs.x_sacc_end-cs.x_sacc_start).^2)];
        Trials(i).Saccades(s).sacc_amp=saccAmp(end);
        pv = [pv cs.peak_vel];
    end
end

binwidth=25;
e_vel=[];
for i = 1:length(Trials)
    for s = 1:length(Trials(i).Saccades)
        cs = Trials(i).Saccades(s);
        camp = cs.sacc_amp;
        [s1,s2]=sort(saccAmp-camp);
        mvx = s2(s1>=0);
        lvx = s2(s1<=0);
        
        if length(mvx)>binwidth
            mvx=mvx(1:binwidth);
        end
        if length(lvx)>binwidth
            lvx=lvx((end-binwidth):end);
        end
        Trials(i).Saccades(s).expected_vel = mean([pv(mvx) pv(lvx)]);
        e_vel=[e_vel Trials(i).Saccades(s).expected_vel];
    end
end





%
% plot(saccAmp,pv,'ro')
% hold all
% plot(saccAmp,e_vel,'ko')
% xlabel('Amplitude')
% ylabel('Peak Velocity')
% title('Main Sequence')


% IDX.withSaccs = logical(IDX.numSaccs);
% IDX.withProbe = logical(IDX.numProbe);


