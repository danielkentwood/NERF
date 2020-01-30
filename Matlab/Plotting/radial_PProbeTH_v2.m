% Reference probe location to eye position at a fixed latency after the
% onset of the probe.

function PSTH = radial_PProbeTH_v2(Trials)

if ispc
    opengl software % use openGL software rather than hardware (since you are using alpha transparency and this isn't compatible with openGL hardware currently)
end

% Get channel
electrode = find(~cellfun(@isempty,{Trials(1).Electrodes.Units}));
% Unit
unit = 1;


% temporal parameters
dt = 5;
pad = 50;
time_before = 500+pad;
time_after = 500+pad;

trialvec = 1:length(Trials);

ind = 1;
for trial = 1:length(trialvec)
    curtrial=trialvec(trial);
    
    p_times = Trials(curtrial).probeXY_time(:,3);
    
    for e = 1:length(p_times)
        
        % get eye position at event time
        lag = 150;
        xy_idx = find(Trials(curtrial).Signals(1).Time==p_times(e) + lag);
        curx = Trials(curtrial).Signals(1).Signal(xy_idx);
        cury = Trials(curtrial).Signals(2).Signal(xy_idx);
        
        % get centered probe XY
        probe_x=Trials(curtrial).probeXY_time(e,1)-curx;
        probe_y=Trials(curtrial).probeXY_time(e,2)-cury;
        
        % get probe angle
        probe_angle = atan2d(probe_y,probe_x);
        probe_angle(probe_angle<0)=probe_angle(probe_angle<0)+360;
        data_struct(ind).angle = probe_angle;
        
        % probe onset
        t_probe_on = double(p_times(e));
        
        % get neural data
        vis_temp = {[Trials(curtrial).Electrodes(electrode).Units(unit).Times] - t_probe_on};
        data_cells{ind}=vis_temp{1}';
        ind = ind + 1;
    end
end


% bin by angle
numbins=8;
bin_edges=linspace(0,360,numbins+1);
[n_ang,bin_edges,ang_bins]=histcounts([data_struct.angle],bin_edges);

time_params(1).zero_time=0;
time_params(1).start_time=-time_before;
time_params(1).end_time=time_after;
time_params(1).dt=dt;
time_params(1).pad=pad;
time_params(2:numbins)=time_params(1);

other_params.errBars=1;
other_params.useSEs=1;
other_params.smoothflag=1;
other_params.gauss_sigma = 10;
other_params.legend_flag=0;

for tb = 1:numbins
    other_params.names{tb}=[num2str(bin_edges(tb)) '-' num2str(bin_edges(tb+1))];
    all_spikes2{tb}=data_cells(ang_bins==tb);
end

fh(unit)=figure(unit+100);

% single plot
set(fh(unit),'position',[495   219   810   764])
other_params.figHand=fh(unit);
other_params.plotLoc = [0 0 1 1];
[h_psth, PSTH] = PSTH_rast(all_spikes2,time_params,other_params);





