% get_remap_measures
function remapRF = get_remap_measures(remapRF, preRF)

pRFdist = preRF.pRFdist;
Prf  = preRF.RF_axis_coeff;
psxm = preRF.RFx;
psym = preRF.RFy;

for i = 1:length(remapRF.RF)
    % get xy of RF peak
    peak(i,:) = remapRF.RF(i).RF.Peak;
    % get true distance from sacc endpoint
    true_dist = sqrt(peak(i,1)^2 + peak(i,2)^2);
    remapRF.RF(i).true_dist = true_dist;
    % get ratio of true distance
    td_ratio = true_dist / pRFdist;
    remapRF.RF(i).true_distance_ratio = td_ratio;
    
    % get distance traveled down axis and deviation from axis
    % first, get slope of a line that intersects axis
    if Prf(1)==0
        Prf(1)=0.00000000000001;
    end
    int_slope = -1/Prf(1);
    % now, make sure it passes through the remap RF peak
    int_slope(2) = peak(i,2)-int_slope(1)*peak(i,1);
    % now, get the point of intersection
    Cx = (int_slope(2)-Prf(2)) / (Prf(1)-int_slope(1));
    Cy = Prf(1)*Cx + Prf(2);
    
    % get intersection distance from presaccadic RF
    axis_distance = sqrt((Cx-psxm)^2 + (Cy-psym)^2);
    % get directionality of axis_distance
    % get intersection distance from sacc endpoint
    Cdist = sqrt((Cx-peak(i,1))^2 + (Cy-peak(i,2))^2);
    distdiff = Cdist-pRFdist;
    if distdiff>0 && axis_distance<(pRFdist*2)
        axis_distance = -axis_distance;
    end
    remapRF.RF(i).axis_distance = axis_distance;
    ad_ratio = axis_distance / pRFdist;
    remapRF.RF(i).axis_distance_ratio = ad_ratio;
    
    % get deviation
    deviation = sqrt((peak(i,1)-Cx)^2 + (peak(i,2)-Cy)^2);
    if peak(i,2)<Cy || (peak(i,2)==Cy && peak(i,1)<Cx)
        deviation = -deviation;
    end
    remapRF.RF(i).deviation = deviation;
    
    % plot to check if this is working
    if 0
        hold off
        imagesc(remapRF.RF(i).x, remapRF.RF(i).y, remapRF.RF(i).image)
        set(gca,'ydir','normal')
        hold on
        plot([-30 30],polyval(Prf,[-30 30]))
        plot([-30 30],polyval(int_slope,[-30 30]))
        plot(0,0,'k.','markersize',15)
        plot(peak(i,1), peak(i,2), 'ko', 'linewidth',4)
        plot(psxm, psym, 'ro','linewidth',4)
        plot(Cx,Cy,'mo','linewidth',4)
        axis([-30 30 -20 20])
        hold off
        drawnow
        pause(0.2)
    end
end



dev = [remapRF.RF.deviation];
adr = [remapRF.RF.axis_distance_ratio];
X = [dev' adr'];
X(any(isnan(X')),:)=[];

% I THINK HDBSCAN IS NOT THE IDEAL ALGORITHM FOR THIS. 
if size(X,1)>10
    % Use Hierarchical Density-based Clustering to identify stable RFs
    clusterer = HDBSCAN( X );
    clusterer.minpts        = 5;
    clusterer.minclustsize  = 4;
    clusterer.outlierThresh = 0.8;
    clusterer.minClustNum   = 1;
    clusterer.fit_model(); 			% trains a cluster hierarchy
    clusterer.get_best_clusters(); 	% finds the optimal "flat" clustering scheme
    clusterer.get_membership();		% assigns cluster labels to the points in X
    
    % get the average of the clusters that reach a threshold for the number of
    % samples in a cluster
    % find label for non-clustered data points
    u_clust = unique(double(clusterer.labels));
    % clusterer.P defines the probability that the sample is a member of
    % the corresponding group label in clusterer.labels. Below, we simply
    % remove a sample if there is 0 probability that it is a member of the
    % group it was assigned to.
    bad_cluster = unique(clusterer.labels(clusterer.P==0));
    hc = histcounts(double(clusterer.labels));
    hc(hc==0)=[];
    if ~isempty(bad_cluster)
        hc(u_clust==bad_cluster)=[];
        u_clust(u_clust==bad_cluster)=[];
    end
    
    [hc_s,hc_sidx]=sort(hc,'descend');
    hc_cutoff = 5;
    hc_keep = u_clust(hc_sidx((hc_s>hc_cutoff)));
    for i = 1:length(hc_keep)
        cur_group = hc_keep(i);
        cur_data = clusterer.data(clusterer.labels==cur_group,:);
        cur_med = nanmean(cur_data);
        
        RFxy_keep(i,:)=cur_med;
    end
    
    if 0
        % plot
        figure()
        clusterer.plot_clusters();
        hold on
        plot(RFxy_keep(1,1), RFxy_keep(1,2), 'ko','linewidth',3)
        hold off
    end
    
    remapRF.RFxy_keep = RFxy_keep;
else
    remapRF.RFxy_keep = [NaN NaN];
end





