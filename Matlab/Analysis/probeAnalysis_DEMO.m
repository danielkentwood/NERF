% TEST script for analyzing the flash probes

% clear;clc;close all
% cd('C:\Data\Jiji\FlashProbe\c29\')
% load('m15_c29_mrg.mat')

% if ispc
%     opengl software % use openGL software rather than hardware (since you are using alpha transparency and this isn't compatible with openGL hardware currently)
% end

curUnit=1;


%% make a struct containing info about each saccade
saccade = makeSaccadeStruct(Trials);




%% use all saccades to estimate RFs
probeRF_estimate(saccade,curUnit);



%% use only the first fixation/saccade to estimate RFs
for s = 1:length(saccade)
   if saccade(s).sacc_num==1
       first_fix(s)=1;
   else first_fix(s)=0;
   end
end

probeRF_estimate(saccade(logical(first_fix)),curUnit)



%% plot RF over time for a limited subset of saccade metrics

% first, look at the distribution of saccade amplitudes and latencies
for s = 1:length(saccade)
    startx=saccade(s).start.x;
    starty=saccade(s).start.y;
    endx=saccade(s).end.x;
    endy=saccade(s).end.y;
    
    t1 = saccade(s).fix.t;
    t2 = saccade(s).start.t;
    
    vecx=endx-startx;
    vecy=endy-starty;
    
    sacc_angle(s)=atan2d(vecy,vecx);
    sacc_amp(s)=sqrt(vecx.^2 + vecy.^2);
    sacc_lat(s) = t2-t1;
end
sacc_angle(sacc_angle<0)=sacc_angle(sacc_angle<0)+360;
ye=0:10:360;
xe=0:5:50;

[hc,ye,xe] = histcounts2(sacc_angle,sacc_amp,ye,xe);
[hc,ye,xe] = histcounts2(sacc_angle,sacc_amp,ye,xe);
% plot this?
if 1
    figure
    imagesc(hc);
    set(gca,'xticklabels',xe(get(gca,'xtick')),'yticklabels',ye(get(gca,'ytick')))
    colorbar
    xlabel('amplitude')
    ylabel('angle')
end

%% look at fixations with latencies under a certain cutoff (Exploit?)

cutoff=300;
for s = 1:length(saccade)
    t1 = saccade(s).fix.t;
    t2 = saccade(s).start.t;
   if (t2-t1)<=cutoff
       low_lat(s)=1;
   else low_lat(s)=0;
   end
end
probeRF_estimate(saccade(~logical(low_lat)),curUnit)
probeRF_estimate(saccade(logical(low_lat)),curUnit)



%% look at fixations prior to rewarded saccades (Exploit?)

for s = 1:length(saccade)
   if saccade(s).rewarded
       rewarded(s)=1;
   else rewarded(s)=0;
   end
end
probeRF_estimate(saccade(logical(rewarded)),curUnit)

probeRF_estimate(saccade(~logical(rewarded)),curUnit)



%% plot RF over time for a limited subset of saccade vectors

% first, look at the distribution of saccade amplitudes and angles
for s = 1:length(saccade)
    startx=saccade(s).start.x;
    starty=saccade(s).start.y;
    endx=saccade(s).end.x;
    endy=saccade(s).end.y;
    
    vecx=endx-startx;
    vecy=endy-starty;
    
    sacc_angle(s)=atan2d(vecy,vecx);
    sacc_amp(s)=sqrt(vecx.^2 + vecy.^2);
end
sacc_angle(sacc_angle<0)=sacc_angle(sacc_angle<0)+360;
ye=0:10:360;
xe=0:5:50;
[hc,ye,xe] = histcounts2(sacc_angle,sacc_amp,ye,xe);
% plot this?
if 1
    figure
    imagesc(hc);
    set(gca,'xticklabels',xe(get(gca,'xtick')),'yticklabels',ye(get(gca,'ytick')))
    colorbar
    xlabel('amplitude')
    ylabel('angle')
end


%% now choose a direction
% looks like around 9dva is a good amplitude
prefAmp = 15;
ampBinSize=30;
prefAmpRange=[prefAmp-ampBinSize/2 prefAmp+ampBinSize/2];
% get index of saccades with this range of amplitudes
ampIdx = sacc_amp>=prefAmpRange(1) & sacc_amp<=prefAmpRange(2);

% now choose an angle
prefAngle = 0;
angleBinSize=40;
prefAngleRange=[prefAngle-angleBinSize/2 prefAngle+angleBinSize/2];
% get index of saccades with this range of angles
angleIdx = sacc_angle>=prefAngleRange(1) & sacc_angle<=prefAngleRange(2);
% combine the indices
curSaccs = ampIdx & angleIdx;


probeRF_estimate(saccade(logical(curSaccs)),curUnit)







% %% get spike triggered average of probe locations
% % now, average probe locations corresponding to each spike
% spike_lag = 50; % 50 ms ????
% eye2rex_lag = 10; % 10 ms?????
% rex2screen_lag = 10; % 10 ms?????
% sta_windowsize = 50; % 50 ms
% 
% for s = 1:length(saccade)
%     curtrial = saccade(s).trial;
%     % get eye position and timing
%     t_time = Trials(curtrial).Signals(1).Time-eye2rex_lag; % eye sampling time stamps
%     t_x = Trials(curtrial).Signals(1).Signal; % eye x position
%     t_y = Trials(curtrial).Signals(2).Signal; % eye y position
%     % get time of probes in this trial
%     probetimes = Trials(curtrial).probeXY_time(:,3)+rex2screen_lag;
%     % get xy position of probes in this trial
%     probexy = Trials(curtrial).probeXY_time(:,1:2);
%     % get xy position of eye at probe times
%     [~,idx]=ismember(probetimes,t_time);
%     eyexy = [t_x(idx)' t_y(idx)'];
%     % center the probe xy on the eye xy
%     probeCentXY = probexy-eyexy;
%     
%     
%     
%     % use probe time to create evaluation window
%     pwindow = probetimes(1):(probetimes(end)+100);
%     pwindow(pwindow>t_time(end))=[];
%     % create time series of probe location
%     probexy_series = NaN(length(pwindow),2);
%     p_counts = probetimes-probetimes(1)+1;
%     for np = 1:length(probetimes)
%         probexy_series(p_counts(np):(p_counts(np)+59),:)=repmat(probeCentXY(np,:),60,1);
%     end
% 
%     % find all spikes within this window
%     % start getting the STA
%     for u = 2:length(Trials(curtrial).Electrodes(chanList(1)).Units)
%         rawtimes = Trials(curtrial).Electrodes(chanList(1)).Units(u).Times;
%         stimes = rawtimes(rawtimes>=pwindow(1) & rawtimes<=pwindow(end));        
%     end
% end































%% get overall probe-triggered average
time_before_probe = 100;
time_after_probe = 300;
dt=5;
inc=1;
trode=1;
angleBins=linspace(0,360,9);
midBins = angleBins(1:end-1)+diff(angleBins)./2;
probeAngle=[];
st=[];
st_train=[];
for s= 1:length(saccade)
    fixx=saccade(s).fix.x;
    fixy=saccade(s).fix.y;
    fixt=saccade(s).fix.t;
    for fp=1:length(saccade(s).fix_probes)
        curprobe = saccade(s).fix_probes(fp);
        pt=curprobe.t-fixt;
        if pt<200 || pt>225
            continue
        end
        probex=curprobe.x-curprobe.eye_x;
        probey=curprobe.y-curprobe.eye_y;
        
        probeAngle(inc)=atan2d(probey,probex);

        st(inc,:)=saccade(s).fix_probes(fp).trode(trode).unit(curUnit).times_gauss;
        st_train(inc,:)=saccade(s).fix_probes(fp).trode(trode).unit(curUnit).times;
        inc=inc+1;
    end
end

probeAngle(probeAngle<0)=probeAngle(probeAngle<0)+360;
[n,edges,bin]=histcounts(probeAngle,angleBins);

figure
maxy = ceil(mean(max(st))*10)/10;
for i = 1:length(n)
%     subplot(2,4,i)
% figure
plot(-time_before_probe:dt:time_after_probe,sum(st_train(bin==i,:))./length(find(bin==i)),'linewidth',2)
%     plot(-time_before_probe:dt:time_after_probe,mean(st(bin==i,:)),'linewidth',2)
    hold all
%     ylim([0 maxy])
    xlim([-time_before_probe time_after_probe])
%     title([num2str(midBins(i)) ' deg'])
end
legend({'0','45','90','135','180','225','270','315'},'location','best')


% figure
% time_params.zero_time=0;
% time_params.start_time=-time_before_probe;
% time_params.end_time=time_after_probe;
% time_params.dt=dt;
% for i = 1:length(n)
%     PSTH_rast({st_train(bin==i,:)},time_params);
%     title([num2str(midBins(i)) ' deg'])
% end
% 














%%

% 
% for trial = 1:length(withProbe)
%     curtrial=withProbe(trial);
%     probes = Trials(curtrial).probeXY_time;
%     numsacs = length(Trials(curtrial).Saccades);
%     cur_ecodes = [Trials(curtrial).Events.Code];
%     cur_codeTimes = [Trials(curtrial).Events.Time];
%     
%     saccade(scInc).trial=curtrial;
%     for cp = 1:size(probes,1)
%         
%         cpX = probes(cp,1);
%         cpY = probes(cp,2);
%         cpT = probes(cp,3);
% 
%         eyeX = Trials(curtrial).Signals(1).Signal(Trials(curtrial).Signals(1).Time==cpT);
%         eyeY = Trials(curtrial).Signals(2).Signal(Trials(curtrial).Signals(2).Time==cpT);
%         
%         cpX0(it) = double(cpX)-eyeX;
%         cpY0(it) = double(cpY)-eyeY;
%         
%         start_time = cpT-time_before_probe;
%         end_time = cpT+time_after_probe;
%         
%         for trode=1:32
%             num_units=length(Trials(curtrial).Electrodes(trode).Units);
%             for u = 2:num_units
%                 sTimes = Trials(curtrial).Electrodes(trode).Units(u).Times;
%                 probe_sTimes = sTimes(sTimes>start_time & sTimes<end_time)- double(cpT);
%                 probeTrigSpikes = buildSpikeTrain(probe_sTimes,0,-time_before_probe,time_after_probe,dt);
%                 
%                 probeTS(trode).gauss{u-1}(it,:) = gauss_spTrConvolve(probeTrigSpikes,dt,sigma);
%                 probeFR(trode).unit{u-1}(it)=mean(probeTS(trode).gauss{u-1}(it,probeTrigTime>70 & probeTrigTime<130)).*1000;
%             end
%         end
%         it=it+1;
%     end 
% end
% 
% params.xwidth=400;
% params.ywidth=400;
% params.filtsize=[200 200];
% params.filtsigma=20;
% 
% for i=1:32
%     for u=1:length(probeFR(i).unit)
%         inferTuning(cpX0,cpY0,probeFR(i).unit{u},params);
%     end
% end
% 













% for trial = 1:length(withSaccs)
%     curtrial=withSaccs(trial);
%     events.code = [Trials(curtrial).Events.Code];
%     events.time = [Trials(curtrial).Events.Time];
%     numSaccs=length(Trials(curtrial).Saccades);
%     
%     for saccade_num = 1:numSaccs
%         % get the time of the previous saccade's ending (or the start of
%         % the trial)
%         if saccade_num==1
%             Trials(curtrial).Saccades(saccade_num).pre_time = events.time(events.code==4020); % get target onset time (for start of trial);
%         else
%             Trials(curtrial).Saccades(saccade_num).pre_time = Trials(curtrial).Saccades(saccade_num-1).saccade_end_time;
%         end
%         
%         % sometimes saccades are made prior to the target presentation (during
%         % the cue period). Make a note of when this happens
%         if Trials(curtrial).Saccades(saccade_num).pre_time>Trials(curtrial).Saccades(saccade_num).saccade_end_time
%             Trials(curtrial).Saccades(saccade_num).too_early=1;
%         else
%             Trials(curtrial).Saccades(saccade_num).too_early=0;
%         end
%         
%         % check to see if there are any probes during this saccade
%         if isempty(Trials(curtrial).probeXY_time);
%             probesInSacc = [];
%         else
%             probeTimes = Trials(curtrial).probeXY_time(:,3);
%             probesInSacc = probeTimes>Trials(curtrial).Saccades(saccade_num).pre_time & ...
%                 probeTimes<Trials(curtrial).Saccades(saccade_num).saccade_end_time;
%         end
%         Trials(curtrial).Saccades(saccade_num).probe_index=find(probesInSacc);
%         
%         % normalize the saccade to the center
%         sx1 = Trials(curtrial).Saccades(saccade_num).horizontal_position_start;
%         sy1 = Trials(curtrial).Saccades(saccade_num).vertical_position_start;
%         sx2 = Trials(curtrial).Saccades(saccade_num).horizontal_position_end;
%         sy2 = Trials(curtrial).Saccades(saccade_num).vertical_position_end;
%         % center by x1 and y1
%         cx2 = sx2-sx1;
%         cy2 = sy2-sy1;
%         % add to Trials struct
%         Trials(curtrial).Saccades(saccade_num).startXY = [0 0];
%         Trials(curtrial).Saccades(saccade_num).endXY = [cx2 cy2];
%     end
% end

