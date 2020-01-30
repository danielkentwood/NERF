

function spikeTriggeredAverage2(Trials,curUnit)


% lag parameters
spike_lag =55; % 50 ms ????
eye2rex_lag = 10; % 10 ms?????
rex2screen_lag = 10; % 10 ms?????

% sta parameters
sta_windowsize = 50; % 50 ms
filtsize    = [10 10];
filtsigma   = 2;

% time bin parameters for plotting
earliest_s=-300;
latest_s=-50;
earliest_f=0;
latest_f=250;
windowsize=50; % default: 50
wind_inc=50; % (time between windows) default: 50
start_times_s=earliest_s:wind_inc:latest_s;
end_times_s=start_times_s+windowsize;
start_times_f=earliest_f:wind_inc:latest_f;
end_times_f=start_times_f+windowsize;
st_probeXY_fix=cell(1,length(start_times_f));
st_probeXY_sac=cell(1,length(start_times_s));

% % set parameters for spatial smoothing during inferTuning.m
% params.xwidth=30;
% params.ywidth=20;
% params.filtsize=[20 20];
% params.filtsigma=2.5;

% how many channels are there?
for i = 1:length(Trials(1).Electrodes)
    chanList(i)=~isempty(Trials(1).Electrodes(i).Units);
end
chanList=find(chanList);


for tr = 1:length(Trials)
    curtrial = Trials(tr);
    if isempty(curtrial.probeXY_time)
        continue
    end
    
    % get eye position and timing
    t_time = curtrial.Signals(1).Time-eye2rex_lag; % eye sampling time stamps
    t_x = curtrial.Signals(1).Signal; % eye x position
    t_y = curtrial.Signals(2).Signal; % eye y position
    % get time of probes in this trial
    probetimes = curtrial.probeXY_time(:,3)+rex2screen_lag;
    % get xy position of probes in this trial
    probexy = curtrial.probeXY_time(:,1:2);
    % get xy position of eye at probe times
    [~,idx]=ismember(probetimes,t_time);
    eyexy = [t_x(idx)' t_y(idx)'];
    % center the probe xy on the eye xy
    pXY_fix = probexy-eyexy;
    % grab spike train for this trial
    
    
    
    
%     spktimes = curtrial.Electrodes(chanList).Units(curUnit).Times;
    spktimes = t_time(1:4:end); % get a meaningless spike train to test for artifactual effects
    
    
    
    
    % lock probe times to fixation onset or saccade onset
    for s = 1:length(curtrial.Saccades) % try starting from the 2nd fixation (otherwise you get the probe grid really strongly represented)
        t_fix = curtrial.Saccades(s).t_start_prev_fix;
        t_sacc = curtrial.Saccades(s).t_start_sacc;
        sacc_end_xy = [curtrial.Saccades(s).x_sacc_end curtrial.Saccades(s).y_sacc_end];
        curprobes=find(probetimes>=t_fix & probetimes<=t_sacc);
        probetimes_raw = probetimes(curprobes);
        probetimes_fix = probetimes(curprobes)-t_fix;
        probetimes_sac = probetimes(curprobes)-t_sacc;
        probeXY_sac = probexy(curprobes,:)-repmat(sacc_end_xy,size(probexy(curprobes,:),1),1);
        probeXY_fix = pXY_fix(curprobes,:);
        
        st_fix = spktimes(spktimes>=(t_fix+spike_lag) & spktimes<=(t_sacc+spike_lag))-t_fix;
        st_sac = spktimes(spktimes>=(t_fix+spike_lag) & spktimes<=(t_sacc+spike_lag))-t_sacc;
        
        for i = 1:length(start_times_f)
            curspk=find(st_fix>=start_times_f(i) & st_fix<=end_times_f(i));
            for cspk = 1:length(curspk)
                % for each spike in the bin, go back in time (spike_lag
                % plus sta window size) and see if and where there was a probe
                pidx = find(probetimes_fix>=(st_fix(curspk(cspk))-spike_lag-sta_windowsize/2) ...
                    & probetimes_fix<=(st_fix(curspk(cspk))-spike_lag+sta_windowsize/2));
                if isempty(pidx)
                    st_probeXY_fix{i}(end+1,:)=[NaN NaN];
                else
                    st_probeXY_fix{i}(end+1,:)=probeXY_fix(pidx,:);
                end
            end
        end
        for i = 1:length(start_times_s)
            curspk=find(st_sac>=start_times_s(i) & st_sac<=end_times_s(i));
            for cspk = 1:length(curspk)
                % for each spike in the bin, go back in time (spike_lag
                % plus sta window size) and see if and where there was a probe
                pidx = find(probetimes_sac>=(st_sac(curspk(cspk))-spike_lag-sta_windowsize/2) ...
                    & probetimes_sac<=(st_sac(curspk(cspk))-spike_lag+sta_windowsize/2));
                if isempty(pidx)
                    st_probeXY_sac{i}(end+1,:)=[NaN NaN];
                else
                    st_probeXY_sac{i}(end+1,:)=probeXY_sac(pidx,:);
                end
            end
        end     
    end
end
    





xe=-30:30;
ye=-25:25;
G = fspecial('gaussian',filtsize,filtsigma);


for i=1:length(start_times_f)
    
    st_pxy = st_probeXY_fix{i};
    st_pxy = round(st_pxy);
    
    if isempty(st_pxy)
        Ig_f(:,:,i) = zeros(length(ye)-1,length(xe)-1);
    else
    st_grid=histcounts2(st_pxy(:,2),st_pxy(:,1),ye,xe);
    
    
%     Ig_f(:,:,i) = imfilter(st_grid,G,'same');  % COMMENTING OUT THE
%     SMOOTHING JUST IN CASE IT IS CAUSING THE ARTIFACT -- IT ISN'T.
    Ig_f(:,:,i) = st_grid;
    
    
    
    end
end
    


for i=1:length(start_times_s)
    
    st_pxy = st_probeXY_sac{i};
    st_pxy = round(st_pxy);
    
    if isempty(st_pxy)
        Ig_s(:,:,i) = zeros(length(ye)-1,length(xe)-1);
    else
        st_grid=histcounts2(st_pxy(:,2),st_pxy(:,1),ye,xe);
%         Ig_s(:,:,i) = imfilter(st_grid,G,'same');
        Ig_s(:,:,i) = st_grid;
    end
end
% convert to z-scores
zIg_f = Ig_f;
zIg_f(1:length(Ig_f(:)))=zscore(Ig_f(:));
zIg_s = Ig_s;
zIg_s(1:length(Ig_s(:)))=zscore(Ig_s(:));

range_f = [min(min(min(zIg_f))) max(max(max(zIg_f)))];
range_s = [min(min(min(zIg_s))) max(max(max(zIg_s)))];

fa=figure;
for i=1:length(start_times_f)
    subplot(1,length(start_times_f),i)
    imagesc(xe,ye,zIg_f(:,:,i))
    hold on
    plot([0 0],ylim,'w-')
    plot(xlim,[0 0],'w-')
    caxis(range_f)
end
fb=figure;
for i=1:length(start_times_s)
    subplot(1,length(start_times_s),i)
    imagesc(xe,ye,zIg_s(:,:,i))
    hold on
    plot([0 0],ylim,'w-')
    plot(xlim,[0 0],'w-')
    caxis(range_s)
end

figure(fa)
set(gcf,'position',[4         800        1910         197])
subplot(1,length(start_times_f),1)
colorbar('position',[0.1 0.1 .01 .8])

figure(fb)
set(gcf,'position',[4         517        1910         197])
subplot(1,length(start_times_s),1)
colorbar('position',[0.1 0.1 .01 .8])


%     curprobes_f=probe_times_f>=start_times_f(i) & probe_times_f<=end_times_f(i);
%     fixX=probe_x_fix(curprobes_f);
%     fixY=probe_y_fix(curprobes_f);
%     fr_f=probe_fr(1).unit(curUnit).rate(curprobes_f);
%     params.fig_Handle=fa;
%     params.axes_Handle=subplot(1,length(start_times_f),i);
%     out.f=inferTuning(fixX,fixY,fr_f,params);
%        
%     fmax(i)=max(max(out.f.image));
%     fmin(i)=min(min(out.f.image));    
%     
%     addScreenFrame([48 36],[1 1 1])
%     title([num2str(start_times_f(i)) '-' num2str(end_times_f(i)) ' ms'])
end














% 
% st_probeXY=round(st_probeXY);
% 
% 
% [st_grid,xe,ye]=histcounts2(st_probeXY(:,1),st_probeXY(:,2),-30:30,-25:25);
% 
% G = fspecial('gaussian',filtsize,filtsigma);
% % Filter it
% Ig = imfilter(st_grid,G,'same');
% 
% imagesc(xe,ye,Ig)
% hold on
% plot([0 0],ylim,'w-')
% plot(xlim,[0 0],'w-')
% 
% 





















% gridHeight=51;
% yMid=(gridHeight-1)/2 + 1;
% gridWidth=61;
% xMid=(gridWidth-1)/2 + 1;
% default_grid = zeros(gridHeight,gridWidth);
% st_grid=default_grid;
% for i = 1:size(st_probeXY,1)
%     curxy=st_probeXY(i,:);
%     cur_grid = default_grid;
%     if isnan(curxy(1)) || abs(curxy(1))>=xMid || abs(curxy(2))>=yMid
%         continue
%     end
%     cur_grid(curxy(2)+yMid,curxy(1)+xMid)=1;
%     st_grid=st_grid + cur_grid;
% end






% 
%         % use probe time to create evaluation window
%         pwindow = probetimes(1):(probetimes(end)+100);
%         pwindow(pwindow>t_time(end))=[];
%         % create time series of probe location
%         probexy_series = NaN(length(pwindow),2);
%         p_counts = probetimes-probetimes(1)+1;
%         for np = 1:length(probetimes)
%             probexy_series(p_counts(np):(p_counts(np)+59),:)=repmat(probeCentXY(np,:),60,1);
%         end
%         
%         % find all spikes within this window
%         % start getting the STA
%         for u = 2:length(Trials(curtrial).Electrodes(chanList(1)).Units)
%             rawtimes = Trials(curtrial).Electrodes(chanList(1)).Units(u).Times;
%             stimes = rawtimes(rawtimes>=pwindow(1) & rawtimes<=pwindow(end));
%         end