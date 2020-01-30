function probe = makeProbeStruct(Trials)

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
probeTrigTime = -time_before_probe:dt:time_after_probe;
sigma = 10;

% how many channels are there?
for i = 1:length(Trials(1).Electrodes)
    chanList(i)=~isempty(Trials(1).Electrodes(i).Units);
end
chanList=find(chanList);

% initialize probe struct
probe.probeNum = NaN;
probe.saccNum = NaN;
probe.numSaccs = NaN;
probe.trialNum = NaN;
probe.rewardedSacc = NaN;
probe.fixProbe=NaN;
probe.saccProbe=NaN;
probe.t=NaN;
probe.t_fix_lock=NaN;
probe.t_sacc_start_lock=NaN;
probe.t_sacc_end_lock=NaN;
probe.t_sacc_nextEnd_lock=NaN;
probe.x_raw=NaN;
probe.x_curFix=NaN;
probe.x_oneFixAhead=NaN;
probe.x_twoFixAhead=NaN;
probe.y_raw=NaN;
probe.y_curFix=NaN;
probe.y_oneFixAhead=NaN;
probe.y_twoFixAhead=NaN;
probe.trode=NaN;

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
       
        saccade.trial=curtrial;
        saccade.sacc_num = sacc_num;
        
        % get position and timing of the previous saccade's ending
        saccade.fix.t=double(Trials(curtrial).Saccades(sc).t_start_prev_fix);
        saccade.fix.x=double(Trials(curtrial).Saccades(sc).meanX_prev_fix);
        saccade.fix.y=double(Trials(curtrial).Saccades(sc).meanY_prev_fix);
        
        saccade.start.t=double(Trials(curtrial).Saccades(sc).t_start_sacc);
        saccade.start.x=double(Trials(curtrial).Saccades(sc).x_sacc_start);
        saccade.start.y=double(Trials(curtrial).Saccades(sc).y_sacc_start);
        saccade.end.t=double(Trials(curtrial).Saccades(sc).t_end_sacc);
        saccade.end.x=double(Trials(curtrial).Saccades(sc).x_sacc_end);
        saccade.end.y=double(Trials(curtrial).Saccades(sc).y_sacc_end);
        
        if sacc_num<numsacs
            saccade.nextEnd.x=double(Trials(curtrial).Saccades(sc+1).x_sacc_end);
            saccade.nextEnd.y=double(Trials(curtrial).Saccades(sc+1).y_sacc_end);
            saccade.nextEnd.t=double(Trials(curtrial).Saccades(sc+1).t_end_sacc);
        else
            saccade.nextEnd.x=NaN;
            saccade.nextEnd.y=NaN;
            saccade.nextEnd.t=NaN;
        end
        
        % save off rewarded fixations
        if ~isempty(rwdtime) && ~isempty(rwd_sac)
            if rwd_sac==(sc+1)
                saccade.rewarded=1;
            else saccade.rewarded=0;
            end
        else saccade.rewarded=0;
        end
        
        % get all probes that fall within two different windows
        % (1) between fixation start and saccade start
        % (2) between saccade start and saccade end
        fp=find(probes(:,3)>=saccade.fix.t & probes(:,3)<=saccade.start.t);
        sp=find(probes(:,3)>=saccade.start.t & probes(:,3)<=saccade.end.t);
        
        cProbe=[];
        for pridx = 1:size(probes,1)
            cpT = probes(pridx,3);  
            start_time = cpT-time_before_probe;
            end_time = cpT+time_after_probe;            
            
            cProbe.probeNum = pridx;
            cProbe.saccNum = sacc_num;
            cProbe.numSaccs = numsacs;
            cProbe.trialNum = curtrial;
            cProbe.rewardedSacc = saccade.rewarded;
            if ismember(pridx,fp) % if probe happened during fixation
                cProbe.fixProbe=1;
            else
                cProbe.fixProbe=0;
            end
            if ismember(pridx,sp) % if probe happened during saccade
                cProbe.saccProbe=1; 
            else
                cProbe.saccProbe=0;
            end
            cProbe.t=cpT;
            cProbe.t_fix_lock=cpT-saccade.fix.t;
            cProbe.t_sacc_start_lock=cpT-saccade.start.t;
            cProbe.t_sacc_end_lock=cpT-saccade.end.t;
            cProbe.t_sacc_nextEnd_lock=cpT-saccade.nextEnd.t;
            
            cProbe.x_raw=probes(pridx,1);
            cProbe.x_curFix=probes(pridx,1)-saccade.fix.x;
            cProbe.x_oneFixAhead=probes(pridx,1)-saccade.end.x;
            cProbe.x_twoFixAhead=probes(pridx,1)-saccade.nextEnd.x;
            cProbe.y_raw=probes(pridx,2);
            cProbe.y_curFix=probes(pridx,2)-saccade.fix.y;
            cProbe.y_oneFixAhead=probes(pridx,2)-saccade.end.y;
            cProbe.y_twoFixAhead=probes(pridx,1)-saccade.nextEnd.y;
            
            cTrode=[];
            for trode=1:length(chanList)
                curtrode=chanList(trode);
                num_units=length(Trials(curtrial).Electrodes(curtrode).Units);
                unit=[];
                for u = 2:num_units
                    sTimes = Trials(curtrial).Electrodes(curtrode).Units(u).Times;
                    probe_sTimes = sTimes(sTimes>start_time & sTimes<end_time)- double(cpT);
                    probeTrigSpikes = buildSpikeTrain(probe_sTimes,0,-time_before_probe,time_after_probe,dt);
                    probeTS = gauss_spTrConvolve(probeTrigSpikes,dt,sigma);
                    probeFR = mean(probeTS(probeTrigTime>80 & probeTrigTime<150)).*1000;
                    
                    %unit(u-1).spikeTimes = probe_sTimes;
                    unit(u-1).probeFR = probeFR;
                    %unit(u-1).timeBins = -time_before_probe:dt:time_after_probe;
                end
                cTrode(trode).unit=unit;
            end  
            cProbe.trode=cTrode;
            probe(end+1)=cProbe;
        end
    end
    disp(num2str(curtrial))
end

probe(1)=[];

        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
%         
%         
%         for pr_fp = 1:length(fp)
%             fpdx = fp(pr_fp);
%             saccade(scInc).fix_probes(pr_fp).t=probes(fpdx,3);
%             saccade(scInc).fix_probes(pr_fp).x=probes(fpdx,1);
%             saccade(scInc).fix_probes(pr_fp).y=probes(fpdx,2);
%             saccade(scInc).fix_probes(pr_fp).eye_x = eyeX(ismember(eyeTime,probes(fpdx,3)));
%             saccade(scInc).fix_probes(pr_fp).eye_y = eyeY(ismember(eyeTime,probes(fpdx,3)));
%             
%             cpT = probes(fpdx,3);  
%             start_time = cpT-time_before_probe;
%             end_time = cpT+time_after_probe;
%             
%             trodeCtr=1;
%             for trode=chanList
%                 
%                 num_units=length(Trials(curtrial).Electrodes(trode).Units);
%                 for u = 2:num_units
%                     sTimes = Trials(curtrial).Electrodes(trode).Units(u).Times;
%                     probe_sTimes = sTimes(sTimes>start_time & sTimes<end_time)- double(cpT);
%                     probeTrigSpikes = buildSpikeTrain(probe_sTimes,0,-time_before_probe,time_after_probe,dt);
%                     probeTS = gauss_spTrConvolve(probeTrigSpikes,dt,sigma);
%                     probeFR = mean(probeTS(probeTrigTime>80 & probeTrigTime<150)).*1000;
%                     saccade(scInc).fix_probes(pr_fp).trode(trodeCtr).unit(u-1).times=probeTrigSpikes;
%                     saccade(scInc).fix_probes(pr_fp).trode(trodeCtr).unit(u-1).times_gauss=probeTS;
%                     saccade(scInc).fix_probes(pr_fp).trode(trodeCtr).unit(u-1).firing_rate=probeFR;
%                 end
%                 trodeCtr=trodeCtr+1;
%             end
%         end
%         for pr_sp = 1:length(sp)
%             spdx = sp(pr_sp);
%             saccade(scInc).sacc_probes(pr_sp).t=probes(spdx,3);
%             saccade(scInc).sacc_probes(pr_sp).x=probes(spdx,1);
%             saccade(scInc).sacc_probes(pr_sp).y=probes(spdx,2);
%             saccade(scInc).sacc_probes(pr_sp).eye_x = eyeX(ismember(eyeTime,probes(spdx,3)));
%             saccade(scInc).sacc_probes(pr_sp).eye_y = eyeY(ismember(eyeTime,probes(spdx,3)));
%             
%             cpT = probes(spdx,3);  
%             start_time = cpT-time_before_probe;
%             end_time = cpT+time_after_probe;
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
%                     saccade(scInc).sacc_probes(pr_sp).trode(trodeCtr).unit(u-1).times=probeTrigSpikes;
%                     saccade(scInc).sacc_probes(pr_sp).trode(trodeCtr).unit(u-1).times_gauss=probeTS;
%                     saccade(scInc).sacc_probes(pr_sp).trode(trodeCtr).unit(u-1).firing_rate=probeFR;
%                 end
%                 trodeCtr=trodeCtr+1;
%             end
%         end