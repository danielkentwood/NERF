function probe = make_probe_table(Trials)

% Check if preprocessing has already been done on this
pre_check = any(~cellfun(@isempty,{Trials.Saccades}));
if ~pre_check
    Trials = saccade_detector(Trials);
    Trials = cleanTrialsStruct_v2(Trials);
end

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
averaging_window = [50 120];


% how many channels are there?
for i = 1:length(Trials(1).Electrodes)
    chanList(i)=~isempty(Trials(1).Electrodes(i).Units);
end
chanList=find(chanList);

%% initialize probe table variables
probeNum            =[];
saccNum             =[];
numSaccs            =[];
trialNum            =[];
rawTrialNum         =[];
rewardedSacc        =[];
fixProbe            =[];
saccProbe           =[];
saccPeakVel         =[];
expectedPeakVel     =[];
t                   =[];
t_fix_lock          =[];
t_sacc_start_lock   =[];
t_sacc_end_lock     =[];
t_sacc_nextEnd_lock =[];
x_targ              =[];
y_targ              =[];
x_dist              =[];
y_dist              =[];
x_probe             =[];
x_curFix            =[];
x_oneFixAhead       =[];
x_twoFixAhead       =[];
y_probe             =[];
y_curFix            =[];
y_oneFixAhead   	=[];
y_twoFixAhead   	=[];
units               =[];
unitsSC             =[];

%% run the loop
for trial = 1:length(withProbe)
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
            else
                saccade.rewarded=0;
            end
        else
            saccade.rewarded=0;
        end
        
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
            saccNum = [saccNum;sacc_num];
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
            t=[t;cpT];
            t_fix_lock=[t_fix_lock;cpT-saccade.fix.t];
            t_sacc_start_lock=[t_sacc_start_lock;cpT-saccade.start.t];
            t_sacc_end_lock=[t_sacc_end_lock;cpT-saccade.end.t];
            t_sacc_nextEnd_lock=[t_sacc_nextEnd_lock;cpT-saccade.nextEnd.t];
            
            x_targ=[x_targ;saccade.targ.x];
            y_targ=[y_targ;saccade.targ.y];
            x_dist=[x_dist;saccade.dist.x];
            y_dist=[y_dist;saccade.dist.y];
            
            x_probe=[x_probe;probes(pridx,1)];
            x_curFix=[x_curFix;saccade.fix.x];
            x_oneFixAhead=[x_oneFixAhead;saccade.end.x];
            x_twoFixAhead=[x_twoFixAhead;saccade.nextEnd.x];
            y_probe=[y_probe;probes(pridx,2)];
            y_curFix=[y_curFix;saccade.fix.y];
            y_oneFixAhead=[y_oneFixAhead;saccade.end.y];
            y_twoFixAhead=[y_twoFixAhead;saccade.nextEnd.y];
            
            probeFR=[];probeSC=[];
            for trode=1:length(chanList) % right now we are assuming there is just one electrode in the file
                curtrode=chanList(trode);
                
                
                if length(Trials(1).Electrodes(curtrode).Units)==1
                    unitvec=1:1;
                    unitsub=0;
                else
                    unitvec=2:length(Trials(1).Electrodes(curtrode).Units);
                    unitsub=1;
                end
                
                for u = unitvec % first unit is unsorted spikes
                    
                    sTimes = Trials(curtrial).Electrodes(curtrode).Units(u).Times;
                    probe_sTimes = sTimes(sTimes>start_time & sTimes<end_time)- double(cpT);
                    probeTrigSpikes = buildSpikeTrain(probe_sTimes,0,-time_before_probe,time_after_probe,dt);
                    probeTS = gauss_spTrConvolve(probeTrigSpikes,dt,sigma);
                    probeFR(u-unitsub) = mean(probeTS(probeTrigTime>averaging_window(1) & probeTrigTime<averaging_window(2))).*1000/dt; % firing rate
                    probeSC(u-unitsub) = length(probe_sTimes(probe_sTimes>averaging_window(1) & probe_sTimes<averaging_window(2))); % spike count
                end
            end
            units=[units;probeFR];
            unitsSC=[unitsSC;probeSC];
        end
    end
    disp(num2str(curtrial))
end

%% BUILD THE TABLE
probe = table(probeNum,saccNum,numSaccs,trialNum,rawTrialNum,rewardedSacc,fixProbe,saccProbe,...
    saccPeakVel,expectedPeakVel,t,t_fix_lock,t_sacc_start_lock,t_sacc_end_lock,t_sacc_nextEnd_lock,...
    x_targ,y_targ,x_dist,y_dist,x_probe,x_curFix,x_oneFixAhead,...
    x_twoFixAhead,y_probe,y_curFix,y_oneFixAhead,y_twoFixAhead,units,unitsSC);

%% FIX THE ISSUE OF SCREEN ONSET
% get firing rates for all 1st probes and all other probes
% then remove the median firing rate from the first probes and add on the
% median firing rate of all other probes (to remove the influence of the
% full field stimulation during the first probe).
fPmed=nanmedian(probe.units(probe.probeNum==1,:));
oPmed=nanmedian(probe.units(probe.probeNum>1,:));
for i=1:size(fPmed,2)
    probe.units(probe.probeNum==1,i)=probe.units(probe.probeNum==1,i)-fPmed(i)+oPmed(i);
end

%% SCREEN FOR BAD TRIALS
% magnitude of saccades
saccmag = sqrt((probe.y_oneFixAhead-probe.y_curFix).^2 + (probe.x_oneFixAhead-probe.x_curFix).^2);
probe(saccmag>45,:)=[];

% intersaccadic interval 
t_fix=probe.t-probe.t_fix_lock;
t_sacc_start = probe.t-probe.t_sacc_start_lock;
saccisi = t_sacc_start-t_fix;
% now screen for bad isi 
probe(saccisi>1500,:)=[];

% saccade duration
t_sacc_start = probe.t-probe.t_sacc_start_lock;
t_sacc_end = probe.t-probe.t_sacc_end_lock;
saccdur = t_sacc_end-t_sacc_start;
% now screen for bad sacc dur
probe(saccdur>300,:)=[];



    