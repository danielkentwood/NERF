function PSTH = radial_PProbeTH(Trials, plot_type)

if ispc
    opengl software % use openGL software rather than hardware (since you are using alpha transparency and this isn't compatible with openGL hardware currently)
end

switch nargin
    case 1
        plot_type='single';
    case 2
        if ~ismember(plot_type,{'single','subplots'})
            error('OOPS. The plot_type variable needs to be either ''single'' or ''subplots''')
        end
end

% Get channel
electrode = find(~cellfun(@isempty,{Trials(1).Electrodes.Units}));
% Unit
unit = 1;
plotflag=1;

% temporal parameters
dt = 5;
pad = 50;
time_before = 200+pad;
time_after = 300+pad;
sacc_cutoff = -150; % This will split the plotting into two groups, pre-remapping and
% post-remapping.

trialvec = 1:length(Trials);
for ps = 1:2
    ind = 1;
    for trial = 1:length(trialvec)
        curtrial=trialvec(trial);
        
        codes = [Trials(curtrial).Events(:).Code];
        times = [Trials(curtrial).Events.Time];
        
        tx = Trials(curtrial).Target.x;
        ty = Trials(curtrial).Target.y;
        
        p_times = Trials(curtrial).probeXY_time(:,3);
        
        % make sure the probe happened within a set window after
        % fixation
        fix_onsets = [Trials(curtrial).Saccades.t_start_prev_fix];
        sacc_onsets = [Trials(curtrial).Saccades.t_start_sacc];
        
        bad_probes = [];
        nextX=zeros(1,length(p_times));
        nextY=zeros(1,length(p_times));
        
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
        
        for e = 1:length(p_times)
            
            % get eye position at event time
            if ps
                xy_idx = find(Trials(curtrial).Signals(1).Time==p_times(e));
                curx = Trials(curtrial).Signals(1).Signal(xy_idx);
                cury = Trials(curtrial).Signals(2).Signal(xy_idx);
            else
                curx = nextX(e);
                cury = nextY(e);
            end
            
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
    if ps==1
        other_params.figTitle='Original PSTH';
    else
        other_params.figTitle='Remapped PSTH';
    end
    
    for tb = 1:numbins
        other_params.names{tb}=[num2str(bin_edges(tb)) '-' num2str(bin_edges(tb+1))];
        all_spikes2{tb}=data_cells(ang_bins==tb);
    end
    

        fh(unit)=figure(unit+101);
        switch plot_type
            case 'single'
                % single plot
                set(fh(unit),'position',[495   219   810   764])
                other_params.figHand=fh(unit);
                other_params.plotLoc = [0.05+.5*(ps-1) 0 .43 1];
                [h_psth(tb), PSTH(tb).bin] = PSTH_rast(all_spikes2,time_params,other_params);
            case 'subplots'
                % create subplots
                set(fh(unit),'Position',[41          69        1053         904])
                other_params.figHand=fh(unit);
                heights=1/2;
                widths=1/(numbins/2);
                binlefts=0:widths:(1-widths);
                lefts=repmat(binlefts,1,2);
                bottoms=[.5*ones(1,length(binlefts)) zeros(1,length(binlefts))];
                other_params.names = [];
                for tb = 1:numbins
                    all_spikes={data_cells(ang_bins==tb)};
                    other_params.plotLoc = [lefts(tb) bottoms(tb) widths heights];
                    other_params.figTitle = [num2str(bin_edges(tb)) '-' num2str(bin_edges(tb+1))];
                    PSTH(tb) = PSTH_rast(all_spikes,time_params,other_params);
                end
        end
end



