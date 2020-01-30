function trial = read_pl2(fname)

t_multiplier = 1000;


%% to get basic info about the file
pl2 = PL2ReadFileIndex(fname);
% Now get a count of all the units in each channel
for i = 1:length(pl2.SpikeChannels)
%     unit_counts(i) = find(pl2.SpikeChannels{i}.UnitCounts, 1, 'last' );
    unit_counts(i) = pl2.SpikeChannels{i}.NumberOfUnits;
end


%% to get all events and their timestamps
event = internalPL2EventTs(fname, 'Strobed');
% event = internalPL2EventTs(fname, 41);
% Here, we are passing channel 41, which is the strobed channel. To verify
% this, use PL2Print(pl2.EventChannels) and check which cell# (first
% column) corresponds to the Strobed source.


%% To get eye position from Plexon file
% We are currently passing the eye position into PLEXON analog inputs 1 and 2 (AI01 and
% AI02). To see which channel these correspond to, run
% PL2Print(pl2.AnalogChannels). This shows that the cell# (i.e., channel)
% is 97 for AI01 and 98 for AI02. 
% To extract these, use PL2Ad.m
% eye_x_raw = PL2Ad(fname, 98);
% eye_y_raw = PL2Ad(fname, 99);
eye_x_raw = PL2Ad(fname, 'AI01');
eye_y_raw = PL2Ad(fname, 'AI02');

% We also need the timestamp of each eye position sample.



%% Build trial struct

% set up a few useful variables
ADFreq = eye_x_raw.ADFreq;
tstep = 1/ADFreq;
st_idx = 1;

disp(length(eye_x_raw.FragTs))

for i = 1:length(eye_x_raw.FragTs)
    FTs = eye_x_raw.FragTs(i);
    FC = eye_x_raw.FragCounts(i);
    
    % divide eye traces into fragments (trials)
    % first, get the timestamp of the eye position sample
    trial(i).eye.time = t_multiplier .* (FTs:tstep:(FC / ADFreq + FTs - tstep));
    % then save the eye position 
    trial(i).eye.x = eye_x_raw.Values(st_idx:(st_idx + FC - 1));
    trial(i).eye.y = eye_y_raw.Values(st_idx:(st_idx + FC - 1));
    st_idx = st_idx + FC;
    
    % get time span of current fragment (i.e., trial)
    tspan = [trial(i).eye.time(1) trial(i).eye.time(end)];
    
    % divide events into fragments
    t_idx = (t_multiplier .* event.Ts)>=tspan(1) & (t_multiplier .* event.Ts)<=tspan(2);
    trial(i).events.code = event.Strobed(t_idx);
    trial(i).events.time = t_multiplier .* event.Ts(t_idx);
    
    % divide neural data into fragments
    for ii = 1:length(pl2.SpikeChannels)
        ii
        num_u = pl2.SpikeChannels{ii}.NumberOfUnits;
        for u=1:num_u
            waves = PL2Waves( fname, ii, u );
            sp_idx = waves.Ts>=tspan(1) & waves.Ts<=tspan(2);
            trial(i).chan(ii).unit(u).times = t_multiplier .* waves.Ts(sp_idx);
            trial(i).chan(ii).unit(u).waves = waves.Waves(sp_idx,:);
        end
    end
end


