function sm_gauss = gauss_spTrConvolve(spikeTrains,dt,sigma)

% create the kernel
edges = (-3*sigma:dt:3*sigma);
kernel = normpdf(edges,0,sigma);
kernel = kernel.*dt;
% find the index of the kernel center
center = floor(length(edges)/2);

% do the convolution
for i = 1:size(spikeTrains,1)
    st = conv(spikeTrains(i,:),kernel);
    sm_gauss(i,:) = st(center:end-center-1);
end



