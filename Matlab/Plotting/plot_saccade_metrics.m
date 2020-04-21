function plot_saccade_metrics(probe,filters)

figure('position',[604        -260        1474         915])
subplot(2,2,1)
bins = .5:.02:2;
[n1,x1] = hist(filters.relVel(filters.relVel<2 & logical(probe.rewardedSacc)),bins);
[n2,x2] = hist(filters.relVel(filters.relVel<2 & ~logical(probe.rewardedSacc)),bins);
n1n = n1/length(find(filters.relVel<2 & logical(probe.rewardedSacc)));
n2n = n2/length(find(filters.relVel<2 & ~logical(probe.rewardedSacc)));
h2 = bar(x2,n2n);
hold on
h1 = bar(x1,n1n);
set(h1,'facecolor','r','edgecolor','none','facealpha',.5)
set(h2,'facealpha',.5,'edgecolor','none')
title('relative velocities')
lh = legend('explore','exploit','location','best');
set(lh,'box','off')


subplot(2,2,2)
bins = 0:20:1600;
[n1,x1] = hist(filters.saccisi(logical(probe.rewardedSacc)),bins);
[n2,x2] = hist(filters.saccisi(~logical(probe.rewardedSacc)),bins);
n1n = n1/length(filters.saccisi(logical(probe.rewardedSacc)));
n2n = n2/length(filters.saccisi(~logical(probe.rewardedSacc)));
h2 = bar(x2,n2n);
hold on
h1 = bar(x1,n1n);
set(h1,'facecolor','r','edgecolor','none','facealpha',.5)
set(h2,'facealpha',.5,'edgecolor','none')
title('latencies')
lh = legend('explore','exploit','location','best');
set(lh,'box','off')

subplot(2,2,3)
bins = 0:.5:50;
[n1,x1] = hist(filters.saccmag(logical(probe.rewardedSacc)),bins);
[n2,x2] = hist(filters.saccmag(~logical(probe.rewardedSacc)),bins);
n1n = n1/length(filters.saccmag(logical(probe.rewardedSacc)));
n2n = n2/length(filters.saccmag(~logical(probe.rewardedSacc)));
h2 = bar(x2,n2n);
hold on
h1 = bar(x1,n1n);
set(h1,'facecolor','r','edgecolor','none','facealpha',.5)
set(h2,'facealpha',.5,'edgecolor','none')
title('amplitudes')
lh = legend('explore','exploit','location','best');
set(lh,'box','off')


subplot(2,2,4)
bins = 0:2:360;
[n1,x1] = hist(filters.saccdir(logical(probe.rewardedSacc)),bins);
[n2,x2] = hist(filters.saccdir(~logical(probe.rewardedSacc)),bins);
n1n = n1/length(filters.saccdir(logical(probe.rewardedSacc)));
n2n = n2/length(filters.saccdir(~logical(probe.rewardedSacc)));
h2 = bar(x2,n2n);
hold on
h1 = bar(x1,n1n);
set(h1,'facecolor','r','edgecolor','none','facealpha',.5)
set(h2,'facealpha',.5,'edgecolor','none')
title('saccade direction')
lh = legend('explore','exploit','location','best');
set(lh,'box','off')