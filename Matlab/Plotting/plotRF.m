% [out, h] = plotRF(x,y,fr,varargin)
%
% Inputs    x: vector of x-values.
%           y: vector of y-values.
%           fr: vector of instantaneous or average firing rates
%           varargin: a struct with optional parameters
%                 - xwidth: the width of the plot window (default is to
%                 include all data points)
%                 - ywidth: the height of the plot window (default is to
%                 include all data points)
%                 - filtsize: size of the gaussian filter for smoothing
%                 (default: [3 3])
%                 - filtsigma: standard deviation of the gaussian filter
%                 (default: 0.5)
%                 - plotflag: plot or not (default is yes)
%
% Output    out: a struct with the image matrix, x, and y
%           h: handle to the axes and figure (if plotting is turned on).
%
% DKW, Jan 2016


function [out, h] = plotRF(x,y,fr,varargin)

% varargin default values (varargin is a struct with the following possible fields)
xwidth      = max(abs(x));
ywidth      = max(abs(y));
filtsize    = [10 10];
filtsigma   = 2;
plotflag    = 1;
fig_Handle   = [];
axes_Handle  = [];

Pfields = {'xwidth','ywidth','filtsize','filtsigma','plotflag','fig_Handle','axes_Handle'};
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


%% build the image matrix
% make sure the data fit within the bounds
bound = y>-ywidth & y<ywidth & x>-xwidth & x<xwidth;
y=y(bound);
x=x(bound);
fr=fr(bound);

% create x and y vectors
xvec = -xwidth:xwidth;
yvec = -ywidth:ywidth;
act_map=NaN(length(yvec),length(xvec));


%% smoothing

if 1 % use k-nearest neighbors smoothing algorithm
    % create matrix of saccade/firing rates
    rallx=ceil(x);
    rally=ceil(y);
    % get x,y position of each pixel on the grid
    [xg,yg]=meshgrid(xvec,yvec);
    knn=20; % number of neighbors that will influence each other
    decay=.05; % influence of neighbors decays over distance
    peaks = rf_smooth([rallx(:) rally(:)],[xg(:) yg(:)],fr,decay,knn);
    Ig=reshape(peaks,size(act_map));
    
    G = fspecial('gaussian',filtsize,filtsigma);
    Ig = imfilter(Ig,G,'same');
end



%% fitting RF

% make a white and black mask for plotting later
wmask=cat(3, ones(size(Ig)), ones(size(Ig)), ones(size(Ig)));
bmask=cat(3, zeros(size(Ig)), zeros(size(Ig)), zeros(size(Ig)));

% set the threshold
iz = zscore(Ig(:));
iz_grid = reshape(iz,size(Ig));
iz_sort=sort(iz);
iz_t = iz_sort((end-round(length(iz_sort)*.01)));

% get threshold map and perimeter
mask_alpha=.5;
threshmap_raw = iz_grid<iz_t;
threshmap_raw=threshmap_raw*mask_alpha; % the value at the end determines the alpha value of the mask

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
    [i,j]=ind2sub(size(Ig),roipix(pkdx));
    rfpeaks(arv,:)=[xvec(j) yvec(i)];
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
bad_pix = cat(1,stats(bad_area).PixelIdxList);
threshmap_raw(bad_pix)=mask_alpha;
% draw perimeter around significant regions
tperim=bwperim(~logical(threshmap_raw),8);

%% create output variable
out.image = Ig;
out.x = xvec;
out.y = yvec;
out.fr = fr;
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
    
    out.RF.Centroid = [centx centy];
    out.RF.Peak = [peakx peaky];
    out.RF.Orientation_rad = orient;
    out.RF.MinorAxisLength = minax;
    out.RF.MajorAxisLength = majax;
else
    out.RF.Centroid = [NaN NaN];
    out.RF.Peak = [NaN NaN];
    out.RF.Orientation_rad = NaN;
    out.RF.MinorAxisLength = NaN;
    out.RF.MajorAxisLength = NaN;
end


%% plotting
if plotflag
    if isempty(fig_Handle)
        h.f = figure();
    else
        h.f = fig_Handle;
        figure(h.f);
    end
    if ~isempty(axes_Handle)
        subplot('position',axes_Handle)
        imagesc(xvec,yvec,Ig);
        set(gca,'Ydir','normal')
        hold on
        mh2 = imagesc(xvec,yvec,wmask);
        set(gca,'Ydir','normal')
        mh3 = imagesc(xvec,yvec,bmask);
        set(gca,'Ydir','normal')
        set(mh2, 'AlphaData', threshmap_raw)
        set(mh3, 'AlphaData', tperim)
        
        h.im = axes_Handle;
        h.axes = gca;
    else
        h.im = imagesc(xvec,yvec,Ig);
        set(gca,'Ydir','normal')
        hold on
        mh2 = imagesc(xvec,yvec,wmask);
        set(gca,'Ydir','normal')
        mh3 = imagesc(xvec,yvec,bmask);
        set(gca,'Ydir','normal')
        set(mh2, 'AlphaData', threshmap_raw)
        set(mh3, 'AlphaData', tperim)
        
        h.axes = gca;
    end
    
    cb = colorbar;
    ylabel(cb,'Firing Rate (sp/s)')
    
    hold on
    plot([0 0],ylim,'w--')
    plot(xlim,[0 0],'w--')
    xlabel('Lateral Position (dva)')
    ylabel('Vertical Position (dva)')
else h=NaN;
end