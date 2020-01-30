function [ y_u ] = rf_smooth( x_k, x_u, y_k, decay, knn )

%Inputs:
%x_k is the locations of known points
%x_u is the location of unknown points (that we're trying to estimate)
%y_k is the value (firing rate) at known points
%decay is decay parameter for smoothing
%knn is number of nearest neighbors to look at

%Outputs:
%y_u is the value (firing rate) at unknown points

%1. Decide area of space to look at
%Either based on KNN, or an absolute distance

if knn==0 %Use all data points
    knn=size(y_k,1);
end

%2. Decide weighting of points
%Probably 1/d, but maybe 1/d^2 (or could even be equal weighting)


% [D,idx]=pdist2(x_k,x_u,'euclidean','Smallest',knn);
% 
% const=1; %In case distance is 0
% weights=(D+const).^decay; %How much to weight each point based on their distances from the unknown point
% y_u=mean(weights.*y_k(idx),1)./sum(weights,1);
% y_u=y_u';



[idx,D]=knnsearch(x_k,x_u,'K',knn); %idx and D are both size #unknown points x knn

const=1; %In case distance is 0
weights=(D+const).^decay; %How much to weight each point based on their distances from the unknown point
y_u=sum(weights.*y_k(idx),2)./sum(weights,2);

