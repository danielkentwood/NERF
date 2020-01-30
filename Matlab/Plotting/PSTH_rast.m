
function [handles,psth] = PSTH_rast(spikeTimes,time_params,varargin)
% TIME_PARAMS is a struct with the following fields.
%     time_params(1).zero_time=0;
%     time_params(1).start_time=-450;
%     time_params(1).end_time=250;
%     time_params(1).dt=5;
%
%     NOTE: there should be as many instances of TIME PARAMS as there are
%     spike trains you want to plot.


% make sure spikeTimes is a cell array of cell arrays
if ~iscell(spikeTimes{1})
    numConds=1;
    spikeTimes = {spikeTimes};
else
    numConds=length(spikeTimes);
end

%% varargin default values (varargin is a struct with the following possible fields)
sep         = .075; % proportion of vertical separation between raster and psth
rasterSpace = .4; % vertical proportion of total plot that the raster takes up
axesDims    = [.15 .15 .7 .7]; % [left bottom width height]
MColor      = [1 0 0; 0 0 1; 0 1 .2; 1 .65 0; .5 .5 0; .2 .2 .2; 1 0 1; .5 .2 1]; % default colormap
errBars     = 1; % to turn psth error bars on and off
useSEs      = 0; % use SEM instead of 95% CI for the psth
smoothflag  = 1; % use smoothing
gauss_sigma = 15;
plotLoc     = [0 0 1 1];
figHand     = NaN;
figTitle    = '';
names       = {};
plotflag    = 1;


Pfields = {'sep', 'rasterSpace', 'axesDims', 'MColor', 'useSEs', 'errBars','smoothflag',...
    'gauss_sigma','plotLoc','figHand','figTitle','names','plotflag'};
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

%% initialize figure
if plotflag
    psthSpace = 1-sep-rasterSpace;
    if isfloat(figHand)
        hf = figure;
    else
        hf = figure(figHand);
    end
    hold on
    psthBounds=[plotLoc(1)+axesDims(1)*plotLoc(3) plotLoc(2)+axesDims(2)*plotLoc(4) ....
        plotLoc(3)*axesDims(3) psthSpace*plotLoc(4)*axesDims(4)];
    rasterBounds=[psthBounds(1) psthBounds(2)+psthSpace*plotLoc(4)*axesDims(4)+...
        sep*plotLoc(4)*axesDims(4) psthBounds(3) rasterSpace*plotLoc(4)*axesDims(4)];
    sp1 = subplot('position',rasterBounds);
    sp2 = subplot('position',psthBounds);
    set(hf, 'color', [1 1 1]);
end

% start looping through conditions
j=0;
for c = 1:numConds
    % get current condition
    pd = time_params(c).pad;
    zt = time_params(c).zero_time;
    st = time_params(c).start_time - pd;
    et = time_params(c).end_time + pd;
    dt = time_params(c).dt;
    
    sTms_rast = [];
    spikeTrains=[];
    
    
    % save category names
    if ~isempty(names)
        psth(c).name = names{c};
    end
    
    % minus padding
    st_pad = st+pd;
    et_pad = et-pd;
    
    % get time vectors
    tv = (st:dt:et)';
    tv_pad = st_pad:dt:et_pad;
    [~,tv_ia,~]=intersect(tv,tv_pad);
    
    % convert spike timestamps to spike train histogram
    sTms = spikeTimes{c};
    % if there are too many spikes for plotting (which can take a long time),
    % randomly sample from each condition.
    max_trains = 4000;
    trains_cut = ceil(max_trains/numConds);
    
    if length(sTms)>trains_cut
        sTms_idx = ceil(rand(1,trains_cut).*length(sTms));
        sTms_rast = sTms(sTms_idx);
    else
        sTms_rast = sTms;
    end
    % Convert timestamps to a spike train vector
    for i=1:length(sTms)
        spikeTrains(i,:) = buildSpikeTrain(sTms{i},zt,st,et,dt);
    end
    
    if ~isempty(spikeTrains)
        if smoothflag
            % convolves a spike train with a
            % gaussian kernel
            sm_gauss = gauss_spTrConvolve( spikeTrains, dt, gauss_sigma );
            sm_mu = mean(sm_gauss).*1000/dt;
        else
            sm_mu = mean(spikeTrains).*1000/dt;
        end
        
        
        % compute the error bars
        if errBars
            if useSEs % use standard error
                sm_err = (repmat(std(spikeTrains)./sqrt(size(spikeTrains,1)),2,1)' .*1000/dt);
                if smoothflag
                    sm_err = (repmat(std(sm_gauss)./sqrt(size(sm_gauss,1)),2,1)' .*1000/dt);
                end
            else % use 95% CI
                sm_err = bootci(1000,@mean,spikeTrains)'.*1000/dt;
                if smoothflag
                    sm_err = (bootci(1000,@mean,sm_gauss)'.*1000/dt);
                end
                sm_err = sm_err-repmat(sm_mu',1,2);
                sm_err(:,2) = sm_err(:,2).*-1;
            end
        else
            sm_err=[];
        end
        
        % remove padding
        sm_mu = sm_mu(tv_ia);
        if ~isempty(sm_err)
            sm_err=sm_err(tv_ia,:);
        end
        
    else
        tv_pad=[];
        sm_mu = [];
        sm_err=[];
    end
    
    
    
    % save psth for output
    psth(c).y = sm_mu;
    psth(c).x = tv_pad;
    
    
    % PLOTTING
    if plotflag
        % add the raster
        subplot(sp1)
        spTs=[];
        ypls=[];
        for t = 1:length(sTms_rast)
            spTimes = sTms_rast{t}';
            spTimes = spTimes(spTimes>st_pad & spTimes<et_pad);
            nsp = length(spTimes);
            ypl = repmat([j; j+.99], 1,  nsp);
            j=j+1;
            spTs = [spTs; spTimes];
            ypls = [ypls ypl];
        end
        plot([spTs'; spTs'], ypls, 'color',MColor(c,:), 'linewidth', 2); hold on;
        xlim([st et])
        
        % keep tabs of how many total rows there are in the raster
        rastRows(c) = size(sTms_rast,2);
        
        % add the psth
        subplot(sp2)
        if errBars
            hold all
            [h(c).l,h(c).p] = boundedline(tv_pad,sm_mu,...
                sm_err*-1,'cmap',MColor(c,:),'alpha');
            set(h(c).l,'linewidth',2);
            % save err for output
            psth(c).err = sm_err*-1;
        else
            hold all
            if smoothflag
                h(c).l = plot(tv_pad,sm_mu,'color',MColor(c,:));
                set(h(c).l,'linewidth',2);
            else
                h(c) = bar(tv_pad,sm_mu,'FaceColor',MColor(c,:),'LineStyle','none');
                h(c).FaceAlpha = 0.2;
            end
        end
    end
end


if plotflag
    % finalize the psth plot
    subplot(sp2); axis tight
    cxlm = get(sp2,'xlim');
    cylm = get(sp2,'ylim');
    axis manual
    set(sp2,'fontsize',12*plotLoc(4));
    set(sp2,'ylim',[cylm(1)-(diff(cylm)*.025) cylm(2)+(diff(cylm)*.025)]);
    ytk = get(sp2,'YTick');
    set(sp2,'tickdir','out','YTick',[ytk(1) ytk(end)],...
        'xlim',cxlm,'XTick',100.*unique(ceil(get(sp2,'XTick')./100)));
    
    ylabel('Spikes/S')
    xlabel('Time (ms)')
    if ~isempty(names)
        lhPSTH = legend([h.l],names,'location','best');
        set(lhPSTH,'box','off','fontsize',10)
    end
    
    % finalize the raster plot
    totalRastRows=sum(rastRows);
    subplot(sp1);
    title(sp1,figTitle);
    axis manual
    set(sp1,'visible', 'off','ylim',[0 totalRastRows],'xlim',cxlm);
    set(findall(sp1, 'type', 'text'), 'visible', 'on')
    
    
    % create the output struct
    handles.raster=sp1;
    handles.psth=sp2;
    handles.lines=h;
    handles.figure=hf;
else
    handles = [];
end







