% plexCheck
% Quickly checks the plexon file (for comparison with the rex file)


%% Open file and get initial info
[OpenedFileName, Version, Freq, Comment, Trodalness, NPW, PreThresh, SpikePeakV, ...
    SpikeADResBits, SlowPeakV, SlowADResBits, Duration, DateTime] = plx_information([plex_fpath plex_fname]);

%% get LFPs (too see how many there are, since there is one for each trial)
if strcmp('2',OpenedFileName(end))
    ad = PL2Ad(OpenedFileName, 65); % plx channel 65 is the second FP (field potential) channel. We just need a random one to count trials.
    tsad = ad.FragTs;
else
    [adfreq, nad, tsad, fnad, allad] = plx_ad(OpenedFileName, 17);
end

%% get events and their timestamps
[nevs, tsevs, svStrobed] = plx_event_ts(OpenedFileName, 257);

%% get starts and stops as defined by event codes
startcode = 1001; % normally 1001; 800 is when window opens
endcode = 4079; % normally 1014; 801 is when window closes
start_trials = find(svStrobed == startcode);
end_trials   = find(svStrobed == endcode);

