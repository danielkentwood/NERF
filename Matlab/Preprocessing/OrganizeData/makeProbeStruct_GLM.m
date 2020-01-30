function [probes,fixations] = makeProbeStruct_GLM(Trials)

% get trials with probes
withProbe=[];
for i = 1:length(Trials)
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

% initialize variables
probeNum            =[];
fixNum              =[];
numSaccs            =[];
trialNum            =[];
rawTrialNum         =[];
rewardedSacc        =[];
fixProbe            =[];
saccProbe           =[];
saccPeakVel         =[];
expectedPeakVel     =[];
t_probe             =[];
t_fix               =[];
t_sacc              =[];
x_targ              =[];
y_targ              =[];
x_dist              =[];
y_dist              =[];
x_probe             =[];
x_curFix            =[];
x_oneFixAhead       =[];
y_probe             =[];
y_curFix            =[];
y_oneFixAhead       =[];

fixNum_f              =[];
numSaccs_f            =[];
trialNum_f            =[];
rawTrialNum_f         =[];
rewardedSacc_f        =[];
saccPeakVel_f         =[];
expectedPeakVel_f     =[];
t_fix_f               =[];
t_sacc_f              =[];
x_targ_f              =[];
y_targ_f              =[];
x_dist_f              =[];
y_dist_f              =[];
x_curFix_f            =[];
x_oneFixAhead_f       =[];
y_curFix_f            =[];
y_oneFixAhead_f       =[];



h = waitbar(0,'Please wait...');
% run the loop
for trial = 1:length(withProbe)
    % update wait bar
    waitbar(trial / length(withProbe))
    
    curtrial=withProbe(trial);
    rawtrial=Trials(curtrial).trialNumber;
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
        
        % get peak saccadic velocity
        saccade.peakVel=double(Trials(curtrial).Saccades(sc).peak_vel);
        saccade.e_pv=double(Trials(curtrial).Saccades(sc).expected_vel);
        
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
        
        saccade.targ.x=double(Trials(curtrial).Target.x);
        saccade.targ.y=double(Trials(curtrial).Target.y);
        saccade.dist.x=double(Trials(curtrial).Distractor.x);
        saccade.dist.y=double(Trials(curtrial).Distractor.y);

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
        
        
        fixNum_f = [fixNum_f;sacc_num];
        numSaccs_f = [numSaccs_f;numsacs];
        trialNum_f = [trialNum_f;curtrial];
        rawTrialNum_f = [rawTrialNum_f;rawtrial];
        rewardedSacc_f = [rewardedSacc_f;saccade.rewarded];
        saccPeakVel_f=[saccPeakVel_f;saccade.peakVel];
        expectedPeakVel_f=[expectedPeakVel_f;saccade.e_pv];
        t_fix_f=[t_fix_f;saccade.fix.t];
        t_sacc_f=[t_sacc_f;saccade.start.t];
        x_targ_f=[x_targ_f;saccade.targ.x];
        y_targ_f=[y_targ_f;saccade.targ.y];
        x_dist_f=[x_dist_f;saccade.dist.x];
        y_dist_f=[y_dist_f;saccade.dist.y];
        x_curFix_f=[x_curFix_f;saccade.fix.x];
        x_oneFixAhead_f=[x_oneFixAhead_f;saccade.end.x];
        y_curFix_f=[y_curFix_f;saccade.fix.y];
        y_oneFixAhead_f=[y_oneFixAhead_f;saccade.end.y];
        
        
        
        % get all probes that fall within two different windows
        % (1) between fixation start and saccade start
        % (2) between saccade start and saccade end
        fp=find(probes(:,3)>=saccade.fix.t & probes(:,3)<=saccade.start.t);
        sp=find(probes(:,3)>=saccade.start.t & probes(:,3)<=saccade.end.t);
        for pridx = 1:size(probes,1)
            if ~ismember(pridx,[fp;sp])
                continue
            end
            cpT = probes(pridx,3);  
            start_time = cpT-time_before_probe;
            end_time = cpT+time_after_probe;            
            
            probeNum = [probeNum;pridx];
            fixNum = [fixNum;sacc_num];
            numSaccs = [numSaccs;numsacs];
            trialNum = [trialNum;curtrial];
            rawTrialNum = [rawTrialNum;rawtrial];
            rewardedSacc = [rewardedSacc;saccade.rewarded];
            if ismember(pridx,fp) % if probe happened during fixation
                fixProbe=[fixProbe;1];
            else
                fixProbe=[fixProbe;0];
            end
            if ismember(pridx,sp) % if probe happened during saccade
                saccProbe=[saccProbe;1];
            else
                saccProbe=[saccProbe;0];
            end
            
            saccPeakVel=[saccPeakVel;saccade.peakVel];
            expectedPeakVel=[expectedPeakVel;saccade.e_pv];
            t_probe=[t_probe;cpT];
            t_fix=[t_fix;saccade.fix.t];
            t_sacc=[t_sacc;saccade.start.t];
            
            x_targ=[x_targ;saccade.targ.x];
            y_targ=[y_targ;saccade.targ.y];
            x_dist=[x_dist;saccade.dist.x];
            y_dist=[y_dist;saccade.dist.y];
            
            x_probe=[x_probe;probes(pridx,1)];
            x_curFix=[x_curFix;saccade.fix.x];
            x_oneFixAhead=[x_oneFixAhead;saccade.end.x];
            y_probe=[y_probe;probes(pridx,2)];
            y_curFix=[y_curFix;saccade.fix.y];
            y_oneFixAhead=[y_oneFixAhead;saccade.end.y];
        end
    end
    disp(num2str(curtrial))
end

close(h)


probes = table(probeNum,fixNum,numSaccs,trialNum,rawTrialNum,rewardedSacc,fixProbe,saccProbe,...
    saccPeakVel,expectedPeakVel,t_probe,t_fix,t_sacc,...
    x_targ,y_targ,x_dist,y_dist,x_probe,x_curFix,x_oneFixAhead,...
    y_probe,y_curFix,y_oneFixAhead);

fixations = table(fixNum_f,numSaccs_f,trialNum_f,rawTrialNum_f,rewardedSacc_f,saccPeakVel_f,...
    expectedPeakVel_f,t_fix_f,t_sacc_f,x_targ_f,y_targ_f,x_dist_f,y_dist_f,x_curFix_f,x_oneFixAhead_f,...
    y_curFix_f,y_oneFixAhead_f);
        
        
        
        
        
    