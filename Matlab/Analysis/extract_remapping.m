% extract remapping

%% load stuff
if exist('sessList','var') && ~exist('Trials','var')
    Trials = open_merged(sessList);
end

if ~exist('probe')
    [Trials,probe,filters]=probe_preprocess(Trials);
    curUnit=1;
end
chan=find(~cellfun(@isempty,{Trials(1).Electrodes.Units}));
xw = 30;
yw = 20;


%% get presaccadic RF
params=[];
params.earliest    = -20;
params.latest      = 80;
params.windowsize  = 40;
params.wind_inc    = 1;
params.standard_caxis = 1;
params.plotflag    = 0;
params.timeLock    = 'fix';
params.spaceLock   = 'fix1';
params.xwidth      = xw;
params.ywidth      = yw;
params.estimator   = 'PTA';

% get RF estimates
sacc_isis = probe.t_fix_lock-probe.t_sacc_start_lock;

psRF=[];
psRF.RF = probes_RF_estimate(probe(sacc_isis>400,:),curUnit,params);
% plotRF_trajectory(probe(sacc_isis>400,:),curUnit,params);


% get info about the RF location
psx = [];psy=[];
for i = 1:length(psRF.RF)
    psx(i) = psRF.RF(i).RF.Centroid(1);
    psy(i) = psRF.RF(i).RF.Centroid(2);
end
try
    % Use Hierarchical Density-based Clustering to identify stable RFs
    X = [psx(:) psy(:)];
    X(any(isnan(X')),:)=[];
    
    clusterer = HDBSCAN( X );
    clusterer.minpts        = 8;
    clusterer.minclustsize  = 5;
    clusterer.outlierThresh = 0.95;
    clusterer.minClustNum   = 2;
    clusterer.fit_model(); 			% trains a cluster hierarchy
    clusterer.get_best_clusters(); 	% finds the optimal "flat" clustering scheme
    clusterer.get_membership();		% assigns cluster labels to the points in X
    % get the average of the clusters that reach a threshold for the number of
    % samples in a cluster
    hc = histcounts(double(clusterer.labels));
    [hc_s,hc_sidx]=sort(hc,'descend');
    hc_cutoff = 5;
    hc_keep = hc_sidx(hc_s>hc_cutoff);
    RFxy_keep=[];
    for i = 1:length(hc_keep)
        cur_group = hc_keep(i)-1;
        cur_data = clusterer.data(clusterer.labels==cur_group,:);
        cur_med = nanmean(cur_data);
        RFxy_keep(i,:)=cur_med;
    end
    if ~isempty(RFxy_keep)
        psxm = RFxy_keep(1,1);
        psym = RFxy_keep(1,2);
    end
catch
    psxm = mode(round(psx(~isnan(psx))));
    psym = mode(round(psy(~isnan(psy))));
end

psRF.RFx = psxm;
psRF.RFy = psym;
pRFdist = sqrt(psxm^2 + psym^2);
psRF.pRFdist = pRFdist;

% get RF axis with linear fit to RF and origin.
Prf = polyfit([0 psxm], [0 psym], 1);
psRF.RF_axis_coeff = Prf;

if 0
    % plot
    figure()
    subplot('position',[0.1 0.1 0.35 0.8])
    plot((params.earliest:params.latest)+params.windowsize/2,[psx',psy'],'o-')
    legend('x','y','location','best')
    xlabel('Center of time bin (ms)')
    
    subplot('position',[0.6 0.1 0.35 0.8])
    
    clusterer.plot_clusters();
    hold on
    plot(RFxy_keep(1,1), RFxy_keep(1,2), 'ko','linewidth',3)
    plot([0 0],[-20 20],'k--')
    plot([-30 30],[0 0],'k--')
    axis([-30 30 -20 20])
    hold off
end

%% Set params for the remapping RF estimation
params.earliest    = -150;
params.latest      = -0;
params.windowsize  = 40;
params.wind_inc    = 1;
params.standard_caxis = 1;
params.timeLock    = 'sac1start';
params.spaceLock   = 'fix2';
params.def_RF      = [psxm psym];
params.plotflag    = 0;
params.xwidth      = xw;
params.ywidth      = yw;
params.estimator   = 'PTA';



%% get exploit RF estimates
exploitRF=[];
exploitRF.RF = probes_RF_estimate(probe(logical(probe.rewardedSacc),:),curUnit,params);
% plotRF_trajectory(probe(logical(probe.rewardedSacc),:),curUnit,params);
% get exploit measurements
exploitRF = get_remap_measures(exploitRF, psRF);

%% get explore RF estimates
exploreRF=[];
exploreRF.RF = probes_RF_estimate(probe(~logical(probe.rewardedSacc),:),curUnit,params);
% plotRF_trajectory(probe(~logical(probe.rewardedSacc),:),curUnit,params);
% get explore measurements
exploreRF = get_remap_measures(exploreRF, psRF);










%% plot remapping measures
if 1
    animate=1;
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
    
end













