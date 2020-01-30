function Y = compare_tsne_algos(features)

% from: https://www.mathworks.com/help/stats/tsne.html

plotflag = 0;

if plotflag
    figure()
end

% if all(abs(sum(features))>0) && size(features,1)>=size(features,2)
% %     rng('default') % for fair comparison
%     Y{1} = tsne(features,'Algorithm','exact','Distance','mahalanobis');
%     subplot(2,2,1)
%     gscatter(Y{1}(:,1),Y{1}(:,2))
%     title('Mahalanobis')
% end

% rng('default') % for fair comparison
Y{1} = tsne(features,'Algorithm','exact','Distance','cosine');
if plotflag
    subplot(2,2,2)
    gscatter(Y{2}(:,1),Y{2}(:,2))
    title('Cosine')
end

% rng('default') % for fair comparison
Y{2} = tsne(features,'Algorithm','exact','Distance','chebychev');
if plotflag
    subplot(2,2,3)
    gscatter(Y{3}(:,1),Y{3}(:,2))
    title('Chebychev')
end

% rng('default') % for fair comparison
Y{3} = tsne(features,'Algorithm','exact','Distance','euclidean');
if plotflag
    subplot(2,2,4)
    gscatter(Y{4}(:,1),Y{4}(:,2))
    title('Euclidean')
end