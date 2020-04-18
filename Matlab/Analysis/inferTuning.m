function out = inferTuning(Trials,channels,plotflag)

if ispc
    opengl software % use openGL software rather than hardware (since you are using alpha transparency and this isn't compatible with openGL hardware currently)
end

if nargin<3
    plotflag=1;
end

% temporal parameters
dt = 10;
time_before = 75; % 75
time_after = -25; %-25

% grid parameters
xwidth=200;
ywidth=200;
xvec = -xwidth:xwidth;
yvec = -ywidth:ywidth;
tpall=zeros(length(xvec),length(yvec));

trialvec = 1:length(Trials);

statsctr = 1;

for electrode = channels
    if length(Trials(1).Electrodes(electrode).Units)==1
        unitvec=1:1;
        unitsub=0;
    else
        unitvec=2:length(Trials(1).Electrodes(electrode).Units);
        unitsub=1;
    end
    
    for unit = unitvec % first unit is unsorted spikes
        ind = 1;
        
        for trial = 1:length(trialvec)
            curtrial=trialvec(trial);
            ecodes = [Trials(curtrial).Events(:).Code];
            
            for saccade_num = 1:length(Trials(curtrial).Saccades)
                % get last saccade (assuming it is the one that was rewarded)
                sx1 = Trials(curtrial).Saccades(saccade_num).x_sacc_start;
                sy1 = Trials(curtrial).Saccades(saccade_num).y_sacc_start;
                sx2 = Trials(curtrial).Saccades(saccade_num).x_sacc_end;
                sy2 = Trials(curtrial).Saccades(saccade_num).y_sacc_end;
                
                % center by x1 and y1
                cx2 = sx2-sx1;
                cy2 = sy2-sy1;
                
                % get saccade onset time
                start_time = Trials(curtrial).Saccades(saccade_num).t_start_sacc - time_before;
                end_time = Trials(curtrial).Saccades(saccade_num).t_start_sacc + time_after;
                
                temp = {[Trials(curtrial).Electrodes(electrode).Units(unit).Times] - double(start_time)};
                data_struct(ind).data = full(getSpkMat(temp,dt,end_time-start_time,0));
                data_struct(ind).xy = [cx2;cy2];
                ind = ind + 1;
            end
        end
        
        firing_rate = nan(length(data_struct),1);
        
        % Get firing rates
        for ind = 1:length(data_struct)
            allx(ind) = data_struct(ind).xy(1);
            ally(ind) = data_struct(ind).xy(2);
            firing_rate(ind) = sum(data_struct(ind).data)*1000/(time_after+time_before);
        end
        
        
        rallx=ceil(allx);
        rally=ceil(ally);
        act_map=zeros(length(yvec),length(xvec));
        % get x,y position of each pixel on the grid
        [xg,yg]=meshgrid(xvec,yvec);
        knn=20; % number of neighbors that will influence each other
        decay=.05; % influence of neighbors decays over distance
        peaks = rf_smooth([rallx' rally'],[xg(:) yg(:)],firing_rate,decay,knn);
        Ig=reshape(peaks,size(act_map));
        G = fspecial('gaussian',[10 10],2);
        Ig = imfilter(Ig,G,'same');
        
        out{unit-unitsub}.Ig = Ig;
        out{unit-unitsub}.x = xvec;
        out{unit-unitsub}.y = yvec;
        
        if plotflag
            % plotting
            f1 = figure(100);
            set(f1,'name',['Electrode: ' num2str(electrode) ', Unit: ' num2str(unit)],'position',[390   154   414   843])
            
            %# Threshold it
            % make a white and black mask
            wmask=cat(3, ones(size(Ig)), ones(size(Ig)), ones(size(Ig)));
            bmask=cat(3, zeros(size(Ig)), zeros(size(Ig)), zeros(size(Ig)));
            % set the threshold
            iz = zscore(Ig(:));
            iz_grid = reshape(iz,size(Ig));
            iz_sort=sort(iz);
            iz_t = iz_sort((end-round(length(iz_sort)*.001)));
            
            % get threshold map and perimeter
            mask_alpha=.5;
            threshmap_raw = iz_grid<iz_t; threshmap_raw=threshmap_raw*mask_alpha; % the value at the end determines the alpha value of the mask
            
            % get stats on the regions that pass threshold
            stats=regionprops(~logical(threshmap_raw),'centroid','area','PixelIdxList','orientation','MajorAxisLength','MinorAxisLength');
            
            centroids = cat(1,stats.Centroid);
            areas = cat(1,stats.Area);
            % discard regions with area less than some threshold
            area_thresh=20;
            % first get max area
            [max_area,midx]=max(areas);
            % get mean activity values for each region
            for arv = 1:length(areas)
                mu_act(arv)=nanmean(Ig(stats(arv).PixelIdxList));
            end
            [max_act,mxidx]=max(mu_act);
            
            bad_area = setdiff(1:length(areas),mxidx);
            if max_area<area_thresh
                bad_area = [midx bad_area];
                good_area = [];
            else
                good_area = midx;
            end
            centroids(bad_area,:)=[];
            bad_pix = cat(1,stats(bad_area).PixelIdxList);
            threshmap_raw(bad_pix)=mask_alpha;
            % draw perimeter around significant regions
            tperim=bwperim(~logical(threshmap_raw),8);
            tpall = [tpall + tperim];
            
            %# Display
            subplot('position',[.11 .725 .85 .25])
            im1 = imagesc(xvec,yvec,Ig);
            set(gca,'Ydir','normal')
            hold on
            mh2 = imagesc(xvec,yvec,wmask);
            set(gca,'Ydir','normal')
            mh3 = imagesc(xvec,yvec,bmask);
            set(gca,'Ydir','normal')
            set(mh2, 'AlphaData', threshmap_raw)
            set(mh3, 'AlphaData', tperim)
            plot([0 0],ylim,'w--')
            plot(xlim,[0 0],'w--')
            hc1 = colorbar;
            set(get(hc1,'ylabel'),'String','Firing rate (spikes/s)')
            xlabel('X Position (degrees)')
            ylabel('Y Position (degrees)')
            axis([-40 40 -40 40]);
            if ~isempty(centroids)
                centx=(centroids(1)-xwidth-1);
                centy=(centroids(2)-ywidth-1);
                orient = deg2rad(stats(good_area).Orientation);
                minax = stats(good_area).MinorAxisLength*.7;
                majax = stats(good_area).MajorAxisLength*.7;
                figure(200)
                subplot(2,1,2)
                hold on
                ellipse(minax,majax,orient,centx,centy);
                
                allstats(statsctr).Centroid = [centx centy];
                allstats(statsctr).Orientation_rad = orient;
                allstats(statsctr).MinorAxisLength = minax;
                allstats(statsctr).MajorAxisLength = majax;
                allstats(statsctr).Unit=unit;
                allstats(statsctr).Electrode = electrode;
                
                unit_array(statsctr,1)=allstats(statsctr).Centroid(1);
                unit_array(statsctr,2)=allstats(statsctr).Centroid(2);
                unit_array(statsctr,3)=allstats(statsctr).Orientation_rad;
                unit_array(statsctr,4)=allstats(statsctr).MinorAxisLength;
                unit_array(statsctr,5)=allstats(statsctr).MajorAxisLength;
                unit_array(statsctr,6)=allstats(statsctr).Unit;
                unit_array(statsctr,7)=allstats(statsctr).Electrode;
                
                statsctr = statsctr+1;
                
                %             Session.RT=NaN(size(Session.TargOn));
                %             Session.Spikes{unit}.spike_count=NaN(size(Session.TargOn));
                %             Session.Spikes{unit}.base_spike_count=NaN(size(Session.TargOn));
                %             Session.Spikes{unit}.spike_dur=NaN(size(Session.TargOn));
                %             Session.Spikes{unit}.base_spike_dur=NaN(size(Session.TargOn));
                %
                %             if isobject(f1)
                %                 f1 = f1.Number;
                %             end
                %             Session = Fade_PSTH(Trials,Session,electrode,unit,unit_array,f1);
            end
            
            %         % plot just the saccade endpoints and their associated firing rates
            %         subplot(2,1,2)
            %         sh = scatter(allx,ally,[],firing_rate,'o');
            %         set(sh,'markerfacecolor','flat')
            %         axis([-xwidth xwidth -ywidth ywidth])
            %         hc = colorbar('Peer',gca);
            %         set(get(hc,'ylabel'),'String','Firing rate (Hz = spikes/s)')
            %         xlabel('X Position (degrees)')
            %         ylabel('Y Position (degrees)')
            
        end
    end
    
    if plotflag
        % look at all RFs overlaid
        tpall=tpall./max(max(tpall));
        figure(200);
        set(gcf,'position',[817   244   438   753]);
        subplot(2,1,1)
        colormap(bone);
        imagesc(xvec,yvec,tpall);
        hold on
        plot([0 0],ylim,'w--')
        plot(xlim,[0 0],'w--')
        xlabel('X Position (degrees)')
        ylabel('Y Position (degrees)')
        axis([-40 40 -40 40])
        
        subplot(2,1,2)
        axis([-40 40 -40 40])
        hold on
        plot([0 0],ylim,'k--')
        plot(xlim,[0 0],'k--')
        xlabel('X Position (degrees)')
        ylabel('Y Position (degrees)')
        set(gca, 'Ydir', 'reverse')
    end
end
