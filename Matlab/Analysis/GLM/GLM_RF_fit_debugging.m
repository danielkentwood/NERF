% debugging the GLM fitting
clear


% initialize the gaussian masks
N=6; % N^2 is the number of gaussians that fit into the workspace
P=[48 36]; % P is the dimensions of the workspace
G = compute_gaussian_masks(P, N, 'xy');

% here I'm choosing one of the masks as the "RF" I want to fit, and I'm
% adding a bit of noise
tst=G(:,:,8).*(rand(P)'.*.5+1);
% now add noise to the rest of the image
tst = tst+rand(size(tst)).*.5+1;
% show our constructed RF
figure()
imagesc(tst)

% get weight vector W and firing rates
num_trials = 100; % num trials (i.e., probes)
for q = 1:num_trials
    % randomly select a "probe" location
    cdx = randi(P(1)*P(2),1);
    [cdi,cdj]=ind2sub(size(tst),cdx);
    % get a "probe"-sized square around that location
    cj = max(1,(cdj-3)):min(P(1),(cdj+3)); 
    ci = max(1,(cdi-3)):min(P(2),(cdi+3)); 
        
    for wv = 1:size(G,3)
        % for each basis function, take the mean of that probe location
        fixW(q,wv) = mean(mean(G(ci,cj,wv)));
    end
    % take the firing rate from the simulated RF map
    fr(q)=mean(mean(tst(ci,cj)));
end

%% RUN GLMNET
options = glmnetSet;
options.nlambda = 5;
fit = glmnet(fixW,fr','gaussian',options);
B = fit.beta;
intercept = fit.a0;
clear mex
figure(225)
% format output of model
if 1 % visualize all lambdas
    for bi = 1:size(B,2)
        which_lambda = bi; % the third lambda (when numlambda is set to 5) seems to work best
        fW = B(1:N^2,which_lambda); % If the spatial basis functions (SBFs) are 5 x 5, the first 25 rows correspond to the first predictor (probe-weight SBFs), next 25 are second predictor (saccade-weighted SBFs)
        tmpf = repmat(shiftdim(fW', -1), [size(G,1), size(G,2), 1]); % Assign each basis function its weight
        Ig = intercept(which_lambda)+ sum(G.*tmpf, 3); % Here, we add the intercept to the activity map.
        outimage(:,:,bi)=Ig;
        
        
        figure(225)
        subplot(2,ceil(size(B,2)/2),bi)
        imagesc(Ig)
        title(num2str(bi))
    end
end
hold off



%% RUN GLMFIT
figure(226)
% run the GLM
[B2,dev,stats] = glmfit(fixW,fr,'poisson');

% visualize
fW = B2(2:(2+size(G,3)-1));
tmpf = repmat(shiftdim(fW', -1), [size(G,1), size(G,2), 1]);
fR = sum(G.*tmpf, 3);
fR = fR./max(fR(:));


subplot(1,2,1)
imagesc(tst)
title('simulated RF')
subplot(1,2,2)
imagesc(fR)
title('fitted RF')