% batch_makeTrialPlx2.m

% Extracts data from plexon and makes the struct 'Trials'

% this script reads all the spike timestamp and a/d info from a plx file into matlab
% variables.


%% User inputs

save_file = 0;

% Channels 
regtemp = regexp(plex_fname,'_c\d+')+3;
trode=str2double(plex_fname(regtemp:regtemp+1));

% Parameters
startcode = 1001; % normally 1001; 800 is when window opens
endcode = 4079; % normally 1014; 801 is when window closes
a2drate = 1000; % 1000 is the default
time_multiplier = 1000; % 1000 for times in ms, 1 for times in sec
downsample_factor = 20;

%% Open plexon spikes file and get initial info
[OpenedFileName, Version, Freq, Comment, Trodalness, NPW, PreThresh, SpikePeakV, ...
    SpikeADResBits, SlowPeakV, SlowADResBits, Duration, DateTime] = plx_information([plex_fpath '\' plex_fname]);

%% Get timestamps for units
% Read in the timestamps of all units,channels into a two-dimenionsal cell
% array named allts, with each cell containing the timestamps for a unit,channel.
% Note that allts second dim is indexed by the 1-based channel number.
% The indexing here is insanely stupid. plex_ts uses 1-based channel
% numbering instead of 0-based (unlike plx_info)

tscounts = plx_info(OpenedFileName,1);

% tscounts, wfcounts are indexed by (unit+1,channel+1)
% tscounts(:,ch+1) is the per-unit counts for channel ch
% sum( tscounts(:,ch+1) ) is the total wfs for channel ch (all units)
% gives actual number of units (including unsorted) and actual number of
% channels plus 1

[nunits1, nchannels1] = size( tscounts ); 
allts=[];

for iunit = 0:nunits1-1   % starting with unit 0 (unsorted) 
    for ich = 1:nchannels1-1 % starts with channel 1; tscounts goes to 33 not 32, so this line subtracts 1. who knows
        if ( tscounts( iunit+1 , ich+1 ) > 0 )
            
            % Get the timestamps for this channel and unit 
            [nts, allts{iunit+1,ich}] = plx_ts(OpenedFileName, ich , iunit );
            
         end
    end
end
           
% Get some other info about the spike channels
[nspk,spk_filters] = plx_chan_filters(OpenedFileName);
[nspk,spk_gains] = plx_chan_gains(OpenedFileName);
[nspk,spk_threshs] = plx_chan_thresholds(OpenedFileName);
[nspk,spk_names] = plx_chan_names(OpenedFileName);



%% Construct Trials struct

% Find trials that were started and finished
start_trials = find(Strobed(:,2) == startcode);
end_trials   = find(Strobed(:,2) == endcode);

% make sure there is no mismatch of trials
% you want to make sure that:
% 1) These vectors are the same length
% 2) All of the start_trials indices are smaller than their end_trials
% counterparts.
% 3) All of the start_trials indices are bigger than the previous end_trials index. 
while 1
    
    if length(start_trials)<length(end_trials)
        if start_trials(1)>end_trials(1)
            end_trials(1)=[];
        else
            end_trials(end)=[];
        end
    end
    
    if length(start_trials)>length(end_trials)
        if start_trials(end)>end_trials(end)
            start_trials(end)=[];
        else
            start_trials(1)=[];
        end
    end
    
    ie = isequal(length(start_trials),length(end_trials));
    lt = all((start_trials<end_trials)==1);
    gt = all((start_trials(2:end)>end_trials(1:end-1))==1);
    
    if ie && lt && gt
        break
    end
end

if isempty(start_trials)
    errordlg ('There are no trials in this file!');
    return;
end

% Create struct
Trials=struct('trialNumber',[],'StartTime',[],'EndTime',[] ...
        ,'absolute_StartTime',[],'absolute_EndTime',[]...
        ,'a2dRate',[],'Signals',[],'Electrodes',[], 'LFPs',[]...
        ,'Events',[],'PLEX_Events',[],'Saccades',[]);
    
% Loop through trials and fill in struct
% I am dropping the first and last trials on the assumption that they may not be complete
for xx = 1:(length(start_trials)-2)
    
    % Write trial number
    Trials(xx).trialNumber = xx;
    
    % Write all events to struct
    Trials(xx).all_events = Strobed;
    Trials(xx).all_events(:,1) = Trials(xx).all_events(:,1)*time_multiplier;
    
    % Start and end times according to ecodes (NOT a/d collection)
    % This is kind of tricky b/c the a/d collection starts before the trial
    % start ecode (usually 1001) is sent, so there's some a/d data flanking
    % the trial
    
    tr_st_e = Strobed(start_trials(xx+1),1); % Trial start according to ecode
    tr_end_e = Strobed(end_trials(xx+1),1); % Trial end according to ecode

    StartTime = round(tr_st_e*time_multiplier); % Absolute time of the a/d data start
    EndTime =  round(tr_end_e*time_multiplier); % Absolute end time of the a/d data end old
    
    Trials(xx).StartTime = 0; % Trial start time?
    Trials(xx).EndTime = EndTime - StartTime; % Trial length
    
    Trials(xx).absolute_StartTime = StartTime;
    Trials(xx).absolute_EndTime = EndTime;
    
    Trials(xx).a2dRate = a2drate; % is this right? Should it be adfreq?

    % Insert the events
    num_events = end_trials(xx+1) - end_trials(xx);
    
    for yy = 1:num_events
        Trials(xx).PLEX_Events(yy).Code = Strobed(end_trials(xx)+yy,2);
        Trials(xx).PLEX_Events(yy).Time = round((Strobed(end_trials(xx)+yy,1).*time_multiplier) - tr_st_e*time_multiplier); % This is relative time. Is the same as abov
    end
    
    % Insert the units
    if exist('allts','var')
        for electrode = 1:size(allts,2)

            if electrode > 0 && electrode < 17
                ch=2*electrode-1;
            else
                ch = 2*(electrode - 16);
            end
            Trials(xx).Electrodes(ch).Name = spk_names(electrode,:);

            for unit = 1:size(allts,1)
                if ~isempty(allts{unit,electrode}) % If there's data for this unit
                    % Find spikes in the correct time window
                    trial_spk_ind = find((allts{unit,electrode}*time_multiplier >= Trials(xx).absolute_StartTime).*(allts{unit,electrode}*time_multiplier <= Trials(xx).absolute_EndTime));   % Finds spikes after StartTime and before EndTime
                    
                    % Insert spikes and names
                    if unit == 1
                        Trials(xx).Electrodes(ch).Units(unit).Code = [spk_names(electrode,:) '_Unsorted'];
                    else
                        Trials(xx).Electrodes(ch).Units(unit).Code = [spk_names(electrode,:) '_Unit' num2str(unit-1)];
                    end
                    Trials(xx).Electrodes(ch).Units(unit).Times = allts{unit,electrode}(trial_spk_ind)*time_multiplier - Trials(xx).absolute_StartTime; % This is relative time. This second term shouldn't matter, should be 0                  
                  
                end
            end
            
        end
    end
    
end

