% probeAnalysis

if ~exist('probe')
    probe_preprocess
    curUnit=1;
end





%% plot a few histograms comparing explore/exploit saccade metrics

figure
bins = .5:.02:2;
[n1,x1] = hist(relVel(relVel<2 & logical(probe.rewardedSacc)),bins);
[n2,x2] = hist(relVel(relVel<2 & ~logical(probe.rewardedSacc)),bins);
n1n = n1/length(find(relVel<2 & logical(probe.rewardedSacc)));
n2n = n2/length(find(relVel<2 & ~logical(probe.rewardedSacc)));
h2 = bar(x2,n2n);
hold on
h1 = bar(x1,n1n);
set(h1,'facecolor','r','edgecolor','none','facealpha',.5)
set(h2,'facealpha',.5,'edgecolor','none')
title('relative velocities')
lh = legend('explore','exploit','location','best');
set(lh,'box','off')


figure
bins = 0:20:1600;
[n1,x1] = hist(saccisi(logical(probe.rewardedSacc)),bins);
[n2,x2] = hist(saccisi(~logical(probe.rewardedSacc)),bins);
n1n = n1/length(saccisi(logical(probe.rewardedSacc)));
n2n = n2/length(saccisi(~logical(probe.rewardedSacc)));
h2 = bar(x2,n2n);
hold on
h1 = bar(x1,n1n);
set(h1,'facecolor','r','edgecolor','none','facealpha',.5)
set(h2,'facealpha',.5,'edgecolor','none')
title('latencies')
lh = legend('explore','exploit','location','best');
set(lh,'box','off')

figure
bins = 0:.5:50;
[n1,x1] = hist(saccmag(logical(probe.rewardedSacc)),bins);
[n2,x2] = hist(saccmag(~logical(probe.rewardedSacc)),bins);
n1n = n1/length(saccmag(logical(probe.rewardedSacc)));
n2n = n2/length(saccmag(~logical(probe.rewardedSacc)));
h2 = bar(x2,n2n);
hold on
h1 = bar(x1,n1n);
set(h1,'facecolor','r','edgecolor','none','facealpha',.5)
set(h2,'facealpha',.5,'edgecolor','none')
title('amplitudes')
lh = legend('explore','exploit','location','best');
set(lh,'box','off')


figure
bins = 0:2:360;
[n1,x1] = hist(saccdir(logical(probe.rewardedSacc)),bins);
[n2,x2] = hist(saccdir(~logical(probe.rewardedSacc)),bins);
n1n = n1/length(saccdir(logical(probe.rewardedSacc)));
n2n = n2/length(saccdir(~logical(probe.rewardedSacc)));
h2 = bar(x2,n2n);
hold on
h1 = bar(x1,n1n);
set(h1,'facecolor','r','edgecolor','none','facealpha',.5)
set(h2,'facealpha',.5,'edgecolor','none')
title('saccade direction')
lh = legend('explore','exploit','location','best');
set(lh,'box','off')


%% get presaccadic RF
params.earliest    = 25;
params.latest      = params.earliest;
params.windowsize  = 50;
params.wind_inc    = 25; 
params.timeLock    = 'fix';
params.spaceLock   = 'fix1';
params.plotflag    = 1;
params.estimator   = 'PTA';
RF.outCF = probes_RF_estimate(probe,curUnit,params);

sacc_isis = probe.t_fix_lock-probe.t_sacc_start_lock;

% get info about the RF location

psxm = RF.outCF.RF.Centroid(1);
psym = RF.outCF.RF.Centroid(2);

dir2RF=atan2d(psym-probe.y_curFix,psxm-probe.x_curFix);
dir2RF(dir2RF<0)=dir2RF(dir2RF<0)+360;

dir2fix2=atan2d(probe.y_oneFixAhead-probe.y_curFix,probe.x_oneFixAhead-probe.x_curFix);
dir2fix2(dir2fix2<0)=dir2fix2(dir2fix2<0)+360;

RF_sacc_diff = abs(dir2RF-dir2fix2);



%% go to (target OR Distractor) OR NOT
% toTarg = abs(saccdir-dir2targ)<30 & dist2targ<7;
% toDist = abs(saccdir-dir2dist)<30 & dist2dist<7;
toTarg = dist2targ<5;
toDist = dist2dist<5;

params=[];
params.earliest    = -20;
params.latest      = -20;
params.windowsize  = 25;
params.wind_inc    = 10; 
params.timeLock    = 'sac1start';
params.spaceLock   = 'fix2';
params.plotflag    = 1;
params.estimator   = 'PTA';

% outFFdist = probes_RF_estimate(probe(logical(toDist),:),curUnit,params);
outFFtarg = probes_RF_estimate(probe(logical(probe.rewardedSacc) & sacc_isis>200 & RF_sacc_diff>50 & saccmag>4,:),curUnit,params);
% outFFnodist = probes_RF_estimate(probe(~logical(toDist),:),curUnit,params);
outFFnotarg = probes_RF_estimate(probe(~logical(probe.rewardedSacc) & sacc_isis>200 & RF_sacc_diff>50 & saccmag>4,:),curUnit,params);
% outFFnotargnodist = probes_RF_estimate(probe(~logical(toDist | probe.rewardedSacc),:),curUnit,params);


cent = RF.outCF.RF.Centroid;
% dist = outFFdist.RF.Centroid;
targ = outFFtarg.RF.Centroid;
% nodist = outFFnodist.RF.Centroid;
notarg = outFFnotarg.RF.Centroid;
% notargnodist = outFFnotargnodist.RF.Centroid;

figure
% quiver(cent(1),-cent(2),dist(1)-cent(1),-(dist(2)-cent(2)),'Color',[0 0 0]);
hold on
quiver(cent(1),-cent(2),targ(1)-cent(1),-(targ(2)-cent(2)),'Color',[1 0 0]);
% quiver(cent(1),-cent(2),nodist(1)-cent(1),-(nodist(2)-cent(2)),'Color',[0 1 0]);
quiver(cent(1),-cent(2),notarg(1)-cent(1),-(notarg(2)-cent(2)),'Color',[1 0 1]);
% quiver(cent(1),-cent(2),notargnodist(1)-cent(1),-(notargnodist(2)-cent(2)),'Color',[0 0 1]);
% lh = legend('Distractor','Target','NotDistractor','NotTarg','NotDistOrTarg','Location','Best');
lh = legend('Target','NotTarg','Location','Best');
axis([-30 30 -20 20])
plot(xlim,[0 0],'k--')
plot([0 0],ylim,'k--')
set(lh,'box','off')

%%    
params.earliest    = -55;
params.latest      = 15;
params.windowsize  = 25;
params.wind_inc    = 1; 
params.standard_caxis = 0;
params.plotflag    = 0;
params.timeLock    = 'sac1start';
params.spaceLock   = 'fix2';

RF.outFFdist = probes_RF_estimate(probe(logical(toDist),:),curUnit,params);
RF.outFFtarg = probes_RF_estimate(probe(logical(probe.rewardedSacc),:),curUnit,params);
RF.outFFnodist = probes_RF_estimate(probe(~logical(toDist),:),curUnit,params);
RF.outFFnotarg = probes_RF_estimate(probe(~logical(probe.rewardedSacc),:),curUnit,params);
RF.outFFnotargnodist = probes_RF_estimate(probe(~logical(toDist | probe.rewardedSacc),:),curUnit,params);



% 
% 
% 
% %% take a look at the tuning for all probes
% 
% % timeLock values:
% %'fix','sac1start','sac1end','sac2end'
% % spaceLock values:
% %'fix1','fix2','fix3'
% 
% params.earliest    = 0;
% params.latest      = 50;
% params.windowsize  = 25;
% params.wind_inc    = 10; 
% probes_RF_estimate(probe,curUnit,'fix','fix1',params)
% 
% params.earliest    = -50;
% params.latest      = 0;
% params.windowsize  = 25;
% params.wind_inc    = 10; 
% probes_RF_estimate(probe,curUnit,'sac1start','fix2',params)
% 
% %% rewarded or not
% params.earliest    = 0;
% params.latest      = 50;
% params.windowsize  = 25;
% params.wind_inc    = 25; 
% 
% probes_RF_estimate(probe(logical(probe.rewardedSacc),:),curUnit,'fix','fix1',params);
% probes_RF_estimate(probe(~logical(probe.rewardedSacc),:),curUnit,'fix','fix1',params);
% 
% params.earliest    = -70;
% params.latest      = 0;
% params.windowsize  = 25;
% params.wind_inc    = 10; 
% 
% probes_RF_estimate(probe(logical(probe.rewardedSacc),:),curUnit,'sac1start','fix2',params);
% probes_RF_estimate(probe(~logical(probe.rewardedSacc),:),curUnit,'sac1start','fix2',params);
% 
% 
% 
% %% sorted by relative velocity
% 
% params.earliest    = 0;
% params.latest      = 50;
% params.windowsize  = 25;
% params.wind_inc    = 25; 
% 
% probes_RF_estimate(probe,curUnit,'fix','fix1',params);
% 
% params.earliest    = -50;
% params.latest      = 10;
% params.windowsize  = 25;
% params.wind_inc    = 10; 
% 
% probes_RF_estimate(probe(logical(relVel<1),:),curUnit,'sac1start','fix2',params);
% probes_RF_estimate(probe(logical(relVel>1),:),curUnit,'sac1start','fix2',params);
% 
% 
% 
% 
% 
% %% tst
% 
% params.earliest    = -75;
% params.latest      = 0;
% params.windowsize  = 25;
% params.wind_inc    = 25; 
% probes_RF_estimate(probe,curUnit,'sac1start','fix2',params)
% 
% 
% 
% 
% 
% 
% %% exclude certain saccade vectors
% 
% 
% sacckeep=logical(saccdir>45 | saccdir<135);
% % sacckeep=logical(saccdir>110 & saccdir<160);
% 
% 
% params.earliest    = 0;
% params.latest      = 75;
% params.windowsize  = 25;
% params.wind_inc    = 25; 
% probes_RF_estimate(probe(sacckeep,:),curUnit,'fix','fix1',params)
% 
% 
% 
% params.earliest    = -100;
% params.latest      = 0;
% params.windowsize  = 25;
% params.wind_inc    = 25; 
% probes_RF_estimate(probe(sacckeep,:),curUnit,'sac1start','fix2',params)
% 
% %% try out ALD 
% % you need to switch to ALD estimation under the "smoothing" section of 
% % inferTuning.m
% params.earliest    = 0;
% params.latest      = 0;
% params.windowsize  = 25;
% params.wind_inc    = 25; 
% 
% probes_RF_estimate(probe,curUnit,'fix','fix1',params)
% 
% %% go to target or NOT
% params.earliest    = 0;
% params.latest      = 25;
% params.windowsize  = 25;
% params.wind_inc    = 25; 
% probes_RF_estimate(probe,curUnit,'fix','fix1',params);
% 
% 
% toTarg = abs(saccdir-dir2targ)<35 & dist2targ<10;
% 
% params.earliest    = -70;
% params.latest      = 10;
% params.windowsize  = 25;
% params.wind_inc    = 10; 
% 
% probes_RF_estimate(probe(logical(probe.rewardedSacc),:),curUnit,'sac1start','fix2',params);
% probes_RF_estimate(probe(~logical(toTarg),:),curUnit,'sac1start','fix2',params);
% 
