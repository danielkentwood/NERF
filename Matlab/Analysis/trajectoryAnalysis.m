
%% load stuff
if exist('sessList','var') && ~exist('Trials','var')
    Trials = open_merged(sessList);
end
%%
if ~exist('probe')
    Trials = saccade_detector(Trials);  
    Trials = cleanTrials(Trials);
    probe_preprocess
    curUnit=1;
end
chan=find(~cellfun(@isempty,{Trials(1).Electrodes.Units}));
xw = 30;
yw = 20;


%% get presaccadic RF
% params.earliest    = 0;
% params.latest      = 10;
params.earliest    = 15;
params.latest      = 50;
params.windowsize  = 40;
params.wind_inc    = 1; 
params.standard_caxis = 0;
params.plotflag    = 0;
params.timeLock    = 'fix';
params.spaceLock   = 'fix1';
params.xwidth      = xw;
params.ywidth      = yw;
params.estimator   = 'PTA';

sacc_isis = probe.t_fix_lock-probe.t_sacc_start_lock;

psRF = plotRF_trajectory(probe(sacc_isis>400,:),curUnit,params);
% psRF.RF = probes_RF_estimate(probe,curUnit,params);


% get info about the RF location
psx = [];psy=[];
for i = 1:length(psRF.RF)
   psx(i) = psRF.RF(i).RF.Centroid(1);
   psy(i) = psRF.RF(i).RF.Centroid(2);
end
figure()
plot((params.earliest:params.latest)+params.windowsize/2,[psx',psy'],'o-')
legend('x','y','location','best')
xlabel('Time')

% RFwin_s = 0;
% RFwin_e = 15;
% psxm = nanmedian(psx(params.earliest:params.wind_inc:params.latest >=RFwin_s & ...
%     params.earliest:params.wind_inc:params.latest <=RFwin_e));
% psym = nanmedian(psy(params.earliest:params.wind_inc:params.latest >=RFwin_s & ...
%     params.earliest:params.wind_inc:params.latest <=RFwin_e));

% get RF axis with linear fit to RF and origin.
psxm = mode(round(psx(~isnan(psx))));
psym = mode(round(psy(~isnan(psy))));
Prf = polyfit([0 psxm], [0 psym], 1);
pRFdist = sqrt(psxm^2 + psym^2);
psRF.pRFdist = pRFdist;
psRF.RFx = psxm;
psRF.RFy = psym;
psRF.RF_axis_coeff = Prf;


%% grab a couple filters
dir2RF=atan2d(psym-probe.y_curFix,psxm-probe.x_curFix);
dir2RF(dir2RF<0)=dir2RF(dir2RF<0)+360;
dir2fix2=atan2d(probe.y_oneFixAhead-probe.y_curFix,probe.x_oneFixAhead-probe.x_curFix);
dir2fix2(dir2fix2<0)=dir2fix2(dir2fix2<0)+360;
RF_sacc_diff = abs(dir2RF-dir2fix2);


%% Exploit
params.earliest    = -60;
params.latest      = -0;
params.windowsize  = 40;
params.wind_inc    = 1; 
params.standard_caxis = 1;
params.plotflag    = 0;
params.timeLock    = 'sac1start';
params.spaceLock   = 'fix2';
params.def_RF      = [psxm psym];
params.xwidth      = xw;
params.ywidth      = yw;
params.estimator   = 'PTA';


exploit_filter = logical(probe.rewardedSacc) & ...
    sacc_isis>200 & ...
    RF_sacc_diff>50 & ...
    saccmag>5;


% exploitRF = plotRF_trajectory(probe(exploit_filter,:),curUnit,params);
exploitRF = plotRF_trajectory(probe(logical(probe.rewardedSacc),:),curUnit,params);
% exploitRF = plotRF_trajectory(probe(logical(toTarg),:),curUnit,params);
%%
% get exploit measurements
exploitRF = get_remap_measures(exploitRF, psRF);


%% Explore
params.earliest    = -60;
params.latest      = -0;
params.windowsize  = 40;
params.wind_inc    = 1; 
params.standard_caxis = 1;
params.plotflag    = 0;
params.timeLock    = 'sac1start';
params.spaceLock   = 'fix2';
params.def_RF      = [psxm psym];
params.xwidth      = xw;
params.ywidth      = yw;
params.estimator   = 'PTA';

% exploreRF = plotRF_trajectory(probe(~logical(probe.rewardedSacc) & sacc_isis>150 & saccmag>5,:),curUnit,params);
exploreRF = plotRF_trajectory(probe(~logical(probe.rewardedSacc),:),curUnit,params);
% exploreRF = plotRF_trajectory(probe(~logical(probe.rewardedSacc) & sacc_isis>150 & RF_sacc_diff>50 & saccmag>5,:),curUnit,params);
% exploreRF = plotRF_trajectory(probe(~logical(toTarg),:),curUnit,params);

%%
% get explore measurements
exploreRF = get_remap_measures(exploreRF, psRF);


%% plot remapping measures
animate=0;
plot_RF_axis([[exploitRF.RF.deviation] [exploreRF.RF.deviation]],...
    [[exploitRF.RF.axis_distance_ratio] [exploreRF.RF.axis_distance_ratio]],...
    [zeros(1,length(exploitRF.RF)) ones(1,length(exploreRF.RF))],...
    {'exploit','explore'},...
    animate)

plot_RF_axis([[exploitRF.RFxy_keep(1,1)] [exploreRF.RFxy_keep(1,1)]],...
    [[exploitRF.RFxy_keep(1,2)] [exploreRF.RFxy_keep(1,2)]],...
    [0 1],...
    {'exploit','explore'},...
    animate)













% 
% 
% %% Replay movie
% curmovie = exploitRF.movie;
% 
% close all
% [h, w, p] = size(curmovie(1).cdata);  % use 1st frame to get dimensions
% hf = figure; 
% % resize figure based on frame's w x h, and place at (150, 150)
% set(hf, 'position', [150 150 w h]);
% axis off
% movie(hf,curmovie,2);
% % mplay(curmovie)
% 
% 
% 
% 
% 
% 
% 
% 
% 
% %% now look at the timecourse of the PSTH
% 
% % if we're not already doing it, it would be interesting to compare the
% % heatmaps of the current and future fields of the cell. 
% 
% time_params.lock_event='saccade'; % which event are we time-locking to? 'saccade' or 'fixation'
% time_params.start_time=-300; % start time of the PSTH
% time_params.end_time=400; % end time of the PSTH
% time_params.dt=5; % temporal resolution of the PSTH
% 
% other_params.RF_xy       = [psxm psym];
% other_params.RF_size     = 10;
% other_params.remapped    = 1;
% other_params.probeSelect = 'RF'; % how to select the probes. Options: 'RF','Radial'
% other_params.plotflag    = 0;
% other_params.saccSelect  = 'outRF'; % subselection of saccades. Options: 'inRF','outRF','all'
% 
% % start_vec = params.earliest:params.wind_inc:params.latest;
% start_vec = -150:params.wind_inc:150;
% end_vec = start_vec+params.windowsize;
% 
% allPSTH = [];
% for i = 1:length(start_vec)
%     time_params.probe_window=[start_vec(i) end_vec(i)]; % bounds of probe selection time window (wrt to lock event)
%     PSTH = PProbeTH(Trials,chan,time_params,other_params);
%     allPSTH(i,:)=PSTH.unit.data.data;
%     allNumP(i) = PSTH.num_probes;
%     disp([num2str(i) ' of ' num2str(length(start_vec))])
% end
% 
% psth_time = PSTH.unit.data.time;
% bin_time = start_vec+round(params.windowsize/2);
% 
% figure
% imagesc(psth_time,bin_time,allPSTH)
% hold on
% plot([60 60],ylim,'--','color',[1 1 1])
% plot([150 150],ylim,'--','color',[1 1 1])
% plot([0 0],ylim,'-','color',[1 1 1],'linewidth',2)
% plot(xlim,[0 0],'-','color',[1 1 1],'linewidth',2)
% xlabel('PSTH time (ms)')
% ylabel('Sacc-locked probe bin time (ms)')
% % load RF_colormap
% % colormap(gca,mycmap)
% 
% 
% 
% %% MAKE VIDEO OF THE EVOLVING PPTH
% figure
% maxPSTH = max(allPSTH(:));
% allPSTHn = allPSTH./maxPSTH;
% maxPSTHn = max(allPSTHn(:));
% fh = figure;
% for i = 1:length(bin_time)
%     plot(psth_time,allPSTHn(i,:),'r','linewidth',2)
%     hold on
%     ylim([0 1])
%     xlim([psth_time(1) psth_time(end)])
% %     patch([time_params.start_time time_params.start_time+100 time_params.start_time+100 time_params.start_time],...
% %         [-40 -40 0 0],[0 0 0])
%     ts = bin_time(i);
%     text(psth_time(end)-(psth_time(end)-psth_time(1))*.4,.1,...
%         ['Bin time: ' num2str(ts) ' ms'],'Color',[0 0 0],'FontSize',14)
% 
%     plot([0 0],ylim,'k--')
%     set(gca,'fontsize',14)
%     xlabel('Time (ms')
%     ylabel('Normalized firing rate')
%     hold off
%     psth_movie(i)=getframe(fh);
% end
% 
% close all
% [h, w, p] = size(psth_movie(1).cdata);  % use 1st frame to get dimensions
% hf = figure; 
% % resize figure based on frame's w x h, and place at (150, 150)
% set(hf, 'position', [150 150 w h]);
% axis off
% movie(hf,psth_movie);
% 
% 
% 
% 
% 
% 
% 
% %% write to video
% v = VideoWriter('dynamicRF_GMR14_d4_g15_fix','MPEG-4');
% v.FrameRate = 8;
% open(v);
% for i = 1:length(psRF.movie)
%     writeVideo(v,psRF.movie(i));
% end
% close(v);
% 
% 
% % %% compute and visualize trajectory
% % for i = 1:length(RF.outFFtarg)
% %     exploit(i,:)=RF.outFFtarg(i).RF.Centroid;
% % end
% % plot(exploit(:,1),exploit(:,2),'-o')
% % hold on
% % plot(exploit(1,1),exploit(1,2),'ro','linewidth',2)
% % plot(exploit(end,1),exploit(end,2),'mo','linewidth',2)
% % plot(RF.outCF.RF.Centroid(1),RF.outCF.RF.Centroid(2),'kx','linewidth',3)
% 
% % now try plotting distance from presaccadic RF and/or from saccade
% % endpoint over time
% 
% 
% 
