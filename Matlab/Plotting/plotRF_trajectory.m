function out = plotRF_trajectory(probe,curUnit,params)

RF = probes_RF_estimate(probe,curUnit,params);


% set up figure
psh = figure;
% set(psh,'position',[560   112   504   830])
psh.Units = 'pixels';
pos = psh.Position;
rect = [0 0 pos(3) pos(4)];

if strcmp(params.timeLock,'fix')
    fixcolor = [1 0 0];
else
    fixcolor = [255/255,192/255,203/255];
end

% create the RF movie for exploit
load RF_colormap
for i = 1:length(RF)

    imagesc(RF(i).x,RF(i).y,RF(i).image);
    set(gca,'Ydir','normal')
    hold on
    
    % PLOT THE PEAK AND CENTROID OF THE RF MAP
%     plot(RF(i).RF.Peak(1),RF(i).RF.Peak(2),'k.','markersize',14)
%     plot(RF(i).RF.Centroid(1),RF(i).RF.Centroid(2),'kx','markersize',10,'linewidth',2)

    % PLOT THE DEFAULT RF (FROM THE FIXATION-BASED MAP)
    if isfield(params,'def_RF') && ~strcmp(params.spaceLock,'fix1')
        plot(params.def_RF(1),params.def_RF(2),'go','markersize',20,'linewidth',2)
        plot(params.def_RF(1),params.def_RF(2),'ko','markersize',20)
    end
    
    % SPRUCE UP THE PLOT
    plot([0 0],ylim,'k--')
    plot(xlim,[0 0],'k--')
    plot(0,0,'.','color',fixcolor,'markersize',28)
    plot(0,0,'ko','markersize',10,'linewidth',2)
    addScreenFrame([48 36],[0 0 0])
    % add timestamp
    patch([8 31 31 8],[15 15 21 21],[0 0 0])
    ts = RF(i).timeBin(1)+round(params.windowsize/2);
    text(8.5,17.5,['Time bin: ' num2str(ts) ' ms'],'Color',[1 1 1],'FontSize',14)
    % change colormap
    colormap(gca,mycmap)
    hold off 
    % capture frame
    out.movie(i)=getframe(psh,rect);
end
out.RF = RF;






























