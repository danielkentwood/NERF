function out = probeRF_preview(Trials,params)

if ispc
    opengl software % use openGL software rather than hardware (since you are using alpha transparency and this isn't compatible with openGL hardware currently)
end

% temporal params
dt = params.dt;
x_at_peak = params.x_at_peak;
win_size = params.win_size;
time_before = x_at_peak-round(win_size/2);
time_after = x_at_peak+round(win_size/2);
sacc_cutoff = -50; % This will split the plotting into two groups, pre-remapping and
% post-remapping.

% spatial params
xwidth=params.xwidth;
ywidth=params.ywidth;
xvec = -xwidth:xwidth;
yvec = -ywidth:ywidth;

% get electrode
electrode = find(~cellfun(@isempty,{Trials(1).Electrodes.Units}));
unit = 1;

trialvec = 1:length(Trials);
for ps = 1:2
    ind = 1;
    rallx = [];
    rally = [];
    firing_rate = [];
    
    
    for trial = 1:length(trialvec)
        curtrial=trialvec(trial);
        
        % get probe times
        p_times = Trials(curtrial).probeXY_time(:,3);
        
        
        % sort out which probes you want to plot.
        fix_onsets = [Trials(curtrial).Saccades.t_start_prev_fix];
        sacc_onsets = [Trials(curtrial).Saccades.t_start_sacc];
        bad_probes = [];
        nextX=zeros(1,length(p_times));nextY=zeros(1,length(p_times));
        for cp = 1:length(p_times)
            % find the fixation after which it happened
            fix_diffs = p_times(cp)-fix_onsets;
            sacc_diffs = p_times(cp)-sacc_onsets;
            lastfixIDX = find(fix_diffs>0, 1, 'last' );
            if isempty(lastfixIDX)
                lastfixIDX=1;
            end
            
            % did probe start during the saccade?
            pre_sacc = sacc_diffs(lastfixIDX);
            
            % 2 = remapped PSTH (i.e., probes between the cutoff and the movement onset)
            if ps==2
                if pre_sacc>0 || pre_sacc<sacc_cutoff
                    bad_probes = [bad_probes cp];
                    continue
                end
            else %1 = original PSTH (i.e., probes between fixation onset and the cutoff)
                if pre_sacc>0 || pre_sacc>sacc_cutoff
                    bad_probes = [bad_probes cp];
                    continue
                end
            end
            nextX(cp)=Trials(curtrial).Saccades.meanX_next_fix;
            nextY(cp)=Trials(curtrial).Saccades.meanY_next_fix;
        end
        p_times(bad_probes)=[];
        nextX(bad_probes)=[];
        nextY(bad_probes)=[];
        
        
        for probeID = 1:length(p_times)
            % get p_time
            p_time = p_times(probeID);
            % get probe xy
            px1 = Trials(curtrial).probeXY_time(probeID,1);
            py1 = Trials(curtrial).probeXY_time(probeID,2);
            
            % get eye position at probe time
            if ps
                xy_idx = find(Trials(curtrial).Signals(1).Time==p_time);
                curx = Trials(curtrial).Signals(1).Signal(xy_idx);
                cury = Trials(curtrial).Signals(2).Signal(xy_idx);
            else
                curx = nextX(e);
                cury = nextY(e);
            end
            
            % center it at [0, 0]
            rallx(ind) = ceil(px1-curx);
            rally(ind) = ceil(py1-cury);
            
            % get saccade onset time
            start_time = p_time + time_before;
            end_time = p_time + time_after;
            
            % get firing rates
            temp = {[Trials(curtrial).Electrodes(electrode).Units(unit).Times] - double(start_time)};
            firing_rate(ind) = mean(full(getSpkMat(temp,dt,end_time-start_time,0)))*1000/dt;
            
            ind = ind + 1;
        end
    end
    plot_params.fig_Handle  = figure(30);
    plot_params.xwidth      = xwidth;
    plot_params.ywidth      = ywidth;
    plot_params.filtsize    = [10 10];
    plot_params.filtsigma   = 2;
    
    plot_params.axes_Handle = subplot('Position',[.5*(ps-1)+.05 .1 .4 .8]);
    [out, h] = plotRF(rallx, rally, firing_rate, plot_params);
end
set(gcf,'position',[284   503   973   413])



