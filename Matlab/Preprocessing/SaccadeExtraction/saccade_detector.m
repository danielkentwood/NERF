function Trials=saccade_detector(Trials, debugging)
% saccade detection algorithm for natural scene search paradigm. Assumes
% there is a target and a reward for finding the target. 

disp('Detecting saccades...')

if nargin<2
    debugging=0;
end

if debugging
    clear;clc
    % assume we want to see each trial
    plotflag = 1;
    
    % define REX path
    ehf = experimentHomeFolder;
    rexpath = [ehf(1) ':\Data\Jiji\REX_Data'];
    % Open REX files
    [rex_fnames,rex_fpath] = uigetfile([rexpath filesep '*.*A'],'Select the REX files');
    if ~iscell(rex_fnames)
        rex_fnames={rex_fnames};
    end
    % convert to Trials struct
    combineREX
    Trials=REX_Trials;
    clear REX_Trials;
else
    plotflag = 0;
end



%% params 
rex_factor = 1.5; % if you're converting from degrees to REX units, this is the multiplier

min_sac_time = 30; % def: 20
max_sac_time = 120; % is this useful? maybe only at the end, after 
min_fix_time = 60; % def: 40
max_amplitude = 60*rex_factor; % check out plotTargsAndFixations.m to see the distribution of saccade amplitudes
min_amplitude = 1*rex_factor;

xOutBounds=(48/2)*(rex_factor+.1); % screen is 48 x 36 dva
yOutBounds=(36/2)*(rex_factor+.1); % 1.7 is the 1.5 rex factor, plus a .2 buffer 

pre_buffer = 100;










%% cycle through the trials and look for saccades using velocity profile
num_trials = length(Trials);
sac_ctr = 0;
tri_ctr = 0;

for trial_num = 1:num_trials
    % define ecodes and times
    ecodes=[Trials(trial_num).Events.Code];
    etimes=[Trials(trial_num).Events.Time];
    
    % define window start time
    window_start_code = ecodes==1001;
    window_start_time = etimes(window_start_code);  

    % get reward time
    rwd = find(ecodes==4090);
    if isempty(rwd)
        rwdtime(trial_num)=NaN;
    else
        rwdtime(trial_num)=etimes(rwd);
    end
    
    % if time hasn't been defined for the eye position frames, do it now
    if ~isfield(Trials(trial_num).Signals(1),'Time')
        Trials(trial_num).Signals(1).Time = (1:length(Trials(trial_num).Signals(1).Signal)) + double(window_start_time - pre_buffer);
        Trials(trial_num).Signals(2).Time = (1:length(Trials(trial_num).Signals(2).Signal)) + double(window_start_time - pre_buffer );
    end
    
    % get the start of the actual trial (i.e., go cue)
    bin1 = find(ecodes==4020); % This is the code for target onset; we're only interested in eye movements after this point
    if isempty(bin1)
%         disp(['Trial number ' num2str(trial_num) ' was not initiated.'])
        continue
    end
    tri_ctr = tri_ctr+1;
    start_time = etimes(bin1);
    if ~isempty(start_time)
        start_time=start_time(end);
    end
    horiz_signal_num = find(strcmp({Trials(2).Signals(:).Name}, 'horiz_eye'));
    vert_signal_num = find(strcmp({Trials(2).Signals(:).Name}, 'vert_eye'));
    
    % extract eye position and time
    xPos = Trials(trial_num).Signals(horiz_signal_num).Signal;
    yPos = Trials(trial_num).Signals(vert_signal_num).Signal;
    xPos(Trials(trial_num).Signals(horiz_signal_num).Time<(start_time-pre_buffer))=[];
    yPos(Trials(trial_num).Signals(horiz_signal_num).Time<(start_time-pre_buffer))=[];
    eyeTime = Trials(trial_num).Signals(horiz_signal_num).Time;
    eyeTime(Trials(trial_num).Signals(horiz_signal_num).Time<(start_time-pre_buffer))=[];

    % get tangential velocity and smooth it
    xVel = gradient(xPos);
    yVel = gradient(yPos);
    tangVel = sqrt(xVel.^2 + yVel.^2).*1000;
    tv = smooth(tangVel);
    
    % find the mean and std of the bottom 25% of velocity values. This will
    % give a rough estimation of a baseline above which the velocity likely
    % represents a saccade.
    if isempty(tv)
        disp(['trial ' num2str(trial_num) ' is empty'])
        continue
    end
    [f,x]=ecdf(tv); % get the empirical cumulative distribution
    [mf,mfdx]=min(abs(f-.75)); % take the bottom 25%
    muLow=mean(tv(tv<x(mfdx))); % get the mean of bottom 25%
    stdLow=std(tv(tv<x(mfdx))); % get STD (no, not that kind of STD, get your mind out of the gutter)
    % now apply the mean and std to find the saccades
    tv_overThresh = tv>(muLow+stdLow*2); % currently, threshold is mean + std * 2
    tv_overThresh([1 end])=0; % make sure first and last values are zeros (i.e., fixations)
    tv_ut_idx = find(~tv_overThresh); % grab index of vel frames UNDER threshold
    dtv_ut = diff(tv_ut_idx); % grab the derivative (to see where the breaks are)
    dtv_ut_bt = find(dtv_ut>min_sac_time); % get the indices of the cases 
        % where there are strings of N consecutive values above threshold, where 
        % N is the minimum duration of a saccade in ms
    
    % now define the start and end indices for each of the saccades and
    % fixations
    sacc_starts=tv_ut_idx(dtv_ut_bt)+1;
    sacc_ends = (sacc_starts-1)+dtv_ut(dtv_ut>min_sac_time)-1;
    fix_starts=[pre_buffer; sacc_ends+1];
    fix_ends = [sacc_starts-1;length(tv)];
    
    % get fixation durations and identify those that are too short
    fix_dur=(fix_ends-fix_starts);
    brief_fixations = fix_dur<min_fix_time;
    
    % shift the saccade endings to accomodate the joining of the saccades
    % before and after each string of too-short fixations
    % First, make sure there are no too-short fixations at the beginning or
    % end of the brief_fixation vector
    brief_fixations([1 end])=[0 0];
    % now do the shift
    sacc_ends(diff(brief_fixations)==1)=sacc_ends(diff(brief_fixations)==-1);
    % and then join the saccades
    sacc_starts = sacc_starts(~brief_fixations(1:end-1));
    sacc_ends = sacc_ends(~brief_fixations(1:end-1));
    % recompute the fixations
    fix_starts=[pre_buffer; sacc_ends+1];
    fix_ends = [sacc_starts-1;length(tv)];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % okay, now the velocity profile has been parsed
    % now it is time to start labeling the bad saccades and blinks
    % do this on the basis of saccade amplitude and whether the trace goes
    % too far outside of the screen window
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % compute saccade amplitudes
    amplitudes=sqrt((xPos(sacc_ends+1)-xPos(sacc_starts-1)).^2 ...
        + (yPos(sacc_ends+1)-yPos(sacc_starts-1)).^2);
    % see where the amplitudes are too large
    badAmplitudes=amplitudes>max_amplitude | amplitudes<min_amplitude;
    
    % see where absolute value of x and y goes out of the screen window
    outScreen=[];
    for mdx = 1:length(sacc_starts)
       xOut = any(abs(xPos(sacc_starts(mdx):sacc_ends(mdx)))>xOutBounds);
       yOut = any(abs(yPos(sacc_starts(mdx):sacc_ends(mdx)))>yOutBounds);
       outScreen(mdx)=xOut | yOut;
    end
    
    % now store the information about each saccade
    Saccades=[];
    s_num=1;
    for sc = 1:length(sacc_starts)

        % find peak velocity in this saccade
        [ptv, ptvi] = max(tv(sacc_starts(sc):sacc_ends(sc)));
        peakTV = ptv;
        time_pTV = ptvi;
        
        if outScreen(sc) || badAmplitudes(sc) || peakTV>3000
            continue
        end
        
        Saccades(s_num).trial=trial_num;
        Saccades(s_num).sacc_num=s_num;
        Saccades(s_num).t_start_sacc = eyeTime(sacc_starts(sc));
        Saccades(s_num).t_end_sacc = eyeTime(sacc_ends(sc));
        Saccades(s_num).peak_vel = peakTV;
        Saccades(s_num).t_peak_vel = eyeTime(time_pTV + sacc_starts(sc));
        Saccades(s_num).x_sacc_start = xPos(sacc_starts(sc));
        Saccades(s_num).x_sacc_end = xPos(sacc_ends(sc));
        Saccades(s_num).y_sacc_start = yPos(sacc_starts(sc));
        Saccades(s_num).y_sacc_end = yPos(sacc_ends(sc));
        
        Saccades(s_num).t_start_prev_fix = eyeTime(fix_starts(sc));
        Saccades(s_num).meanX_prev_fix = nanmean(xPos(fix_starts(sc):fix_ends(sc)));
        Saccades(s_num).meanY_prev_fix = nanmean(yPos(fix_starts(sc):fix_ends(sc)));
        Saccades(s_num).t_start_next_fix = eyeTime(fix_starts(sc+1));
        Saccades(s_num).meanX_next_fix = nanmean(xPos(fix_starts(sc+1):fix_ends(sc+1)));
        Saccades(s_num).meanY_next_fix = nanmean(yPos(fix_starts(sc+1):fix_ends(sc+1)));

        sac_ctr=sac_ctr+1;
        s_num=s_num+1;
    end
    Trials(trial_num).Saccades = Saccades;

    % visualize each trial
    if plotflag
        

        h=[];
        subplot(1,2,1)
        hold off
        h(1) = plot(tv);
        hold all
        h(2) = plot(find(tv>(muLow+stdLow*2)),tv(tv>(muLow+stdLow*2)),'g.');
        h(3) = plot(find(tv<(muLow+stdLow*2)),tv(tv<(muLow+stdLow*2)),'r.');
        if ~isnan(rwdtime(trial_num))
            rtime=rwdtime(trial_num)-start_time;
            h(4) = plot([rtime rtime],ylim,'k--');
        end
        h(5:5+length(sacc_starts)-1) = plot([sacc_starts';sacc_ends'],repmat(-1*max(tv)*.1,2,length(sacc_starts)),'k-','linewidth',2);
        
        if ~isnan(rwdtime(trial_num))
            hl = legend(h(1:5),'velocity','over threshold','under threshold','reward time','saccades','location','best');
            set(hl,'box','off')
        end
        title('Press ''ENTER'' to cycle through trials','fontsize',14)
        
        subplot(1,2,2)
        hold off
        plot(xPos(tv>(muLow+stdLow*2)),yPos(tv>(muLow+stdLow*2)),'g.','markersize',4)
        hold all
        plot(xPos(tv<(muLow+stdLow*2)),yPos(tv<(muLow+stdLow*2)),'r.','markersize',4)
        if ~isnan(rwdtime(trial_num))
            rtime=rwdtime(trial_num)-start_time;
            plot(xPos(rtime),yPos(rtime),'ko','linewidth',3)
        end
        for s_num = 1:length(Trials(trial_num).Saccades)
            plot(Saccades(s_num).meanX_prev_fix,Saccades(s_num).meanY_prev_fix,'mo','linewidth',2)
        end
        addScreenFrame([48 36]*1.5,[0 0 0])
        addScreenFrame([48 36]*1.7,[0 0 0])
        plot(xlim,[0 0],'k')
        plot([0 0],ylim,'k')
        set(gcf,'position',[72         358        1735         603])

        ginput();
        pause(0.5)
    end
end
    
disp(['There were ' num2str(sac_ctr) ' saccades detected in ' num2str(tri_ctr) ' trials.'])

for i = 1:length(Trials)
    if isempty(Trials(i).Saccades)
        todelete(i)=logical(1);
    else todelete(i)=logical(0);
    end
end
Trials(todelete)=[];





