% compare behavior across conditions for the probeFlash experiment
function compareConds_probeFlash_behavior()

%% choose condition labels
prompt = {'Choose labels for conditions you want to compare.'};
dlg_title = 'Conditions';
num_lines = 1;
default_ans = {'''probe'',''no probe'''};
answer = inputdlg(prompt,dlg_title,num_lines,default_ans);
eval(['conds = {' answer{1} '}'])

%% select the sessions for each condition
for i = 1:length(conds)
    disp('***********************')
    disp('***********************')
    disp(['Select sessions for --' conds{i} '-- condition'])
    Trials = processOnlyREX;
    eval(['cond{' num2str(i) '} = Trials;']);
    Trials=[];
end

%% now run the analysis and plot the results


colors = [0 0 0;1 0 0;0 1 0;0 0 1;1 1 0;0 1 1;1 0 1];
cdx = 1;
for i = 1:length(conds)
    lengthOut(i) = Length_of_Trial(cond{i});

    csessID = lengthOut(i).sessionID;
    cns = lengthOut(i).num_saccs;
    ctt = lengthOut(i).trial_time;
    capv = lengthOut(i).ave_pv;
    caisi = lengthOut(i).ave_isi;
    
    uSess = unique(csessID);
    for us = 1:length(uSess)
        curSess = uSess(us);
        gns{i}(us) = nanmean(cns(1,cns(2,:)==curSess));
        gtt{i}(us) = nanmean(ctt(1,ctt(2,:)==curSess));
        gapv{i}(us) = nanmean(capv(1,capv(2,:)==curSess));
        gaisi{i}(us) = nanmean(caisi(1,caisi(2,:)==curSess));
    end

    mns(i) = nanmean(gns{i});
    mtt(i) = nanmean(gtt{i});
    mapv(i) = nanmean(gapv{i});
    maisi(i) = nanmean(gaisi{i});
  	
    sns(i) = nanstd(gns{i})/sqrt(length(gns{i}));
    stt(i) = nanstd(gtt{i})/sqrt(length(gtt{i}));
    sapv(i) = nanstd(gapv{i})/sqrt(length(gapv{i}));
    saisi(i) = nanstd(gaisi{i})/sqrt(length(gaisi{i}));
    
    % PLOTTING
    figure(1)
    hold on
    fpt = smooth(nanmean(lengthOut(i).findProb_targ));
    fpd = smooth(nanmean(lengthOut(i).findProb_dist));
%     fpt_p = (fpt./sum([fpt; fpd]));
%     fpd_p = (fpd./sum([fpt; fpd]));
    plot(lengthOut(i).degSpan,fpt,'-','color',colors(cdx,:),'linewidth',2)
    plot(lengthOut(i).degSpan,fpd,'--','color',colors(cdx,:),'linewidth',2)
    plabels{2*(i-1)+1}=[conds{i} ': Target'];
    plabels{2*(i-1)+2}=[conds{i} ': Distractor'];

    figure(2)
    hold on
    fph = smooth(nanmean(lengthOut(i).findProb_horizontal));
    fpv = smooth(nanmean(lengthOut(i).findProb_vertical));
%     fph_p = (fph./sum([fph; fpv]));
%     fpv_p = (fpv./sum([fph; fpv]));
    plot(lengthOut(i).degSpan,fph,'-','color',colors(cdx,:),'linewidth',2)
    plot(lengthOut(i).degSpan,fpv,'--','color',colors(cdx,:),'linewidth',2)
    plabels_hv{2*(i-1)+1}=[conds{i} ': Horizontal'];
    plabels_hv{2*(i-1)+2}=[conds{i} ': Vertical'];

    cdx=cdx+1;
end

numconds = length(conds);
permConds = nchoosek(1:numconds,2);
for i = 1:size(permConds,1)
    curpair=permConds(i,:);
    [h,p,ci,t]=ttest2(gns{curpair(1)},gns{curpair(2)});
    disp(['NUMBER OF SACCADES, ' conds{curpair(1)} ' (M=' num2str(mns(1)) ', SE=' num2str(sns(1))...
        ' vs ' conds{curpair(2)} ' (M=' num2str(mns(2)) ', SE=' num2str(sns(2))...
        '): t(' num2str(t.df) ')=' num2str(t.tstat) ', p = ' num2str(p)]);
    [h,p,ci,t]=ttest2(gtt{curpair(1)},gtt{curpair(2)});
    disp(['TRIAL TIME, ' conds{curpair(1)} ' (M=' num2str(mtt(1)) ', SE=' num2str(stt(1))...
        ' vs ' conds{curpair(2)} ' (M=' num2str(mtt(2)) ', SE=' num2str(stt(2))...
        '): t(' num2str(t.df) ')=' num2str(t.tstat) ', p = ' num2str(p)]);
    
    [h,p,ci,t]=ttest2(gapv{curpair(1)},gapv{curpair(2)});
    disp(['PEAK VELOCITY, ' conds{curpair(1)} ' (M=' num2str(mapv(1)) ', SE=' num2str(sapv(1))...
        ' vs ' conds{curpair(2)} ' (M=' num2str(mapv(2)) ', SE=' num2str(sapv(2))...
        '): t(' num2str(t.df) ')=' num2str(t.tstat) ', p = ' num2str(p)]);
    
    [h,p,ci,t]=ttest2(gaisi{curpair(1)},gaisi{curpair(2)});
    disp(['INTERSACCADIC INTERVAL, ' conds{curpair(1)} ' (M=' num2str(maisi(1)) ', SE=' num2str(saisi(1))...
        ' vs ' conds{curpair(2)} ' (M=' num2str(maisi(2)) ', SE=' num2str(saisi(2))...
        '): t(' num2str(t.df) ')=' num2str(t.tstat) ', p = ' num2str(p)]);
end
    


figure(1)
box off
xlabel('Fixation distance from targ/dist (deg)','FontSize',15)
ylabel('Prob(NEXT SACCADE FINDS T/D)','FontSize',15)
ylim([0 1])
title('Target Detectability','FontSize',15);
lh1 = legend(plabels,'location','best');
set(lh1,'box','off')

figure(2)
box off
xlabel('Fixation distance from gabor (deg)','FontSize',15)
ylabel('Prob(NEXT SACCADE FINDS GABOR)','FontSize',15)
ylim([0 1])
title('Gabor Orientation Preference','FontSize',15);
lh2 = legend(plabels_hv,'location','best');
set(lh2,'box','off')

figure(3)
subplot(2,2,1)
bar(1:length(mns),mns,'FaceColor','None');
hold on
errorbar(1:length(mns),mns,sns,'.')
set(gca,'XTickLabel',conds)
ylabel('Number of saccades')
title('Number of saccades before reward')

subplot(2,2,2)
bar(1:length(mtt),mtt,'FaceColor','None');
hold on
errorbar(1:length(mtt),mtt,stt,'.')
set(gca,'XTickLabel',conds)
ylabel('Time (ms)')
title('Duration of trial')

subplot(2,2,3)
bar(1:length(mapv),mapv,'FaceColor','None');
hold on
errorbar(1:length(mapv),mapv,sapv,'.')
set(gca,'XTickLabel',conds)
ylabel('Peak Velocity')
title('Peak saccadic velocity')

subplot(2,2,4)
bar(1:length(maisi),maisi,'FaceColor','None');
hold on
errorbar(1:length(maisi),maisi,saisi,'.')
set(gca,'XTickLabel',conds)
ylabel('Time (ms)')
title('Average intersaccadic interval')



%% get the distraction probability from the probes
choice = questdlg('Do you want to select a probe/noProbe pair for distraction probabilities?', ...
    'Distraction', ...
    'Yes','No','Yes');
colors = [0 0 0;1 0 0;0 1 0;0 0 1;1 1 0;0 1 1;1 0 1];
cdx = 1;
while strcmp(choice,'Yes')
    [s_p,v]=listdlg('PromptString','Select Probe Cond:',...
        'SelectionMode','Single',...
        'ListString',conds);
    [s_np,v]=listdlg('PromptString','Select No-Probe Cond:',...
        'SelectionMode','Single',...
        'ListString',conds);
    
    da_p = probe_distraction_probability(cond{s_p});
    da_np = probe_distraction_probability(cond{s_np});
    
    numbins=70;
    [n_p,x]=hist(da_p,numbins);
    [n_np]=hist(da_np,x);
    p_p = n_p/sum(n_p);
    p_np = n_np/sum(n_np);
    
    n_diff = p_p-p_np;
    
    figure(4)
    subplot(3,1,1)
    hold on
    plot(x,p_p,'color',colors(cdx,:),'linewidth',2);
    subplot(3,1,2)
    hold on
    plot(x,p_np,'color',colors(cdx,:),'linewidth',2);
    subplot(3,1,3)
    hold on
    plotHand = plot(x,n_diff,'color',colors(cdx,:),'linewidth',2);
    cdx=cdx+1;
    
    choice = questdlg('Another pair?', ...
    'Distraction', ...
    'Yes','No','No');
end
if exist('da_p','var')
    subplot(3,1,1)
%     xlim([0 2*pi]) % radians
    xlim([0 (2*pi)*(180/pi)]) % degrees
    ylim([-.01 .05])
    hold on
    plot(xlim,[0 0],'r-')
    title('Probability of Probe Attracting a Saccade','FontSize',16)
    xlabel('Difference between saccade vector and fixation-probe vector (degrees)','FontSize',14)
    ylabel('Percentage of instances','FontSize',14)
        subplot(3,1,2)
%     xlim([0 2*pi]) % radians
    xlim([0 (2*pi)*(180/pi)]) % degrees
    ylim([-.01 .05])
        hold on
    plot(xlim,[0 0],'r-')
    title('Center Bias (i.e., no probe)','FontSize',16)
    xlabel('Difference between saccade vector and fixation-probe vector (degrees)','FontSize',14)
    ylabel('Percentage of instances','FontSize',14)
        subplot(3,1,3)
%     xlim([0 2*pi]) % radians
    xlim([0 (2*pi)*(180/pi)]) % degrees
    ylim([-.01 .05])
        hold on
    plot(xlim,[0 0],'r-')
    title('Probability of Probe Attracting a Saccade, Corrected for Center Bias','FontSize',16)
    xlabel('Difference between saccade vector and fixation-probe vector (degrees)','FontSize',14)
    ylabel('Percentage of instances','FontSize',14)
end






