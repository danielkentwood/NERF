function out = probes_RF_estimate(probe,curUnit,varargin)



%% set default parameters
% varargin default values (varargin is a struct with the following possible fields)
xwidth      = 30;
ywidth      = 20;
filtsize    = [20 20];
filtsigma   = 2.5;
zscore_out  = 1;
standard_caxis = 1;
earliest    = -50;
latest      = 25;
windowsize  = 12.5;
wind_inc    = 12.5;
plotflag    = 1;
timeLock    = 'fix';
spaceLock   = 'fix1';
def_RF      = [0 0];
estimator   = 'PTA'; % 'PTA' (probe triggered average) or 'GLM'

Pfields = {'xwidth','ywidth','filtsize','filtsigma','zscore_out','standard_caxis',...
    'earliest','latest','windowsize','wind_inc','plotflag','timeLock','spaceLock','def_RF','estimator'};
for i = 1:length(Pfields) % if a params structure was provided as an input, change the requested fields
    if ~isempty(varargin)&&isfield(varargin{1}, Pfields{i}), eval(sprintf('%s = varargin{1}.(Pfields{%d});', Pfields{i}, i)); end
end
if ~isempty(varargin)  % if there is a params input
    fnames = fieldnames(varargin{1}); % cycle through field names and make sure all are recognized
    for i = 1:length(fnames)
        recognized = max(strcmp(fnames{i},Pfields));
        if recognized == 0, fprintf('fieldname %s not recognized\n',fnames{i}); end
    end
end



%% build firing rate, time, and x,y vectors
all_fr = probe.units(:,curUnit);

if strcmp(timeLock,'fix')
    t_lock = probe.t_fix_lock;
elseif strcmp(timeLock,'sac1start')
    t_lock = probe.t_sacc_start_lock;
elseif strcmp(timeLock,'sac1end')
    t_lock = probe.t_sacc_end_lock;
elseif strcmp(timeLock,'sac2end')
    t_lock = probe.t_sacc_nextEnd_lock;
end
if strcmp(spaceLock,'fix1')
    px = probe.x_probe-probe.x_curFix;
    py = probe.y_probe-probe.y_curFix;
elseif strcmp(spaceLock,'fix2')
    px = probe.x_probe-probe.x_oneFixAhead;
    py = probe.y_probe-probe.y_oneFixAhead;
elseif strcmp(spaceLock,'fix3')
    px = probe.x_probe-probe.x_twoFixAhead;
    py = probe.y_probe-probe.y_twoFixAhead;
end

% get saccade vectors
sx = probe.x_oneFixAhead-probe.x_curFix;
sy = probe.y_oneFixAhead-probe.y_curFix;

%% Now build the RF maps
% you can change these or make them arguments for the function
% this will determine the width and number of windows you get in your plot
start_times=earliest:wind_inc:latest;
end_times=start_times+windowsize;

% set parameters for spatial smoothing during inferTuning.m
params.xwidth=xwidth;
params.ywidth=ywidth;
params.filtsize=filtsize;
params.filtsigma=filtsigma;

% run probe-triggered averaging
if strcmp(estimator,'PTA')
    %     if plotflag,fa=figure;end
    for i=1:length(start_times)
        curprobes = t_lock>=start_times(i) & t_lock<=end_times(i);
        fixX = px(curprobes);
        fixY = py(curprobes);
        fr = all_fr(curprobes);
        
        %         if plotflag
        %             params.fig_Handle=fa;
        %             params.axes_Handle=subplot(1,length(start_times),i);
        %         end
        params.plotflag=0;
        outtemp1=inferTuning(fixX,fixY,fr,params);
        outimage(:,:,i)=outtemp1.image;
        outtemp2.timeBin = [start_times(i) end_times(i)];
        outtemp2.timeLock = timeLock;
        outtemp2.spaceLock = spaceLock;
        
        pairs = [fieldnames(outtemp1),struct2cell(outtemp1);fieldnames(outtemp2),struct2cell(outtemp2)]';
        out(i)=struct(pairs{:});
    end
    
    % run GLM
elseif strcmp(estimator,'GLM')
    
    % decide on the resolution of the spatial basis functions
    % create a PxP pixel sheet tiled by NxN gaussians
    N=6;
    P=[xwidth*2+1 ywidth*2+1];
    xvec = -floor(P(1)/2):(-floor(P(1)/2)+(P(1)-1));
    yvec = -floor(P(end)/2):(-floor(P(end)/2)+(P(end)-1));
    
    % how big should the probes be?
    prbSz=3;
    
    for i=1:length(start_times)
        % initialize the gaussian masks
        G = compute_gaussian_masks(P, N, 'xy');
        
        % separate out the probes for this epoch
        % then define xy for probes and saccades
        curprobes = t_lock>=start_times(i) & t_lock<=end_times(i);
        fixX = round(px(curprobes));
        fixY = round(py(curprobes));
        sacX = round(sx(curprobes));
        sacY = round(sy(curprobes));
        fr = all_fr(curprobes);
        
        % make sure all the xy data fit within the workspace
        bound = fixY>-P(end)/2 & fixY<P(end)/2 & fixX>-P(1)/2 & fixX<P(1)/2 ...
            & sacY>-P(end)/2 & sacY<P(end)/2 & sacX>-P(1)/2 & sacX<P(1)/2;
        fixX=fixX(bound)+P(1)/2;
        fixY=fixY(bound)+P(end)/2;
        sacX=sacX(bound)+P(1)/2;
        sacY=sacY(bound)+P(end)/2;
        fr=fr(bound);
        
        % get weight vectors from spatial basis functions and probe/saccade locations
        fixW=[];sacW=[];
        for q = 1:length(fr)
            fX = round(max(1,(fixX(q)-prbSz))):floor(min(P(1),(fixX(q)+prbSz)));
            fY = round(max(1,(fixY(q)-prbSz))):floor(min(P(end),(fixY(q)+prbSz)));
            sX = round(max(1,(sacX(q)-prbSz))):floor(min(P(1),(sacX(q)+prbSz)));
            sY = round(max(1,(sacY(q)-prbSz))):floor(min(P(end),(sacY(q)+prbSz)));
            for wv = 1:size(G,3)
                fixW(q,wv) = mean(mean(G(fY,fX,wv)));
                sacW(q,wv) = mean(mean(G(sY,sX,wv)));
            end
        end
        
        % fit the model
        % random forest
        %         Mdl = TreeBagger(100,[fixW sacW],fr,'OOBPredictorImportance','On','Method','Regression');
        %         PredImport = Mdl.OOBPermutedPredictorDeltaError;
        %         fW = PredImport(1:25)';
        %         tmpf = repmat(shiftdim(fW', -1), [size(G,1), size(G,2), 1]);
        %         Ig = sum(G.*tmpf, 3);
        %         outimage(:,:,i)=Ig;
        
        % GLMnet
        options = glmnetSet;
        options.nlambda = 10;
        fit = glmnet([fixW sacW],fr,'gaussian',options);
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
                outimage(:,:,i)=Ig;
                
                
                figure(225)
                subplot(2,(size(B,2)/2),bi)
                imagesc(Ig)
                title(num2str(bi))
            end
        end
        hold off
        
        which_lambda = 5; % the third lambda (when numlambda is set to 5) seems to work best
        fW = B(1:N^2,which_lambda); % If the spatial basis functions (SBFs) are 5 x 5, the first 25 rows correspond to the first predictor (probe-weight SBFs), next 25 are second predictor (saccade-weighted SBFs)
        tmpf = repmat(shiftdim(fW', -1), [size(G,1), size(G,2), 1]); % Assign each basis function its weight
        Ig = intercept(which_lambda)+ sum(G.*tmpf, 3); % Here, we add the intercept to the activity map.
        outimage(:,:,i)=Ig;
        
        % %         % Lasso GLM
        %         disp('Fitting lasso GLM...')
        %          [B,FitInfo] = lassoglm([fixW sacW],fr,'normal','NumLambda',5);
        % %         [B,FitInfo] = lassoglm([fixW sacW],fr,'normal');
        %         % format output of model
        %         which_lambda = 3; % the third lambda (when numlambda is set to 5) seems to work best
        %         fW = B(1:N^2,which_lambda); % If the spatial basis functions (SBFs) are 5 x 5, the first 25 rows correspond to the first predictor (probe-weight SBFs), next 25 are second predictor (saccade-weighted SBFs)
        %         tmpf = repmat(shiftdim(fW', -1), [size(G,1), size(G,2), 1]); % Assign each basis function its weight
        %         Ig = FitInfo.Intercept(which_lambda)+ sum(G.*tmpf, 3); % Here, we add the intercept to the activity map.
        %         outimage(:,:,i)=Ig;
        
        % get peak
        [mx,mdx]=max(Ig(:));
        [ppy,ppx]=ind2sub(size(Ig),mdx);
        
        
        % set the threshold
        iz = zscore(Ig(:));
        iz_grid = reshape(iz,size(Ig));
        iz_sort=sort(iz);
        iz_t = iz_sort((end-round(length(iz_sort)*.01)));
        
        % get threshold map and perimeter
        threshmap_raw = iz_grid<iz_t;
        
        % get stats on the regions that pass threshold
        stats=regionprops(~logical(threshmap_raw),'centroid','area','PixelIdxList','orientation','MajorAxisLength','MinorAxisLength');
        centroids = cat(1,stats.Centroid);
        areas = cat(1,stats.Area);
        
        % discard regions with area less than some threshold
        area_thresh=10;
        % first get max area
        [max_area,midx]=max(areas);
        % get mean activity values for each region
        for arv = 1:length(areas)
            roipix = stats(arv).PixelIdxList;
            mu_act(arv)=nanmean(Ig(roipix));
            [pkval,pkdx]=max(Ig(roipix));
            [ii,j]=ind2sub(size(Ig),roipix(pkdx));
            rfpeaks(arv,:)=[xvec(j) yvec(ii)];
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
        rfpeaks(bad_area,:)=[];
        
        if ~isempty(centroids)
            centx=(centroids(1)-xwidth-1);
            centy=(centroids(2)-ywidth-1);
            peakx=rfpeaks(1);
            peaky=rfpeaks(2);
            if ~isempty(good_area)
                orient = deg2rad(stats(good_area).Orientation);
                minax = stats(good_area).MinorAxisLength*.7;
                majax = stats(good_area).MajorAxisLength*.7;
            else
                orient=NaN;
                minax=NaN;
                majax=NaN;
            end
            
            out(i).RF.Centroid = [centx centy];
            out(i).RF.Peak = [peakx peaky];
            out(i).RF.Orientation_rad = orient;
            out(i).RF.MinorAxisLength = minax;
            out(i).RF.MajorAxisLength = majax;
        else
            out(i).RF.Centroid = [NaN NaN];
            out(i).RF.Peak = [ppx ppy];
            out(i).RF.Orientation_rad = NaN;
            out(i).RF.MinorAxisLength = NaN;
            out(i).RF.MajorAxisLength = NaN;
        end
        
        out(i).image = flipud(Ig);
        out(i).x = xvec;
        out(i).y = yvec;
        out(i).timeBin = [start_times(i) end_times(i)];
        out(i).timeLock = timeLock;
        out(i).spaceLock = spaceLock;
    end
end


%% option to transform to z scores
if zscore_out
    z_s = nanzscore(outimage(:));
    smin=min(z_s);smax=max(z_s);
    outimage_final = reshape(z_s,size(outimage));
else
    smin=min(outimage(:));smax=max(outimage(:));
    outimage_final = outimage;
end

%% plotting
if plotflag
    load RF_colormap
    figure();
    
    if isnan(min(smin)),smin(1)=0;end
    if isnan(max(smax)),smax(1)=0;end
    for i=1:length(start_times)
        subplot(1,length(start_times),i)
        imagesc(out(i).x,out(i).y,outimage_final(:,:,i));
        hold on
        plot(out(i).RF.Peak(1),out(i).RF.Peak(2),'k.','markersize',10)
        plot(out(i).RF.Centroid(1),out(i).RF.Centroid(2),'kx','markersize',10)
        plot([0 0],ylim,'w--')
        plot(xlim,[0 0],'w--')
        addScreenFrame([48 36],[1 1 1])
        title([num2str(start_times(i)) '-' num2str(end_times(i)) ' ms'])
        % standardize color axis across all images
        if standard_caxis
            caxis([min(smin) max(smax)])
        end
        
        colormap(gca,mycmap)
    end
    subplot(1,length(start_times),1)
    colorbar('position',[0.1 0.1 .01 .8])
    set(gcf,'position',[0         416        min([250*length(start_times)],1900)         182])
end

