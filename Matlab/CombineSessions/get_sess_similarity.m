% get session similarity
% make sure you are in a depth folder


%% get session metadata
get_sess_metadata

%% Extract features
sessIDX = 1:length(sessfeatures);
out = extract_features(sessfeatures, sessIDX);




%% Get 2D projection through t-Distributed Stochastic Neighbor Embedding (t-SNE)
% get comparison of multiple different tsne distance algorithms

% how many iterations for the resampling
n_iter = 100;

% setting up a timer
quintile = round(n_iter/5);
step=1;

disp('Getting t-SNE projections...')
for i = 1:n_iter
    tsne_proj(i,:) = compare_tsne_algos(out.spike_wavelet_coeffs);
    if i>quintile*step
        disp([num2str(((quintile*step) / n_iter) * 100) '% complete'])
        step=step+1;
    end
end
disp('Finished with t-SNE')


%% Hierarchical Density-based Clustering 
% https://github.com/Jorsorokin/HDBSCAN

for i = 1:3 % cycle through cosine, chebychev, euclidean
    i
    for ii = 1:size(tsne_proj,1)
 
        clusters = HDBSCAN (tsne_proj{ii,i});
        clusters.minpts        = 1;     % min pts included in distance calculations
        clusters.minclustsize  = 5;     % minimum valid cluster size
        clusters.outlierThresh = 0.8;   % outlier threshold 
        clusters.minClustNum   = 1;     % min number of clusters
        clusters.fit_model(); 			% trains a cluster hierarchy
        clusters.get_best_clusters(); 	% finds the optimal "flat" clustering scheme
        clusters.get_membership();		% assigns cluster labels to the points in X
        
%         clusters.plot_clusters()
%         close all
        
        dist(i).iter(ii).clusterer = clusters;
        
        disp(['distance ' num2str(i) ', iter ' num2str(ii)]) 
    end
end

%% Get group probabilities

num_sess = length(sessIDX);

count_mat = zeros(num_sess,num_sess,length(dist));

for alg = 1:length(dist)
    for it = 1:n_iter
        cur_labels = dist(alg).iter(it).clusterer.labels;
        for i = 1:num_sess
            group = find(cur_labels==cur_labels(i));
            for k = group        
                count_mat(i,k,alg)=count_mat(i,k,alg)+1; 
            end
        end
    end
end

% this is a matrix that represents the probability that a session was
% clustered with any other given session
prob_mat = count_mat./n_iter;
disp('Done computing probabilities')
%% Assign groups
% this loop will, for each distance measure, look for correlations between
% column vectors in the probability matrix. High correlations are an 
% indicator of group membership.
for alg = 1:length(dist)
    
    sess_vec = 1:num_sess;
    labels = zeros(1,num_sess);
    cur_label = 1;
    
    while ~isempty(sess_vec)
        allc = [];
        for i = 1:length(sess_vec)
            allc(i) = corr(prob_mat(:,sess_vec(1),alg),prob_mat(:,sess_vec(i),alg));
        end
        
        % currently hardcoded to accept correlations of above 0.9 as 
        % evidence of group membership.
        curmatch = find(allc>0.9);
        labels(sess_vec(curmatch))=cur_label;
        sess_vec(curmatch)=[];
        cur_label=cur_label+1;
    end
    
    labels_all(alg,:) = labels;
    
end

disp('Done assigning group membership')









%% combine 
% this currently is hardcoded to use the cosine distance algorithm
labels_final = labels_all(1,:)';
sessCombine(sessfeatures,labels_final)




















%% UNUSED CLUSTERING ALGOS

% %% Cluster with Gaussian Mixture Model
% 
% X = tsne_proj{3};
% gm = fitgmdist(X,3);
% threshold = [0.4 0.6];
% P = posterior(gm,X);
% 
% idx = cluster(gm,X);
% P>=threshold(1) & P<=threshold(2)
% idxBoth = find(P(:,1)>=threshold(1) & P(:,1)<=threshold(2)); 
% numInBoth = numel(idxBoth);
% 
% figure
% gscatter(X(:,1),X(:,2),idx,'rbg','+ox',5)
% hold on
% plot(X(idxBoth,1),X(idxBoth,2),'ko','MarkerSize',10)
% legend({'Cluster 1','Cluster 2','Both Clusters'},'Location','SouthEast')
% title('Scatter Plot - GMM with Full Unshared Covariances')
% hold off
% 
% %% Cluster with K means
% opts = statset('Display','final');
% % choose which algorithm to use
% X = tsne_proj{2};
% num_clus = 7;
% 
% 
% [idx,C] = kmeans(X, num_clus,'Distance','cosine',...
%     'Replicates',5,'Options',opts);
% 
% cols = 'bkrgcmy';
% shapes = '+o*.xsd';
% figure();
% gscatter(X(:,1),X(:,2),idx,cols(1:num_clus),shapes(1:num_clus),5)
% title 'Cluster Assignments'
% % hold off