function saccade = makeSaccadeStruct(Trials)

% to do:
% save angle of saccade


% get trials with saccades and probes
withSaccs=[];
withProbe=[];
for i = 1:length(Trials)
    if ~isempty(Trials(i).Saccades)
        withSaccs(end+1)=i;
    end
    if ~isempty(Trials(i).probeXY_time)
        withProbe(end+1)=i;
    end
end

% probe triggered average parameters
time_before_probe = 100;
time_after_probe = 300;
dt=5;
padding=dt*4;
probeTrigTime = -time_before_probe:dt:time_after_probe;
sigma = 10;
prInc=1;
scInc=1;
ctr=0;

% how many channels are there?
for i = 1:length(Trials(1).Electrodes)
    chanList(i)=~isempty(Trials(1).Electrodes(i).Units);
end
chanList=find(chanList);

for trial = 1:length(withProbe)
    curtrial=withProbe(trial);
    probes = double(Trials(curtrial).probeXY_time);
    cursacs = Trials(curtrial).Saccades;
    numsacs = length(Trials(curtrial).Saccades);
    cur_ecodes = double([Trials(curtrial).Events.Code]);
    cur_codeTimes = double([Trials(curtrial).Events.Time]);
    eyeX = double(Trials(curtrial).Signals(1).Signal);
    eyeY = double(Trials(curtrial).Signals(2).Signal);
    eyeTime = double(Trials(curtrial).Signals(1).Time);
    % get position and timing at start of trial
    % get timing of when target appears on the screen (ecode =
    % 4020)
    trial_start_index = find(cur_ecodes==4020);
    trial_start_time = cur_codeTimes(trial_start_index);
    % get reward time
    rwd = find(cur_ecodes==4090);
    rwdtime=cur_codeTimes(rwd);
    
    if ~isempty(rwdtime)
        curfixtimes = ([cursacs.t_start_prev_fix]+100); % add 100 ms buffer
        rwd_sac = max(find(curfixtimes<rwdtime));
    else rwd_sac =[];
    end
    
    rwd_noted=0;
    for sc = 1:numsacs
        sacc_num=Trials(curtrial).Saccades(sc).sacc_num;

        % check to see if the saccade is before the trial or after the
        % reward
        if isempty(trial_start_index),continue; end
        tooEarly=trial_start_time>Trials(curtrial).Saccades(sc).t_end_sacc;
        tooLate=rwdtime<Trials(curtrial).Saccades(sc).t_start_sacc;
        if isempty(rwdtime) % b/c sometimes rwdTime (and therefore tooLate) will be empty, which will break the boolean argument below
            if tooEarly
                continue
            end
        elseif tooEarly
            continue
        end
        
        saccade(scInc).trial=curtrial;
        saccade(scInc).sacc_num = sacc_num;
        
        % get position and timing of the previous saccade's ending
        saccade(scInc).fix.t=double(Trials(curtrial).Saccades(sc).t_start_prev_fix);
        saccade(scInc).fix.x=double(Trials(curtrial).Saccades(sc).meanX_prev_fix);
        saccade(scInc).fix.y=double(Trials(curtrial).Saccades(sc).meanY_prev_fix);
        
        saccade(scInc).start.t=double(Trials(curtrial).Saccades(sc).t_start_sacc);
        saccade(scInc).start.x=double(Trials(curtrial).Saccades(sc).x_sacc_start);
        saccade(scInc).start.y=double(Trials(curtrial).Saccades(sc).y_sacc_start);
        saccade(scInc).end.t=double(Trials(curtrial).Saccades(sc).t_end_sacc);
        saccade(scInc).end.x=double(Trials(curtrial).Saccades(sc).x_sacc_end);
        saccade(scInc).end.y=double(Trials(curtrial).Saccades(sc).y_sacc_end);
        
        % save off rewarded fixations
        if ~isempty(rwdtime) && ~isempty(rwd_sac)
            if rwd_sac==sc && sacc_num>1
                saccade(scInc-1).rewarded=1;
                ctr=ctr+1;
                rwd_noted=1;
            else saccade(scInc).rewarded=0;
            end
        else saccade(scInc).rewarded=0;
        end

        % get all probes that fall within two different windows
        % (1) between fixation start and saccade start
        % (2) between saccade start and saccade end
        fp=find(probes(:,3)>=saccade(scInc).fix.t & probes(:,3)<=saccade(scInc).start.t);
        sp=find(probes(:,3)>=saccade(scInc).start.t & probes(:,3)<=saccade(scInc).end.t);
        
        
%         for pridx = 1:size(probes,1)
%             cpT = probes(pridx,3);  
%             start_time = cpT-time_before_probe;
%             end_time = cpT+time_after_probe;            
%             
%             probes(prInc).probeNum = pridx;
%             probes(prInc).saccNum = sacc_num;
%             probes(prInc).trialNum = curtrial;
%             probes(prInc).saccNumTotal = scInc;
%             if ismember(pridx,fp) % if probe happened during fixation
%                 probes(prInc).fixProbe=1;
%             else
%                 probes(prInc).fixProbe=0;
%             end
%             if ismember(pridx,sp) % if probe happened during saccade
%                 probes(prInc).saccProbe=1; 
%             else
%                 probes(prInc).saccProbe=0;
%             end
%             probes(prInc).t_fix_lock=cpT-saccade(scInc).fix.t;
%             probes(prInc).t_sacc_start_lock=cpT-saccade(scInc).start.t;
%             probes(prInc).t_sacc_end_lock=cpT-saccade(scInc).end.t;
%             
%             probes(prInc).x_curFix=probes(pridx,1)-saccade(scInc).fix.x;
%             probes(prInc).x_oneFixAhead=probes(pridx,1)-saccade(scInc).end.x;
%             probes(prInc).y_curFix=probes(pridx,2)-saccade(scInc).fix.y;
%             probes(prInc).y_oneFixAhead=probes(pridx,2)-saccade(scInc).end.y;
%             
%             trodeCtr=1;
%             for trode=chanList
%                 num_units=length(Trials(curtrial).Electrodes(trode).Units);
%                 for u = 2:num_units
%                     sTimes = Trials(curtrial).Electrodes(trode).Units(u).Times;
%                     probe_sTimes = sTimes(sTimes>start_time & sTimes<end_time)- double(cpT);
%                     probeTrigSpikes = buildSpikeTrain(probe_sTimes,0,-time_before_probe,time_after_probe,dt);
%                     probeTS = gauss_spTrConvolve(probeTrigSpikes,dt,sigma);
%                     probeFR = mean(probeTS(probeTrigTime>80 & probeTrigTime<150)).*1000;
%                     
%                     probes(prInc).trode(trodeCtr).unit(u-1).spikeTimes = probe_sTimes;
%                     probes(prInc).trode(trodeCtr).unit(u-1).probeFR = probeFR;
%                     probes(prInc).trode(trodeCtr).unit(u-1).timeBins = -time_before_probe:dt:time_after_probe;
%                 end
%                 trodeCtr=trodeCtr+1;
%             end
%             prInc=prInc+1;
%         end
        
        for pr_fp = 1:length(fp)
            fpdx = fp(pr_fp);
            saccade(scInc).fix_probes(pr_fp).t=probes(fpdx,3);
            saccade(scInc).fix_probes(pr_fp).x=probes(fpdx,1);
            saccade(scInc).fix_probes(pr_fp).y=probes(fpdx,2);
            saccade(scInc).fix_probes(pr_fp).eye_x = eyeX(ismember(eyeTime,probes(fpdx,3)));
            saccade(scInc).fix_probes(pr_fp).eye_y = eyeY(ismember(eyeTime,probes(fpdx,3)));
            
            cpT = probes(fpdx,3);  
            start_time = cpT-time_before_probe;
            end_time = cpT+time_after_probe;
            
            trodeCtr=1;
            for trode=chanList
                
                num_units=length(Trials(curtrial).Electrodes(trode).Units);
                for u = 2:num_units
                    sTimes = Trials(curtrial).Electrodes(trode).Units(u).Times;
                    probe_sTimes = sTimes(sTimes>start_time & sTimes<end_time)- double(cpT);
                    probeTrigSpikes = buildSpikeTrain(probe_sTimes,0,-time_before_probe,time_after_probe,dt);
                    probeTS = gauss_spTrConvolve(probeTrigSpikes,dt,sigma);
                    probeFR = mean(probeTS(probeTrigTime>80 & probeTrigTime<150)).*1000;
                    saccade(scInc).fix_probes(pr_fp).trode(trodeCtr).unit(u-1).times=probeTrigSpikes;
                    saccade(scInc).fix_probes(pr_fp).trode(trodeCtr).unit(u-1).times_gauss=probeTS;
                    saccade(scInc).fix_probes(pr_fp).trode(trodeCtr).unit(u-1).firing_rate=probeFR;
                end
                trodeCtr=trodeCtr+1;
            end
        end
        for pr_sp = 1:length(sp)
            spdx = sp(pr_sp);
            saccade(scInc).sacc_probes(pr_sp).t=probes(spdx,3);
            saccade(scInc).sacc_probes(pr_sp).x=probes(spdx,1);
            saccade(scInc).sacc_probes(pr_sp).y=probes(spdx,2);
            saccade(scInc).sacc_probes(pr_sp).eye_x = eyeX(ismember(eyeTime,probes(spdx,3)));
            saccade(scInc).sacc_probes(pr_sp).eye_y = eyeY(ismember(eyeTime,probes(spdx,3)));
            
            cpT = probes(spdx,3);  
            start_time = cpT-time_before_probe;
            end_time = cpT+time_after_probe;
            
            trodeCtr=1;
            for trode=chanList
                num_units=length(Trials(curtrial).Electrodes(trode).Units);
                for u = 2:num_units
                    sTimes = Trials(curtrial).Electrodes(trode).Units(u).Times;
                    probe_sTimes = sTimes(sTimes>start_time & sTimes<end_time)- double(cpT);
                    probeTrigSpikes = buildSpikeTrain(probe_sTimes,0,-time_before_probe,time_after_probe,dt);
                    probeTS = gauss_spTrConvolve(probeTrigSpikes,dt,sigma);
                    probeFR = mean(probeTS(probeTrigTime>80 & probeTrigTime<150)).*1000;
                    saccade(scInc).sacc_probes(pr_sp).trode(trodeCtr).unit(u-1).times=probeTrigSpikes;
                    saccade(scInc).sacc_probes(pr_sp).trode(trodeCtr).unit(u-1).times_gauss=probeTS;
                    saccade(scInc).sacc_probes(pr_sp).trode(trodeCtr).unit(u-1).firing_rate=probeFR;
                end
                trodeCtr=trodeCtr+1;
            end
        end
        scInc=scInc+1;
    end
end





disp(['There were ' num2str(ctr) ' rewarded fixations'])