% simple probe analysis
Trials = saccade_detector(Trials);
Trials = cleanTrials(Trials);
%% separate trials into bins for target position
targ_dir=[];
for i = 1:length(Trials)
    xs = Trials(i).Target.x ./ abs(Trials(i).Target.x);
    if isnan(xs),xs=0;end
    ys = Trials(i).Target.y ./ abs(Trials(i).Target.y);
    if isnan(ys),ys=0;end
    ss = xs*4 + ys;
    
    switch ss
        case 1
            targ_dir(i) = 1; %up
        case -1
            targ_dir(i) = 2; %down
        case 4
            targ_dir(i) = 3; %right
        case -4
            targ_dir(i) = 4; %left
    end
end
directions = {'up','down','right','left'};

colors = ['r','m','b','c'];
%% now remove cases where the angle and amplitude do not meet the criteria

for i = 1:length(Trials)
    bad_saccs=[];
    for s = 1:length(Trials(i).Saccades)
        cursacc = Trials(i).Saccades(s);
        % get angle
        x1 = cursacc.x_sacc_start;
        x2 = cursacc.x_sacc_end;
        y1 = cursacc.y_sacc_start;
        y2 = cursacc.y_sacc_end;
        a = atan2d(y2-y1,x2-x1);
        if a<0, a=a+360; end
        % get amplitude
        amp = sqrt((x2-x1)^2 + (y2-y1)^2);
        
        % identify bad saccades
        if (targ_dir(i)==1 && (a>75 && a<105)) ||...
                (targ_dir(i)==2 && (a>255 && a<285)) ||...
                (targ_dir(i)==3 && a>345 || a<15) ||...
                (targ_dir(i)==4 && (a>165 && a<195))
            angFlag=0;
        else
            angFlag=1;
        end
        
        if amp>8 && amp<18
            ampFlag=0;
        else
            ampFlag=1;
        end
        if angFlag || ampFlag
            bad_saccs(end+1)=s;
        end
    end
    Trials(i).Saccades(bad_saccs)=[];
end


% %% Estimate remapping for each target direction, locked to saccade endpoint
% curTrode=find(~cellfun(@isempty,{Trials(1).Electrodes.Units}));
% 
% probe_preprocess;
% 
% for ii = 1:4
%     Trials_temp = [Trials(targ_dir==ii).trialNumber];
%     
%     probe_temp = probe(ismember(probe.trialNum, Trials_temp),:);
%     % Trials_temp = Trials;
%     %     for i = 1:length(Trials_temp), Trials_temp(i).Electrodes(setdiff(1:curTrode,curTrode))=[];end
%     %     probe_temp = makeProbeStruct2(Trials_temp);
%     
%     params.earliest    = -100;
%     params.latest      = 0;
%     params.windowsize  = 25;
%     params.wind_inc    = 25;
%     params.timeLock    = 'sac1start';
%     params.spaceLock   = 'fix1';
%     params.standard_caxis = 1;
%     params.xwidth      = 60;
%     params.ywidth      = 50;
%     out2 = probes_RF_estimate(probe_temp,1,params);
%     
%     set(gcf,'Position',[3 815-250*(ii-1) 1250 182],...
%         'Name',['Target ' directions{ii}],'NumberTitle','off')
% end


%% look at the passive RF
curUnit=1;
curTrode=find(~cellfun(@isempty,{Trials(1).Electrodes.Units}));
time_before_probe = 0;
time_after_probe = 300;
dt=5;
probeTrigTime = -time_before_probe:dt:time_after_probe;
sigma=10;
load RF_colormap

fr=[];
xy=[];
for i = 1:length(Trials)
    % find target onset time
    events = [Trials(i).Events.Code];
    time   = [Trials(i).Events.Time];
    eyex   = Trials(i).Signals(1).Signal;
    eyey   = Trials(i).Signals(2).Signal;
    eyet   = Trials(i).Signals(1).Time;
    
    tgt_on_times=time(events==4020);
    tgt_on_time=tgt_on_times(end);
    
    % find probe times that happen before the target onset
    pt = Trials(i).probeXY_time(:,3);
    preProbes = find(pt<tgt_on_time);
    
    % get firing rates for these probes
    probeFR=[];
    probeXY=[];
    for pp = 1:length(preProbes)
        cpT = pt(preProbes(pp));
        start_time = cpT-time_before_probe;
        end_time = cpT+time_after_probe;
        sTimes = Trials(i).Electrodes(curTrode).Units(curUnit).Times;
        probe_sTimes = sTimes(sTimes>start_time & sTimes<end_time)- double(cpT);
        probeTrigSpikes = buildSpikeTrain(probe_sTimes,0,-time_before_probe,time_after_probe,dt);
        probeTS = gauss_spTrConvolve(probeTrigSpikes,dt,sigma);
        probeFR(pp) = mean(probeTS(probeTrigTime>60 & probeTrigTime<100)).*(1000/dt);
        
        % now pull the x and y, minus the current eye position at the time
        % of the probe
        probeXY(pp,1) = Trials(i).probeXY_time(preProbes(pp),1)-eyex(eyet==cpT);
        probeXY(pp,2) = Trials(i).probeXY_time(preProbes(pp),2)-eyey(eyet==cpT);
    end
    
    fr = [fr;probeFR'];
    xy = [xy;probeXY];
end
params=[];
params.filtsize=[20 20];
params.filtsigma=2.5;
params.xwidth=40;
params.ywidth=30;
[~, h] = plotRF(xy(:,1),xy(:,2),fr,params);
colormap(h.axes, mycmap)
title('Passive RF')






%% look at remapping of RF at each target

curUnit=1;
curTrode=find(~cellfun(@isempty,{Trials(1).Electrodes.Units}));
time_before_probe = 0;
time_after_probe = 300;
dt=5;
probeTrigTime = -time_before_probe:dt:time_after_probe;
sigma=10;
load RF_colormap

remap_window_size = 50;
start_window = -150;
step_size = 5;
win_starts = start_window:step_size:-remap_window_size;

colors = ['r','m','b','c'];

figHandles = findobj('Type', 'figure');
fighandle = max([figHandles.Number])+1;



for tdir = 1:4
    fr=[];
    xy=[];
    trial_vec=[];
    sacc_vec=[];
    
    % initialize the optimal start window to [-1 0] where first item is the
    % index and second is the actual difference value
    optimal_window_start = [-1 0];
    optimal_xy = [];
    optimal_fr = [];
    
    for ind = 1:length(win_starts)
        remap_window = [win_starts(ind) (win_starts(ind)+remap_window_size)];
        % after it does all the analysis and before it plots, want to calculate
        % diff between max fr and avg fr
        % keep record of the max over all possible windows (save as index into
        % win_starts
        
        for i = 1:length(Trials)
            events = [Trials(i).Events.Code];
            time   = [Trials(i).Events.Time];
            eyex   = Trials(i).Signals(1).Signal;
            eyey   = Trials(i).Signals(2).Signal;
            eyet   = Trials(i).Signals(1).Time;
            
            
            if targ_dir(i)==tdir
                % find the saccade that lands on the target
                tx = Trials(i).Target.x;
                ty = Trials(i).Target.y;
                
                sacc_idx=[];
                for cursacc = 1:length(Trials(i).Saccades)
                    fx = Trials(i).Saccades(cursacc).x_sacc_start;
                    fy = Trials(i).Saccades(cursacc).y_sacc_start;
                    fix_dist = sqrt(fx^2 + fy^2);
                    
                    
                    sx = Trials(i).Saccades(cursacc).x_sacc_end;
                    sy = Trials(i).Saccades(cursacc).y_sacc_end;
                    sacc_dist = sqrt((tx-sx)^2 + (ty-sy)^2);
                    
                    %                 disp([num2str(fix_dist) ' ' num2str(sacc_dist)])
                    
                    if sacc_dist<4 && fix_dist<4
                        sacc_idx = cursacc;
                        break
                    end
                end
                
                if isempty(sacc_idx)
                    continue
                end
                
                % save saccade and trial
                trial_vec(end+1)=i;
                sacc_vec{end+1}=sacc_idx;
                
                % get timing of saccade to target
                sacc_onset = Trials(i).Saccades(sacc_idx).t_start_sacc;
                
                % find probe times that happen before saccade onset
                pt = Trials(i).probeXY_time(:,3) - sacc_onset;
                preProbes = find(pt<remap_window(2) & pt>remap_window(1));
                
                % get firing rates for these probes
                probeFR=[];
                probeXY=[];
                for pp = 1:length(preProbes)
                    cpT = pt(preProbes(pp));
                    
                    % create window for looking at probe-triggered spikes
                    start_time = cpT-time_before_probe;
                    end_time = cpT+time_after_probe;
                    % lock spike times to sacc onset
                    sTimes = Trials(i).Electrodes(curTrode).Units(curUnit).Times - sacc_onset;
                    % select spikes that are elicited by the probe
                    probe_sTimes = sTimes(sTimes>start_time & sTimes<end_time)- double(cpT);
                    % build a spike train out of these
                    probeTrigSpikes = buildSpikeTrain(probe_sTimes,0,-time_before_probe,time_after_probe,dt);
                    % smooth the spike train
                    probeTS = gauss_spTrConvolve(probeTrigSpikes,dt,sigma);
                    % calculate firing rate by taking the mean of the spike
                    % count within a window that corresponds to the peak
                    % response to the probe
                    probeFR(pp) = mean(probeTS(probeTrigTime>60 & probeTrigTime<100)).*(1000/dt);
                    
                    % now pull the x and y, minus the current eye position at the time
                    % of the probe
                    probeXY(pp,1) = Trials(i).probeXY_time(preProbes(pp),1);
                    probeXY(pp,2) = Trials(i).probeXY_time(preProbes(pp),2);
                end
                
                fr = [fr;probeFR'];
                xy = [xy;probeXY];
            end
            
            mean_fr = mean(fr);
            max_fr = max(fr);
            diff = max_fr/mean_fr;
            if max(optimal_window_start(2), diff) == diff
                optimal_window_start = [ind diff];
                optimal_xy = xy;
                optimal_fr = fr;
            end
        end
    end
    
    
    
    figure(200)
    plot_saccades(Trials, trial_vec, sacc_vec, colors(tdir));
    
    xy = optimal_xy;
    fr = optimal_fr;
    
    params=[];
    params.filtsize=[20 20];
    params.filtsigma=2.5;
    params.xwidth=40;
    params.ywidth=30;
    params.fig_Handle   = figure(fighandle);
    params.axes_Handle  = subplot(1,4,tdir);
    
    out = plotRF(xy(:,1),xy(:,2),fr,params);
    colormap(gca,mycmap)
    
    switch tdir
        case 1
            id = 'up';
        case 2
            id = 'down';
        case 3
            id = 'right';
        case 4
            id = 'left';
    end
    title(['Target ' id])
    
    
end

 set(gcf,'position',[4         633        1913         339])






% %% look at remapping of RF at each target
% 
% curUnit=1;
% curTrode=find(~cellfun(@isempty,{Trials(1).Electrodes.Units}));
% time_before_probe = 0;
% time_after_probe = 300;
% dt=5;
% probeTrigTime = -time_before_probe:dt:time_after_probe;
% sigma=10;
% load RF_colormap
% 
% remap_window = [-50 0];
% 
% colors = ['r','m','b','c'];
% 
% figHandles = findobj('Type', 'figure');
% fighandle = max([figHandles.Number])+1;
% 
% for tdir = 1:4
%     fr=[];
%     xy=[];
%     trial_vec=[];
%     sacc_vec=[];
%     
%     for i = 1:length(Trials)
%         events = [Trials(i).Events.Code];
%         time   = [Trials(i).Events.Time];
%         eyex   = Trials(i).Signals(1).Signal;
%         eyey   = Trials(i).Signals(2).Signal;
%         eyet   = Trials(i).Signals(1).Time;
%         
%         
%         
%         if targ_dir(i)==tdir
%             % find the saccade that lands on the target
%             tx = Trials(i).Target.x;
%             ty = Trials(i).Target.y;
%             
%             sacc_idx=[];
%             for cursacc = 1:length(Trials(i).Saccades)
%                 fx = Trials(i).Saccades(cursacc).x_sacc_start;
%                 fy = Trials(i).Saccades(cursacc).y_sacc_start;
%                 fix_dist = sqrt(fx^2 + fy^2);
%                 
%                 
%                 sx = Trials(i).Saccades(cursacc).x_sacc_end;
%                 sy = Trials(i).Saccades(cursacc).y_sacc_end;
%                 sacc_dist = sqrt((tx-sx)^2 + (ty-sy)^2);
%                 
% %                 disp([num2str(fix_dist) ' ' num2str(sacc_dist)])
%                 
%                 if sacc_dist<4 && fix_dist<4
%                     sacc_idx = cursacc;
%                     break
%                 end
%             end
%             
%             if isempty(sacc_idx)
%                 continue
%             end
%             
%             % save saccade and trial
%             trial_vec(end+1)=i;
%             sacc_vec{end+1}=sacc_idx;
%             
%             % get timing of saccade to target
%             sacc_onset = Trials(i).Saccades(sacc_idx).t_start_sacc;
%             
%             % find probe times that happen before saccade onset
%             pt = Trials(i).probeXY_time(:,3) - sacc_onset;
%             preProbes = find(pt<remap_window(2) & pt>remap_window(1));
%             
%             % get firing rates for these probes
%             probeFR=[];
%             probeXY=[];
%             for pp = 1:length(preProbes)
%                 cpT = pt(preProbes(pp));
%                 
%                 % create window for looking at probe-triggered spikes
%                 start_time = cpT-time_before_probe;
%                 end_time = cpT+time_after_probe;
%                 % lock spike times to sacc onset
%                 sTimes = Trials(i).Electrodes(curTrode).Units(curUnit).Times - sacc_onset;
%                 % select spikes that are elicited by the probe
%                 probe_sTimes = sTimes(sTimes>start_time & sTimes<end_time)- double(cpT);
%                 % build a spike train out of these
%                 probeTrigSpikes = buildSpikeTrain(probe_sTimes,0,-time_before_probe,time_after_probe,dt);
%                 % smooth the spike train
%                 probeTS = gauss_spTrConvolve(probeTrigSpikes,dt,sigma);
%                 % calculate firing rate by taking the mean of the spike
%                 % count within a window that corresponds to the peak
%                 % response to the probe
%                 probeFR(pp) = mean(probeTS(probeTrigTime>60 & probeTrigTime<100)).*(1000/dt);
%                 
%                 % now pull the x and y, minus the current eye position at the time
%                 % of the probe
%                 probeXY(pp,1) = Trials(i).probeXY_time(preProbes(pp),1);
%                 probeXY(pp,2) = Trials(i).probeXY_time(preProbes(pp),2);
%             end
%             
%             fr = [fr;probeFR'];
%             xy = [xy;probeXY];
%         end
%         
% 
%         
%     end
%     
%     figure(200)
%     plot_saccades(Trials, trial_vec, sacc_vec, colors(tdir));
%     
%     params=[];
%     params.filtsize=[20 20];
%     params.filtsigma=2.5;
%     params.xwidth=40;
%     params.ywidth=30;
%     params.fig_Handle   = figure(fighandle);
%     params.axes_Handle  = subplot(1,4,tdir);
%     
%     out = plotRF(xy(:,1),xy(:,2),fr,params);
%     colormap(gca,mycmap)
%     
%     switch tdir
%         case 1
%             id = 'up';
%         case 2
%             id = 'down';
%         case 3
%             id = 'right';
%         case 4
%             id = 'left';
%     end
%     title(['Target ' id])
% end
% set(gcf,'position',[4         633        1913         339])









%% make sure you're only looking at saccades that have the correct vector
% first take a look at all the vector angles and amplitudes
a=[]; amp=[]; targdir=[];
for i = 1:length(Trials)
    for s = 1:length(Trials(i).Saccades)
        cursacc = Trials(i).Saccades(s);
        % get angle
        x1 = cursacc.x_sacc_start;
        x2 = cursacc.x_sacc_end;
        y1 = cursacc.y_sacc_start;
        y2 = cursacc.y_sacc_end;
        a(end+1) = atan2d(y2-y1,x2-x1);
        
        % get amplitude
        amp(end+1) = sqrt((x2-x1)^2 + (y2-y1)^2);
        targdir(end+1) = targ_dir(i);
    end
end
a(a<0) = a(a<0)+360;
[n,xedges,yedges,binx,biny]=histcounts2(a,amp,0:5:360,0:2:40);
figure
imagesc(yedges,xedges,n)
ylabel('saccade angle (deg)')
xlabel('saccade amplitude (dva)')







%% now look at the RF map for the upward target



%% now look at the RF map for the rightward target




