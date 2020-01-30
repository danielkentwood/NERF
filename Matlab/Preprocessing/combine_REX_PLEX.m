% Combines Trial information from REX and PLEXON systems into a single file

% REX .mat contains a Trials struct with the following important info: 
% 1) Signals (H eye, V eye, H joystick, V joystick)
% 2) Events (ecodes, times in ms)

% PLEXON .mat contains a Trials struct with the following important info:
% 1) Signals (LFPs from each electrode)
% 2) Spike recordings (potentially multiple units per electrode); more
    % about this later since these might need to be offline sorted...
% 3) Events (incomplete list of ecodes, times in ms)

%% User inputs

verbose = 0; % 1 = True, 0 = False
open_manually = 0; % This script can also be called with the below files already open. In this case, don't prompt user to open them.
start_ecode = 1001;
end_ecode = 4079;
% end_ecode = 800;
reward_ecode = 4090;
misalignment_tolerance = 10; % Maximum alignment mismatch tolerable in ms

pre_buffer = 100;
post_buffer = 100;

%% Open files

if open_manually == 1 % This script can also be called with the below files already open. In this case, don't prompt user to open them.
    
    % Open .mat file generated from REX
    REX_filename = uigetfile('*.mat','Choose REX file');
    REX_Trials = importdata(REX_filename);
    
    % Open .mat file generated from PLEXON
    PLEX_filename = uigetfile('*.mat','Choose PLEXON file');
    Trials = importdata(PLEX_filename);
    
end

%% Ghettify Rex file for visual task

% For visual task, Plexon Trials struct is one shorter than it should be.
% To compensate, we trim REX_Trials by 1 (the first trial)
if length(REX_Trials) - length(Trials) < 2
    REX_Trials = REX_Trials(2:end);
    disp('Plexon Trials struct has too few trials; trimming Rex Trials struct to compensate')
end

%% Check to see which fields are in each file

% Eventually, include some error checking stuff here

%% Find temporal offset between two files
[REX_tr_length, PLEX_tr_length] = tr_lengths(Trials, REX_Trials);
% Check for misalignments
ms_idx = find(abs(PLEX_tr_length - REX_tr_length) > misalignment_tolerance | isnan(PLEX_tr_length - REX_tr_length));

% if there are more than 10 misaligned trials
if length(ms_idx)>10
    % try shifting up to two spots to see if this helps
    ptrl = PLEX_tr_length(ms_idx);
    time_shifts = [-2 -1 1 2];
    for shift_num = time_shifts
        rx_idx = ms_idx+shift_num;
        rx_idx_idx = rx_idx>length(REX_tr_length) | rx_idx<1;
        rx_idx(rx_idx_idx) = [];
        
        time_diff = nanmean(abs(ptrl(~rx_idx_idx) - REX_tr_length(rx_idx)));
        % if the shift reduced the time diff below tolerance
        if time_diff<misalignment_tolerance
            % Shift the REX trials
            REX_Trials(ms_idx(~rx_idx_idx)+1)=REX_Trials(rx_idx+1);
            % now recalculate the trial lengths
            [REX_tr_length, PLEX_tr_length] = tr_lengths(Trials, REX_Trials);
            % And check for misalignments
            ms_idx = find(abs(PLEX_tr_length - REX_tr_length) > misalignment_tolerance | isnan(PLEX_tr_length - REX_tr_length));
            break
        end
    end
end

% delete the trials that are misaligned and or NaNs
Trials(ms_idx)=[];
REX_Trials(ms_idx+1)=[];
[REX_tr_length, PLEX_tr_length, temporal_offset] = tr_lengths(Trials, REX_Trials);
PLEXREX_diff=double(PLEX_tr_length)-double(REX_tr_length);
disp(['Median temporal offset between REX and PLEXON = ' num2str(median(PLEXREX_diff)) ' ms'])

%% Combine fields into one file
% In particular, add REX information to PLEX file. Arbitrary. 
for trial = 1:length(Trials)
    
    % add session info
    if isfield(REX_Trials,'session')
        Trials(trial).Session.num = REX_Trials(trial+1).session.num;
        Trials(trial).Session.name= REX_Trials(trial+1).session.name;
    else
        Trials(trial).Session.num = 1;
        Trials(trial).Session.name = rex_fname(1:13);
    end
    
    % Add events
    for event = 1:length(REX_Trials(trial+1).Events)
        Trials(trial).Events(event).Code = REX_Trials(trial+1).Events(event).Code;
        Trials(trial).Events(event).Time = REX_Trials(trial+1).Events(event).Time ... % Event time in PLEXON time is equal to the event time in REX time
            + temporal_offset(trial);                                                % + how much behind PLEXON is compared to REX (due to transmission delay or wonky time)
              % I don't know why, but this temporal_offset is necessary. Removing it
              % breaks the code because something in the saccade_detector
              % code depends on it.
    end
    
    window_start_code = find([Trials(trial).PLEX_Events(:).Code]==start_ecode);
    
    if isempty(window_start_code)
        continue
    end
    
    window_start_time = Trials(trial).PLEX_Events(window_start_code).Time;
    diff1 = Trials(trial).Events(2).Time - Trials(trial).Events(1).Time; % what is this for? Usually ~1ms
    
    % Add eye movement and joystick signals
    % Sampling freq assumed to be 1kHz, maybe recode to account for
    % variable a2d freq or downsampling
    
    Trials(trial).Signals(1).Name = 'horiz_eye';
    Trials(trial).Signals(1).Signal = REX_Trials(trial+1).Signals(1).Signal;
    Trials(trial).Signals(1).Time = (1:length(REX_Trials(trial+1).Signals(1).Signal)) + double(window_start_time - pre_buffer + diff1); % Bc REX signals are in ms starting with 1;
    Trials(trial).Signals(2).Name = 'vert_eye';
    Trials(trial).Signals(2).Signal = REX_Trials(trial+1).Signals(2).Signal;
    Trials(trial).Signals(2).Time = (1:length(REX_Trials(trial+1).Signals(2).Signal)) + double(window_start_time - pre_buffer + diff1); % Bc REX signals are in ms starting with 1;
    Trials(trial).Signals(3).Name = 'horiz_joy';
    Trials(trial).Signals(3).Signal = REX_Trials(trial+1).Signals(3).Signal;
    Trials(trial).Signals(3).Time = (1:length(REX_Trials(trial+1).Signals(3).Signal)) + double(window_start_time - pre_buffer + diff1); % Bc REX signals are in ms starting with 1;
    Trials(trial).Signals(4).Name = 'vert_joy';
    Trials(trial).Signals(4).Signal = REX_Trials(trial+1).Signals(4).Signal;
    Trials(trial).Signals(4).Time = (1:length(REX_Trials(trial+1).Signals(4).Signal)) + double(window_start_time - pre_buffer + diff1); % Bc REX signals are in ms starting with 1;

    % Add reward
    if ~isempty(find([Trials(trial).Events(:).Code] == reward_ecode,1))
        Trials(trial).Reward = 1;
    else
        Trials(trial).Reward = 0;
    end
    
end
clear REX_Trials





function [REX_tr_length, PLEX_tr_length, temporal_offset] = tr_lengths(Trials, REX_Trials)

start_ecode = 1001;
end_ecode = 4079;

temporal_offset = nan(length(Trials),1);
PLEX_tr_length = nan(length(Trials),1);
REX_tr_length = nan(length(Trials),1);

% Find 1001 in REX and PLEX files
for trial = 1:length(Trials)
    % define rex and plex trial counters
    REX_trial = 1+trial; % Because the PLEX file always starts with REX trial 2; first and last REX trials are discarded
    PLEX_trial = trial;

    % REX
    if ~isempty(find([REX_Trials(REX_trial).Events(:).Code] == start_ecode, 1))
        REX_start_ind = find([REX_Trials(REX_trial).Events(:).Code] == start_ecode);
        REX_end_ind_temp = find([REX_Trials(REX_trial).Events(:).Code] == end_ecode);
        REX_end_ind = REX_end_ind_temp(REX_end_ind_temp > REX_start_ind);
        REX_end_ind = REX_end_ind(end);
        REX_tr_length(trial) = REX_Trials(REX_trial).Events(REX_end_ind).Time - REX_Trials(REX_trial).Events(REX_start_ind).Time;
    end
    % PLEXON
    if ~isempty(find([Trials(PLEX_trial).PLEX_Events(:).Code] == start_ecode, 1))
        PLEX_start_ind = find([Trials(PLEX_trial).PLEX_Events(:).Code] == start_ecode);
        PLEX_end_ind = find([Trials(PLEX_trial).PLEX_Events(:).Code] == end_ecode);
        PLEX_tr_length(trial) = Trials(PLEX_trial).PLEX_Events(PLEX_end_ind).Time - Trials(PLEX_trial).PLEX_Events(PLEX_start_ind).Time;
    end
    
     temporal_offset(trial) = Trials(PLEX_trial).PLEX_Events(PLEX_start_ind).Time - REX_Trials(REX_trial).Events(REX_start_ind).Time;
end
end



% misaligned=[];
% missing_plex_start=[];
% for trial = 1:length(Trials)
%     % define rex and plex trial counters
%     REX_trial = 1+trial; % Because the PLEX file always starts with REX trial 2; first and last REX trials are discarded 
%     PLEX_trial = trial; 
%     % find start ecodes
%     PLEX_start_ind = find([Trials(PLEX_trial).PLEX_Events(:).Code] == start_ecode);
%     REX_start_ind = find([REX_Trials(REX_trial).Events(:).Code] == start_ecode);
%     % find end ecodes
%     PLEX_end_ind = find([Trials(PLEX_trial).PLEX_Events(:).Code] == end_ecode);
%     REX_end_ind_temp = find([REX_Trials(REX_trial).Events(:).Code] == end_ecode);
%     REX_end_ind = REX_end_ind_temp(REX_end_ind_temp > REX_start_ind);
%     REX_end_ind = REX_end_ind(end);
%     
%     % check to see if the plex start ecode is missing (this is a common
%     % problem)
%     if isempty(PLEX_start_ind) 
%         missing_plex_start(end+1)=trial;
%         % check if the current REX trial length matches the next PLEXON
%         % trial length.
%         REX_tl = REX_Trials(REX_trial).Events(REX_end_ind).Time - REX_Trials(REX_trial).Events(REX_start_ind).Time;
%         PLEX_start_ind = find([Trials(PLEX_trial+1).PLEX_Events(:).Code] == start_ecode);
%         PLEX_end_ind = find([Trials(PLEX_trial+1).PLEX_Events(:).Code] == end_ecode);
%         PLEX_tl = Trials(PLEX_trial+1).PLEX_Events(PLEX_end_ind).Time - Trials(PLEX_trial+1).PLEX_Events(PLEX_start_ind).Time; 
%         if ~(abs(PLEX_tl - REX_tl) > misalignment_tolerance)
%             % if so, shift the REX trial down
%             RX_l = length(REX_Trials);
%             REX_Trials(REX_trial+1:RX_l+1) = REX_Trials(REX_trial:RX_l);
%         end
%         continue
%     end
%     
%     % Compare the length of the rex and the plex trial. Ideally, these two are the same
%     temporal_offset1(trial) = Trials(PLEX_trial).PLEX_Events(PLEX_start_ind).Time - REX_Trials(REX_trial).Events(REX_start_ind).Time; % Offset between start ecodes. SEE THIS LINE. MIGHT BE AN ISSUE
%     temporal_offset2(trial) = Trials(PLEX_trial).PLEX_Events(PLEX_end_ind).Time - REX_Trials(REX_trial).Events(REX_end_ind).Time; % Offset between end ecodes
%     PLEX_tr_length(trial) = Trials(PLEX_trial).PLEX_Events(PLEX_end_ind).Time - Trials(PLEX_trial).PLEX_Events(PLEX_start_ind).Time; % Length of PLEX trial from start to end code
%     REX_tr_length(trial) = REX_Trials(REX_trial).Events(REX_end_ind).Time - REX_Trials(REX_trial).Events(REX_start_ind).Time; % "" REX trial ""
%     
%     % print out a warning if there is a misalignment
%     if abs(PLEX_tr_length(trial) - REX_tr_length(trial)) > misalignment_tolerance
%         disp(['Warning: Trial ' num2str(trial) ' experienced misalignment'])
%         disp(['Length of PLEX trial: ' num2str(PLEX_tr_length(trial)) ' ms'])
%         disp(['Length of REX trial: ' num2str(REX_tr_length(trial)) ' ms'])
%         misaligned(end+1)=trial;
%     elseif verbose == 1
%         disp(['Trial ' num2str(trial) ' aligned properly.'])
%     end
% end
% 
% % MISALIGNMENT HANDLING
% % if there are misaligned trials, check to see how many there are. If there
% % are less than 10 consecutive trials misaligned, just delete them.
% if length(misaligned)<10
%    Trials(misaligned)=[];
%    REX_Trials(misaligned+1)=[];
% else
%     % if more, then what?
% end

