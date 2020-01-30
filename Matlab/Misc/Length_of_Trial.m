function out = Length_of_Trial(Trials,plotFlag)

if nargin<2
    plotFlag=0;
end

rwd_ecode=4090;
tri_st_ecode=4020;
ctr=1;
pvctr=1;

for i=1:length(Trials),sessions(i)=Trials(i).Session.num; end 
uSess=unique(sessions);

sacc_ctr=zeros(1,length(Trials));
isrewarded=[];
isrewarded2=[];
Time_trial=[];
Time_trial2=[];
sacc_isi=[];
sacc_ctr=[];
sacc_pv=[];
for i=1:length(Trials)
    curSess = Trials(i).Session.num;
    sessionID(i)=find(uSess==curSess);
    
    isrewarded(i)=logical(Trials(i).Reward);
    events = [Trials(i).Events.Code];
    event_time = [Trials(i).Events.Time];
    sacc_ctr(:,i)=[0;0];
    
    rwd_idx = find(events==rwd_ecode);
    isrewarded2(i)=~isempty(rwd_idx);
    tri_st_idxs = find(events==tri_st_ecode);
    if isempty(tri_st_idxs)
        continue
    end
    tri_st_idx = tri_st_idxs(end);
    
    % get trial duration and number of saccades in trial
    Time_trial(i)=Trials(i).absolute_EndTime-Trials(i).absolute_StartTime;
    if ~isempty(rwd_idx) && ~isempty(tri_st_idx) && ~isempty(Trials(i).Saccades)
        Time_trial2(1,ctr)=event_time(rwd_idx)-event_time(tri_st_idx);
        Time_trial2(2,ctr)=sessionID(i);
        ctr=ctr+1;
        
        % cycle through all saccades, count only those between the trial start
        % time and the reward time
        
        tri_start_time = event_time(tri_st_idx);
        rew_time = event_time(rwd_idx);
        sacc_start_times=[Trials(i).Saccades.t_start_sacc];
        sacc_end_times =[Trials(i).Saccades.t_end_sacc];
        
        good_sacc_idx = find(sacc_start_times>tri_start_time & sacc_end_times<rew_time);
        
        for s = good_sacc_idx
            if s==1
                sacc_isi(1,pvctr)=Trials(i).Saccades(s).t_start_sacc-tri_start_time;
            else
                sacc_isi(1,pvctr)=Trials(i).Saccades(s).t_start_sacc-Trials(i).Saccades(s-1).t_end_sacc;
            end
            sacc_isi(2,pvctr)=sessionID(i);
            sacc_ctr(1,i)=sacc_ctr(i)+1;
            sacc_ctr(2,i)=sessionID(i);
            sacc_pv(1,pvctr)=Trials(i).Saccades(s).peak_vel;
            sacc_pv(2,pvctr)=sessionID(i);
            pvctr=pvctr+1;
            %             end
        end
    end
end

out.num_saccs = sacc_ctr(:,logical(isrewarded));
out.trial_time = Time_trial2;
out.ave_pv = sacc_pv;
out.ave_isi = sacc_isi;


%% next analysis: probability of finding the target as a function of current distance to target (from current fixation)
% vectors needed:
% 1. distance to target from current fixation
% 2. logical vector of whether the target was found or not on the next
% saccade
% 3rd vector: whether the next saccade was in the direction of
% the target (or distractor) or not.
sacc_num=1;
rewardVec=[];targDist=[];targSessID=[];

for i = 1:length(Trials)
    tx = Trials(i).Target.x;
    ty = Trials(i).Target.y;
    dx = Trials(i).Distractor.x;
    dy = Trials(i).Distractor.y;
    
    events = [Trials(i).Events.Code];
    events_time = [Trials(i).Events.Time];
    
    rwd_idx = find(events==rwd_ecode);
    rwd_time=events_time(rwd_idx);
    
    % grab the orientation of the target
    orient = events(find(events==10000)+1)-10000;
    if isempty(orient)
        orientVec(i)=NaN;
    elseif orient==17
        orientVec(i)=1; % horizontal
    elseif orient==18
        orientVec(i)=0; % vertical
    end
    
   
    sacc_end_time=[];
    for s = 1:length(Trials(i).Saccades)
        % get the end time of the saccades 
        sacc_end_time(s) = Trials(i).Saccades(s).t_end_sacc;
    end
    if isempty(rwd_time)
    else
        [mins,minsdx]=min(abs(double(rwd_time)-sacc_end_time));
        rwd_sacc_time = sacc_end_time(minsdx);
    end

    for s = 1:length(Trials(i).Saccades)
        % use reward to infer whether the target was acquired
        prev_fixX = Trials(i).Saccades(s).meanX_prev_fix;
        prev_fixY = Trials(i).Saccades(s).meanY_prev_fix; 
        distX = prev_fixX-tx;
        distY = prev_fixY-ty; 
        distDistX = prev_fixX-dx;
        distDistY = prev_fixY-dy;
        targDist(sacc_num) = sqrt(distX.^2 + distY.^2);
        distDist(sacc_num) = sqrt(distDistX.^2 + distDistY.^2);
        targSessID(sacc_num)=Trials(i).Session.num;
        if isempty(rwd_idx)
            rewardVec(sacc_num)=0;
        else
            se_time = Trials(i).Saccades(s).t_end_sacc;
            if se_time==rwd_sacc_time
                rewardVec(sacc_num)=1;
            else rewardVec(sacc_num)=0;
            end
        end
        
        % now just try defining the target and distractor windows, and see
        % what the likelihood of saccading into the target/distractor
        % window is, given the distance
        next_fixX = Trials(i).Saccades(s).meanX_next_fix;
        next_fixY = Trials(i).Saccades(s).meanY_next_fix;
        tgt_nxt_distX = next_fixX-tx;
        tgt_nxt_distY = next_fixY-ty;
        dst_nxt_distX = next_fixX-dx;
        dst_nxt_distY = next_fixY-dy;
        
        tgt_nxt_dist=sqrt(tgt_nxt_distX.^2 + tgt_nxt_distY.^2);
        dst_nxt_dist=sqrt(dst_nxt_distX.^2 + dst_nxt_distY.^2);
        tgtYesVec(sacc_num)=tgt_nxt_dist<5;
        dstYesVec(sacc_num)=dst_nxt_dist<5;
        
        % does the orientation of the target matter?
        if orientVec(i)
            horizYesVec(sacc_num)=tgtYesVec(sacc_num);
            vertYesVec(sacc_num)=dstYesVec(sacc_num);
        elseif ~orientVec(i)
            horizYesVec(sacc_num)=dstYesVec(sacc_num);
            vertYesVec(sacc_num)=tgtYesVec(sacc_num);
        end

        sacc_num=sacc_num+1;
    end
end

out.inTarget = tgtYesVec;
out.inDistractor = dstYesVec;
out.inHorizontal = horizYesVec;
out.inVertical = vertYesVec;
out.distractorDist = distDist;
out.sessionID = sessionID;
out.rewardVec = rewardVec;
out.targDist = targDist;
out.degSpan=1:48;

uSess = unique(sessionID);
for u = 1:length(uSess)
    cursess = uSess(u);
    csvec = find(targSessID==cursess);    
    
    
    [n,out.bin]=histc(targDist(csvec),out.degSpan);
    [n,out.dstBin]=histc(distDist(csvec),out.degSpan);
    
    % cycle through each degree
    for i=1:length(out.degSpan)
        curDeg = out.degSpan(i);
        % build reward version
        cs_rv = rewardVec(csvec);
        out.findProb(u,i)=nanmean(cs_rv(out.bin==curDeg));
        
        % build target/distractor version
        cs_tyv = tgtYesVec(csvec);
        cs_dyv = dstYesVec(csvec);
        out.findProb_targ(u,i)=nanmean(cs_tyv(out.bin==curDeg));
        out.findProb_dist(u,i)=nanmean(cs_dyv(out.bin==curDeg));
        
        % build horizontal, vertical version
        cs_hyv = horizYesVec(csvec);
        cs_vyv = vertYesVec(csvec);
        out.findProb_horizontal(u,i)=nanmean(cs_hyv(out.bin==curDeg));
        out.findProb_vertical(u,i)=nanmean(cs_vyv(out.bin==curDeg));
    end
end

if plotFlag
    figure
    fp = smooth(nanmean(out.findProb));
%     fp = fp./sum(fp);
    plot(out.degSpan,fp,'linewidth',2)
    box off
    xlabel('Fixation distance from target (deg)')
    ylabel('Prob(NEXT SACCADE IS REWARDED)')
    ylim([0 1])
    title('Target Detectability (Reward)')
    
    figure
    fpt = smooth(nanmean(out.findProb_targ));
    fpd = smooth(nanmean(out.findProb_dist));
%     fpt_p = (fpt./sum([fpt; fpd]));
%     fpd_p = (fpd./sum([fpt; fpd]));
    plot(out.degSpan,fpt,'k','linewidth',2)
    hold on
    plot(out.degSpan,fpd,'r','linewidth',2)
    box off
    xlabel('Fixation distance from target/distractor (deg)')
    ylabel('Prob(NEXT SACCADE GOES TO TARG/DIST)')
    ylim([0 1])
    title('Target Detectability')
    lh2 = legend('Target','Distractor','location','best');
    set(lh2,'box','off')
    
    figure
    fph = smooth(nanmean(out.findProb_horizontal));
    fpv = smooth(nanmean(out.findProb_vertical));
%     fph_p = (fph./sum([fph; fpv]));
%     fpv_p = (fpv./sum([fph; fpv]));
    plot(out.degSpan,fph,'k','linewidth',2)
    hold on
    plot(out.degSpan,fpv,'r','linewidth',2)
    box off
    xlabel('Fixation distance from gabor (deg)')
    ylabel('Prob(NEXT SACCADE GOES TO HORIZ/VERT GABOR)')
    ylim([0 1])
    title('Orientation preference')
    lh3 = legend('Horizontal','Vertical','location','best');
    set(lh3,'box','off')
end

