function probeRF_estimate(saccade,curUnit)

zscore_out=1; % make this a parameter eventually

prInc=1;
for s = 1:length(saccade)
    endX=saccade(s).end.x;
    endY=saccade(s).end.y;
    sacc_time=saccade(s).start.t;
    fix_time=saccade(s).fix.t;
    
    for pr = 1:length(saccade(s).fix_probes)
        probe_times_s(prInc) = saccade(s).fix_probes(pr).t-sacc_time;
        probe_times_f(prInc) = saccade(s).fix_probes(pr).t-fix_time;
        probe_x_fix(prInc) = saccade(s).fix_probes(pr).x-saccade(s).fix_probes(pr).eye_x;
        probe_y_fix(prInc) = saccade(s).fix_probes(pr).y-saccade(s).fix_probes(pr).eye_y;
        probe_x_end(prInc) = saccade(s).fix_probes(pr).x-endX;
        probe_y_end(prInc) = saccade(s).fix_probes(pr).y-endY;
        
        for tr = 1:length(saccade(s).fix_probes(pr).trode)
            for ut = 1:length(saccade(s).fix_probes(pr).trode(tr).unit)
                probe_fr(tr).unit(ut).rate(prInc) = saccade(s).fix_probes(pr).trode(tr).unit(ut).firing_rate;
            end
        end
        prInc=prInc+1;
    end
end
disp(['There are ' num2str(length(probe_times_s)) ' probes over ' ...
    num2str(length(saccade)) ' fixations.'])


%% Now build the RF maps
% you can change these or make them arguments for the function
% this will determine the width and number of windows you get in your plot
earliest_s=-75;
latest_s=-12.5;
windowsize_s=12.5; % default: 50
wind_inc_s=12.5; % (time between windows) default: 50
start_times_s=earliest_s:wind_inc_s:latest_s;
end_times_s=start_times_s+windowsize_s;

earliest_f=0;
latest_f=250;
windowsize_f=50; % default: 50
wind_inc_f=50; % (time between windows) default: 50
start_times_f=earliest_f:wind_inc_f:latest_f;
end_times_f=start_times_f+windowsize_f;

% set parameters for spatial smoothing during inferTuning.m
params.xwidth=30;
params.ywidth=20;
params.filtsize=[20 20];
params.filtsigma=2.5;

% aligned to fixation
fa=figure;
for i=1:length(start_times_f)
    curprobes_f=probe_times_f>=start_times_f(i) & probe_times_f<=end_times_f(i);
    fixX=probe_x_fix(curprobes_f);
    fixY=probe_y_fix(curprobes_f);
    fr_f=probe_fr(1).unit(curUnit).rate(curprobes_f);
    % 	fr_f=rand(1,length(fr_f))*50;
    params.fig_Handle=fa;
    params.axes_Handle=subplot(1,length(start_times_f),i);
    params.plotflag=0;
    out.f(i)=inferTuning(fixX,fixY,fr_f,params);
    outimage_f(:,:,i)=out.f(i).image;
end
% aligned to saccade
fb=figure;
for i=1:length(start_times_s)
    curprobes_s=probe_times_s>=start_times_s(i) & probe_times_s<=end_times_s(i);
    endX=probe_x_end(curprobes_s);
    endY=probe_y_end(curprobes_s);
    fr_s=probe_fr(1).unit(curUnit).rate(curprobes_s);
    % 	fr_s=rand(1,length(fr_s))*50;
    params.fig_Handle=fb;
    params.axes_Handle=subplot(1,length(start_times_s),i);
    params.plotflag=0;
    out.s(i)=inferTuning(endX,endY,fr_s,params);
    outimage_s(:,:,i)=out.s(i).image;
end

%% option to transform to z scores
if zscore_out
    z_s = zscore(outimage_s(:));
    z_f = zscore(outimage_f(:));
    fmin=min(z_f);fmax=max(z_f);
    smin=min(z_s);smax=max(z_s);
    outimage_s_final = reshape(z_s,size(outimage_s));
    outimage_f_final = reshape(z_f,size(outimage_f));
else
    fmin=min(outimage_f(:));fmax=max(outimage_f(:));
    smin=min(outimage_s(:));smax=max(outimage_s(:));
    outimage_s_final = outimage_s;
    outimage_f_final = outimage_f;
end

%% plotting
figure(fa)
set(gcf,'position',[4         800        1910         197])
if isnan(min(fmin)),fmin(1)=0;end
if isnan(max(fmax)),fmax(1)=0;end
for i=1:length(start_times_f)
    subplot(1,length(start_times_f),i)
    imagesc(out.f(i).x,out.f(i).y,outimage_f_final(:,:,i))
    hold on
    plot([0 0],ylim,'w--')
    plot(xlim,[0 0],'w--')
    addScreenFrame([48 36],[1 1 1])
    title([num2str(start_times_f(i)) '-' num2str(end_times_f(i)) ' ms'])
    caxis([min(fmin) max(fmax)])
end
subplot(1,length(start_times_f),1)
colorbar('position',[0.1 0.1 .01 .8])

figure(fb)
set(gcf,'position',[4         517        1910         197])
if isnan(min(smin)),smin(1)=0;end
if isnan(max(smax)),smax(1)=0;end
for i=1:length(start_times_s)
    subplot(1,length(start_times_s),i)
    imagesc(out.s(i).x,out.s(i).y,outimage_s_final(:,:,i))
    hold on
    plot([0 0],ylim,'w--')
    plot(xlim,[0 0],'w--')
    addScreenFrame([48 36],[1 1 1])
    title([num2str(start_times_s(i)) '-' num2str(end_times_s(i)) ' ms'])
    caxis([min(smin) max(smax)])
end
subplot(1,length(start_times_s),1)
colorbar('position',[0.1 0.1 .01 .8])



