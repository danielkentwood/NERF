function PSTH = PProbeTH(Trials,electrode,time_params,varargin)


% use default time params if left empty
if isempty(time_params)
    time_params.lock_event='saccade'; % which event are we time-locking to? 'saccade' or 'fixation'
    time_params.start_time=-200; % start time of the PSTH
    time_params.end_time=500; % end time of the PSTH
    time_params.dt=5; % temporal resolution of the PSTH
    time_params.probe_window=[-25 0]; % bounds of probe selection time window (wrt to lock event)
end

%% varargin default values (varargin is a struct with the following possible fields)
axesDims    = [.15 .15 .7 .7]; % [left bottom width height]
plotLoc     = [0 0 1 1];
figHand     = NaN;
figTitle    = '';
plotflag    = 1;
RF_xy       = NaN;
RF_size     = 10;
remapped    = 0;
saccSelect  = 'RF'; % Options: 'inRF','outRF','all'
probeSelect = 'RF'; % how to select the probes. Options: 'RF','Radial'


Pfields = {'axesDims','plotLoc','figHand','figTitle','plotflag','RF_xy',...
    'RF_size','remapped','saccSelect','probeSelect'};
for i = 1:length(Pfields) % if a params structure was provided as an input, change the requested fields
    if ~isempty(varargin)&&isfield(varargin{1}, Pfields{i}), eval(sprintf('%s = varargin{1}.(Pfields{%d});', Pfields{i}, i)); end
end
if ~isempty(varargin)  % if there is a params input
    fnames = fieldnames(varargin{1}); % cycle through field names and make sure all are recognized
    for i = 1:length(fnames)
        recognized = max(strcmp(fnames{i},Pfields));
        if recognized == 0, fprintf('fieldname %s not recognized\n',fnames{i}); end
    end
end

%% start loop

% rename a few temporal parameters
time_range = [time_params.start_time time_params.end_time];
time_before = -time_params.start_time;
time_after = time_params.end_time;
p_win = time_params.probe_window;

if length(Trials(1).Electrodes(electrode).Units)==1
    unitvec=1:1;
    unitsub=0;
else
    unitvec=2:length(Trials(1).Electrodes(electrode).Units);
    unitsub=1;
end

for unit = unitvec % first unit is unsorted spikes
    pctr=0;
    
    tic
    for trial = 1:length(Trials)

        codes = [Trials(trial).Events(:).Code];
        times = [Trials(trial).Events.Time];
        p_times = Trials(trial).probeXY_time(:,3);
        px = Trials(trial).probeXY_time(:,1);
        py = Trials(trial).probeXY_time(:,2);
        
        % temporal selection of probes
        fix_onsets = [Trials(trial).Saccades.t_start_prev_fix];
        sacc_onsets = [Trials(trial).Saccades.t_start_sacc];
        
        for cp = 1:length(p_times)
            fix_diffs = p_times(cp)-fix_onsets;
            sacc_diffs = p_times(cp)-sacc_onsets;

            % identify which saccade we're locking to
            keepflag=0;
            p_x=[];p_y=[];
            if strcmp(time_params.lock_event,'saccade')
                lock_idx = find(sacc_diffs>=p_win(1) & sacc_diffs<=p_win(2));
            elseif strcmp(time_params.lock_event,'fixation')
                lock_idx = find(fix_diffs>=p_win(1) & fix_diffs<=p_win(2));
                lock_idx = min(lock_idx);
            end

            % lock to the fixation or the saccade
            if ~isempty(lock_idx)
                keepflag=1;  

                % define future and previous fixation locations
                s_x = Trials(trial).Saccades(lock_idx).meanX_next_fix;
                s_y = Trials(trial).Saccades(lock_idx).meanY_next_fix;
                f_x = Trials(trial).Saccades(lock_idx).meanX_prev_fix;
                f_y = Trials(trial).Saccades(lock_idx).meanY_prev_fix;

                sacc_x = s_x - f_x;
                sacc_y = s_y - f_y;
                xd = RF_xy(1)-sacc_x;
                yd = RF_xy(2)-sacc_y;
                sdiff = sqrt(xd^2 + yd^2);
                sacc_angle = atan2d(yd,xd);
                sacc_angle(sacc_angle<0)=sacc_angle(sacc_angle<0)+360;
                sacc_angle=round(sacc_angle);
                
                % get probe location vectors
                if remapped
                    % CENTER ON FUTURE FIXATION POSITION
                    p_x = px(cp)-s_x;
                    p_y = py(cp)-s_y;
                else
                    % CENTER ON CURRENT FIXATION POSITION
                    p_x = px(cp)-f_x;
                    p_y = py(cp)-f_y;
                end
            end

            if keepflag
                pctr=pctr+1;
                % Spatial criterion
                % If method is 'RF', throw out probes that don't qualify
                if strcmp(probeSelect,'RF')
                    
                    if strcmp(saccSelect,'all') ||...
                            (sdiff<=RF_size && strcmp(saccSelect,'inRF'))...
                            || (sdiff>RF_size && strcmp(saccSelect,'outRF'))
                        RFpx=p_x-RF_xy(1);
                        RFpy=p_y-RF_xy(2);
                        RFp_dist = sqrt(RFpx^2 + RFpy^2);
                        if RFp_dist>RF_size
                            pctr=pctr-1;
                            continue
                        end
                    else
                        pctr=pctr-1;
                        continue
                    end
                    
                    % if method is 'Radial', just get the vector angles so you can bin
                    % them and break into arbitrary radial bins later on.
                elseif strcmp(probeSelect,'Radial')
                    RF_angle = atan2d(RF_xy(2),RF_xy(1));
                    RF_angle(RF_angle<0)=RF_angle(RF_angle<0)+360;
                    RF_angle = round(RF_angle);
                    
                    bin_bounds = round(RF_angle-RF_size/2):round(RF_angle+RF_size/2);
                    bin_bounds(bin_bounds<0)=bin_bounds(bin_bounds<0)+360;
                    
                    if strcmp(saccSelect,'all') ||...
                            (any(ismember(sacc_angle,bin_bounds)) && strcmp(saccSelect,'inRF'))...
                            || (~any(ismember(sacc_angle,bin_bounds)) && strcmp(saccSelect,'outRF'))
                        
                        probe_angle = atan2d(p_y,p_x);
                        probe_angle(probe_angle<0)=probe_angle(probe_angle<0)+360;
                        probe_angle = round(probe_angle);
                        
                        if ~any(ismember(probe_angle,bin_bounds))
                            pctr=pctr-1;
                            continue
                        end
                    else
                        pctr=pctr-1;
                        continue
                    end
                else
                    error('The probeSelect variable must be ''RF'' or ''Radial''.')
                end
                
                % get neural data
                vis_temp = {[Trials(trial).Electrodes(electrode).Units(unit).Times] - p_times(cp)};
                data_cells{pctr}=vis_temp{1}';
            end
        end
    end
    toc
    
    % set temporal parameters for nda_PSTH
    time_params(1).zero_time=0;
    time_params(1).start_time=-time_before;
    time_params(1).end_time=time_after;
    time_params(1).dt=5;
    
    % set other parameters for nda_PSTH
    other_params.errBars=0;
    other_params.useSEs=0;
    other_params.smoothflag=1;
    other_params.smoothtype='gauss';
    other_params.gauss_sigma = 10;
    other_params.plotLoc = [0.05 0 .43 1];
    other_params.plotflag = plotflag;
    
    all_spikes2{1} = data_cells;
    
    tic
    PSTH.unit(unit).data=nda_PSTH(all_spikes2,time_params,other_params);
    PSTH.bin_range = p_win; 
    PSTH.num_probes = length(data_cells);
    toc
    if plotflag
        title('Stimulus locked')
        set(gcf,'position',[206         415        1578         547])
        set(gcf,'Name',['unit ' num2str(unit-unitsub)],'NumberTitle','off')
    end
end





