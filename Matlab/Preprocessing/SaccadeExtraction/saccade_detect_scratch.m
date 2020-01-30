function Trials=saccade_detector(Trials)

debugging=0;
if debugging
    % saccade_detect_scratch
    clear;clc
    
    % Open REX files
    [rex_fnames,rex_fpath] = uigetfile('*.*A','Select the REX files');
    if ~iscell(rex_fnames)
        rex_fnames={rex_fnames};
    end
    
    % convert to REX_Trials struct
    combineREX
    Trials=REX_Trials;
    clear REX_Trials;
end



% params 
min_sac_length = 10;
min_fix_time = 25;
pre_buffer = 100;

% cycle through the trials and look for saccades
num_trials = length(Trials);
sac_ctr = 0;
tri_ctr = 0;
for trial_num = 1:num_trials
    window_start_code = find([Trials(trial_num).Events(:).Code]==1001);
    window_start_time = Trials(trial_num).Events(window_start_code).Time;    
    
    % if time hasn't been defined for the eye position frames, do it now
    if ~isfield(Trials(trial_num).Signals(1),'Time')
        Trials(trial_num).Signals(1).Time = (1:length(Trials(trial_num).Signals(1).Signal)) + double(window_start_time - pre_buffer);
        Trials(trial_num).Signals(2).Time = (1:length(Trials(trial_num).Signals(2).Signal)) + double(window_start_time - pre_buffer );
    end
    
    bin1 = find([Trials(trial_num).Events(:).Code]==4019); % This is the code for fixation off; this is when we're interested in eye movements
    if isempty(bin1)
        disp(['Trial number ' num2str(trial_num) ' did not meet criteria for initiation by fixation.'])
        continue
    end
    tri_ctr = tri_ctr+1;
    
    start_time = Trials(trial_num).Events(bin1).Time;
    horiz_signal_num = find(strcmp([{Trials(2).Signals(:).Name}], 'horiz_eye'));
    vert_signal_num = find(strcmp([{Trials(2).Signals(:).Name}], 'vert_eye'));
    
    % extract eye position
    xPos = Trials(trial_num).Signals(horiz_signal_num).Signal;
    yPos = Trials(trial_num).Signals(vert_signal_num).Signal;
    xPos(Trials(trial_num).Signals(horiz_signal_num).Time<(start_time-100))=[];
    yPos(Trials(trial_num).Signals(horiz_signal_num).Time<(start_time-100))=[];
    eyeTime = Trials(trial_num).Signals(horiz_signal_num).Time;
    eyeTime(Trials(trial_num).Signals(horiz_signal_num).Time<(start_time-100))=[];

    % get tangential velocity and smooth it
    xVel = gradient(xPos);
    yVel = gradient(yPos);
    tangVel = sqrt(xVel.^2 + yVel.^2).*1000;
    smoothTV = smooth(tangVel);
    tv = smoothTV;
    
    % find the mean and std of the bottom 25% of velocity values. This will
    % give a rough estimation of a baseline above which the velocity likely
    % represents a saccade.
    [f,x]=ecdf(tv);
    [mf,mfdx]=min(abs(f-.75));
    muLow=mean(tv(tv<x(mfdx)));
    stdLow=std(tv(tv<x(mfdx)));
    % now apply the mean and std to find the saccades
    tv_overThresh = tv>(muLow+stdLow*2); % currently, threshold is mean + std * 2
    tv_ot_idx = find(tv_overThresh);
    tv_ut_idx = find(~tv_overThresh);
    dtv_ut = diff(tv_ut_idx);
    dtv_ut_bt = find(dtv_ut>min_sac_length); % get the indices of the cases 
    % where there are strings of N consecutive values above threshold, where 
    % N is the minimum length of a saccade in ms
    
    % now define the start and end indices for each of the saccades
    sacc_starts=tv_ut_idx(dtv_ut_bt)+1;
    sacc_ends = sacc_starts+dtv_ut(dtv_ut>min_sac_length);
    
    % now cycle through the saccades and deal with blinks and fixation
    % times that are too short
    peakTV=[];
    time_pTV=[];
    fix_length=[];
    for st = 1:length(sacc_starts)
        % find peak value in this saccade
        [ptv, ptvi] = max(tv(sacc_starts(st):sacc_ends(st)));
        peakTV(st) = ptv;
        time_pTV(st) = ptvi;
        % find length of fixation preceding this saccade
        if st==1
            fix_length(st)=sacc_starts(1)-1;
        else
            fix_length(st)=sacc_starts(st)-sacc_ends(st-1);
        end
    end
    % join the saccades where fix length between them is too short
    % note: first fix_length is the fixation before the first saccade, 
    % so when a fix_length is too short, you need to join the corresponding
    % saccade with the previous saccade
    fl_temp=fix_length;
    num_joined=0;
    for fl = 2:length(fix_length)
        if fix_length(fl)<min_fix_time
            sacc_starts(fl-num_joined)=[];
            sacc_ends(fl-1-num_joined)=[];
            [ptv,ptvi]=max([peakTV(fl-num_joined) peakTV(fl-num_joined-1)]);
            peakTV(fl-num_joined-1)=ptv;
            peakTV(fl-num_joined)=[];
            time_pTV(fl-num_joined-1)=time_pTV(fl-num_joined-ptvi+1);
            time_pTV(fl-num_joined)=[];
            fl_temp(fl-num_joined-1)=fl_temp(fl-num_joined-1)+fl_temp(fl-num_joined);
            fl_temp(fl-num_joined)=[];
            num_joined=num_joined+1;
        end
    end
    fix_length = fl_temp;

    
    % identify the spikes in velocity corresponding to blinks
    blinkSpikes=((peakTV-muLow)./stdLow) > 150;
    bsi=find(blinkSpikes);
    for i = 1:sum(blinkSpikes)
        blinkFrames{i}=sacc_starts(bsi(i)):sacc_ends(bsi(i));
    end
    
%     plot(xPos,yPos,'b.','markersize',1)
%     hold on
    
    % now store the information about each saccade
    Saccades=[];
    s_num=1;
    for sc = 1:length(sacc_starts)
        if ismember(sc,bsi)
            continue
        end
        
        Saccades(s_num).trial=trial_num;
        Saccades(s_num).sacc_num=s_num;
        Saccades(s_num).t_start_sacc = eyeTime(sacc_starts(sc));
        Saccades(s_num).t_end_sacc = eyeTime(sacc_ends(sc));
        Saccades(s_num).t_peak_vel = eyeTime(time_pTV(sc) + sacc_starts(sc));
        Saccades(s_num).peak_vel = peakTV(sc);
        Saccades(s_num).x_sacc_start = xPos(sacc_starts(sc));
        Saccades(s_num).x_sacc_end = xPos(sacc_ends(sc));
        Saccades(s_num).y_sacc_start = yPos(sacc_starts(sc));
        Saccades(s_num).y_sacc_end = yPos(sacc_ends(sc));
        
        if sc==1
            Saccades(s_num).t_start_prev_fix = eyeTime(1);
            Saccades(s_num).meanX_prev_fix = nanmean(xPos(1:sacc_starts(1)));
            Saccades(s_num).meanY_prev_fix = nanmean(yPos(1:sacc_starts(1)));
            Saccades(s_num).t_start_next_fix = eyeTime(sacc_ends(sc));
            Saccades(s_num).meanX_next_fix = nanmean(xPos(sacc_ends(1):sacc_starts(2)));
            Saccades(s_num).meanY_next_fix = nanmean(yPos(sacc_ends(1):sacc_starts(2)));
        elseif sc==length(sacc_starts)
            Saccades(s_num).t_start_prev_fix = eyeTime(sacc_ends(sc-1));
            Saccades(s_num).meanX_prev_fix = nanmean(xPos(sacc_ends(sc-1):sacc_starts(sc)));
            Saccades(s_num).meanY_prev_fix = nanmean(yPos(sacc_ends(sc-1):sacc_starts(sc)));
            Saccades(s_num).t_start_next_fix = eyeTime(sacc_ends(sc));
            Saccades(s_num).meanX_next_fix = nanmean(xPos(sacc_ends(sc):length(tv)));
            Saccades(s_num).meanY_next_fix = nanmean(yPos(sacc_ends(sc):length(tv)));
            
%             plot(Saccades(s_num).meanX_next_fix,Saccades(s_num).meanY_next_fix,'go')
            
        else
            Saccades(s_num).t_start_prev_fix = eyeTime(sacc_ends(sc-1));
            Saccades(s_num).meanX_prev_fix = nanmean(xPos(sacc_ends(sc-1):sacc_starts(sc)));
            Saccades(s_num).meanY_prev_fix = nanmean(yPos(sacc_ends(sc-1):sacc_starts(sc)));
            Saccades(s_num).t_start_next_fix = eyeTime(sacc_ends(sc));
            Saccades(s_num).meanX_next_fix = nanmean(xPos(sacc_ends(sc):sacc_starts(sc+1)));
            Saccades(s_num).meanY_next_fix = nanmean(yPos(sacc_ends(sc):sacc_starts(sc+1)));
        end
        
%         plot(Saccades(s_num).meanX_prev_fix,Saccades(s_num).meanY_prev_fix,'mo')

        sac_ctr=sac_ctr+1;
        s_num=s_num+1;
    end
    Trials(trial_num).Saccades = Saccades;
        
%     ginput();
%     hold off
    
%  plot(tv); hold on   
%  plot([sacc_starts';sacc_ends'],repmat(-20,2,length(sacc_starts)),'k-','linewidth',2)   

%     figure
%     plot(tv)
%     hold all
%     plot(find(tv>(muLow+stdLow*2)),tv(tv>(muLow+stdLow*2)),'gx')
%     plot(find(tv<(muLow+stdLow*2)),tv(tv<(muLow+stdLow*2)),'rx')

end
    
disp(['There were ' num2str(sac_ctr) ' saccades detected in ' num2str(tri_ctr) ' trials.'])





