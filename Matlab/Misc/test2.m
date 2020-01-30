% plot a single radial PPTH


time_params.lock_event='fixation'; % which event are we time-locking to? 'saccade' or 'fixation'
time_params.start_time=-300; % start time of the PSTH
time_params.end_time=600; % end time of the PSTH
time_params.dt=5; % temporal resolution of the PSTH

% other_params.RF_xy       = RF.outCF.RF.Peak;
% other_params.RF_size     = 10;
other_params.probeSelect = 'Radial'; % how to select the probes. Options: 'RF','Radial'
other_params.plotflag    = 1;

time_params.probe_window=[50 75]; % bounds of probe selection time window (wrt to lock event)
PSTH = PProbeTH(Trials,chan,time_params,other_params);




%% plot a pre-saved RF image
    out = psRF.RF;
    outimage = out(20).image;
    x = out(30).x;
    y = out(30).y;

    z_s = nanzscore(outimage(:));
    smin=min(z_s);smax=max(z_s);
    outimage_final = reshape(z_s,size(outimage));

    load RF_colormap
    fa=figure;
    
    if isnan(min(smin)),smin(1)=0;end
    if isnan(max(smax)),smax(1)=0;end

        imagesc(x,y,outimage_final);
        hold on
%         plot(out.RF.Peak(1),out.RF.Peak(2),'k.','markersize',10)
%         plot(out.RF.Centroid(1),out.RF.Centroid(2),'kx','markersize',10)
        plot([0 0],ylim,'w--')
        plot(xlim,[0 0],'w--')
        addScreenFrame([48 36],[1 1 1])


        caxis([min(smin) max(smax)])

        
        colormap(gca,mycmap)


    colorbar('position',[0.05 0.1 .035 .8])
