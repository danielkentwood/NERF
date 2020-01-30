

cd('C:\Data\Jiji\FlashProbe\allRFs')
drf = dir('C:\Data\Jiji\FlashProbe\allRFs');
drf(1:2)=[];

for i = 1:length(drf)
    load(drf(i).name);
    trf.filename = drf(i).name;
    
    pairs = [fieldnames(RF),struct2cell(RF);fieldnames(trf),struct2cell(trf)]';
    allRFs(i)=struct(pairs{:});

    cent = RF.outCF.RF.Centroid;
    cdist(i) = sqrt(cent(1).^2 + cent(2).^2);

    dist = RF.outFFdist(6).RF.Centroid;
    targ = RF.outFFtarg(6).RF.Centroid;
    notargnodist = RF.outFFnotargnodist(6).RF.Centroid;   
    
    ddist(i) = sqrt(dist(1).^2 + dist(2).^2);
    tdist(i) = sqrt(targ(1).^2 + targ(2).^2);
    ndist(i) = sqrt(notargnodist(1).^2 + notargnodist(2).^2);

    
    figure(31)
    hold on
    quiver(cent(1),-cent(2),targ(1)-cent(1),-(targ(2)-cent(2)),'Color',[1 0 0]);
    quiver(cent(1),-cent(2),dist(1)-cent(1),-(dist(2)-cent(2)),'Color',[0 0 0]);
    figure(33)
    hold on
    quiver(cent(1),-cent(2),targ(1)-cent(1),-(targ(2)-cent(2)),'Color',[1 0 0]);
    quiver(cent(1),-cent(2),notargnodist(1)-cent(1),-(notargnodist(2)-cent(2)),'Color',[0 0 1]);
end

figure(31)
axis([-30 30 -20 20])
plot(xlim,[0 0],'k--')
plot([0 0],ylim,'k--')
lh = legend('Target','Distractor','Location','Best');
set(lh,'box','off')

figure(33)
axis([-30 30 -20 20])
plot(xlim,[0 0],'k--')
plot([0 0],ylim,'k--')
lh = legend('Target','NotDistOrTarg','Location','Best');
set(lh,'box','off')

figure(34)
ddiff=cdist-ddist;
tdiff=cdist-tdist;
ndiff=cdist-ndist;
bar([1 3 5],[mean(tdiff) mean(ndiff) mean(ddiff)],'facecolor',[.8 .8 .8])
hold on
errorbar([1 3 5],[mean(tdiff) mean(ndiff) mean(ddiff)],...
    [std(tdiff)/sqrt(length(tdiff)) std(ndiff)/sqrt(length(tdiff)) std(ddiff)/sqrt(length(tdiff))],'k.','markersize',10)
set(gca,'xticklabels',{'Exploit Targ','Explore','Exploit Dist'})
ylabel({'Compression'; '(pre to perisaccadic RF distance from fixation)'});

