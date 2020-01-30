function [psth,handles] = nda_PSTH(spikeTimes,time_params,varargin)

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
axesDims    = [.15 .15 .7 .7]; % [left bottom width height]
MColor      = [1 0 0; 0 0 1; 0 1 .2; 1 .65 0; .5 .5 0; .2 .2 .2; 1 0 1; .5 .2 1]; % default colormap
errBars     = 1; % to turn psth error bars on and off
useSEs      = 0; % use SEM instead of 95% CI for the psth
smoothflag  = 1; % use smoothing
smoothtype  = 'gauss'; % can be either 'gauss' or 'spline'
gauss_sigma = 15;
splineOrder = 35; % for smoothing the psth with a spline
plotLoc     = [0 0 1 1];
buffer      = 100; % 100 ms buffer to avoid artifacts at the end of the PSTH
figHand     = NaN;
figTitle    = '';
names       = {};
plotflag    = 1;


Pfields = {'axesDims', 'MColor', 'useSEs','splineOrder', 'errBars','smoothflag','smoothtype',...
    'gauss_sigma','plotLoc','buffer','figHand','figTitle','names','plotflag'};
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

%% plot figure
if plotflag
    if isfloat(figHand)
        hf = figure;
    else
        hf = figure(figHand);
    end
    hold on
    
    psthBounds=[plotLoc(1)+axesDims(1)*plotLoc(3) plotLoc(2)+axesDims(2)*plotLoc(4) ....
        plotLoc(3)*axesDims(3) plotLoc(4)*axesDims(4)];
    sp2 = subplot('position',psthBounds);
    set(hf, 'color', [1 1 1]);
end

% start looping through conditions
j=0;
for c = 1:numConds
    % get current condition
    zt = time_params(c).zero_time;
    st = time_params(c).start_time;
    et = time_params(c).end_time;
    dt = time_params(c).dt;
    
    % get time vector
    tv = (st:dt:et)';
    tv_buff = (st-buffer:dt:et+buffer)';
    
    % convert spike timestamps to spike train histogram
    sTms = spikeTimes{c};
    spikeTrains = buildSpikeTrain(sTms,zt,st-buffer,et+buffer,dt);
    
    % compute the mean spike
    if smoothflag
        switch smoothtype
            case 'spline' % THIS IS CURRENTLY NOT WORKING. NOT SURE WHERE THE LSSPLINESMOOTH FUNCTION COMES FROM
                sm_raw = spikeTrains;
                sm_mu = mean(sm_raw,1).*1000/dt;
                sm_mu = lsSplineSmooth(tv,sm_mu,splineOrder)';
                sm_mu = sm_mu(tv_buff>=st & tv_buff<=et);
            case 'gauss'
                % create a function that convolves a spike train with a
                % gaussian kernel
                sm_gauss = gauss_spTrConvolve( spikeTrains, dt, gauss_sigma );
                sm_mu = mean(sm_gauss,1).*1000/dt;
                sm_mu = sm_mu(tv_buff>=st & tv_buff<=et);
        end
    end
    
    % compute the error bars
    if errBars
        if useSEs % use standard error
            if size(spikeTrains,1)==1
                sm_err = repmat(sm_mu,2,1)';
            elseif smoothflag
                switch smoothtype
                    case 'spline'
                        sm_err = repmat(lsSplineSmooth(tv,std(sm_raw)./sqrt(size(sm_raw,1)),splineOrder),2,1)' .*1000/dt;
                        sm_err = sm_err(tv_buff>=st & tv_buff<=et,:);
                    case 'gauss'
                        sm_err = repmat(std(sm_gauss)./sqrt(size(sm_gauss,1)),2,1)' .*1000/dt;
                        sm_err = sm_err(tv_buff>=st & tv_buff<=et,:);
                end
            end
        else % use 95% CI
            if size(spikeTrains,1)==1
                sm_err = repmat(sm_mu,2,1)';
            elseif smoothflag
                switch smoothtype
                    case 'spline'
                        sm_err = lsSplineSmooth(tv,bootci(1000,@mean,sm_raw)',splineOrder)' .*1000/dt;
                        sm_err = sm_err(tv_buff>=st & tv_buff<=et,:);
                    case 'gauss'
                        sm_err = bootci(1000,@mean,sm_gauss)'.*1000/dt;
                        sm_err = sm_err(tv_buff>=st & tv_buff<=et,:);
                end
            end
            sm_err = sm_err-repmat(sm_mu',1,2);
            sm_err(:,2) = sm_err(:,2).*-1;
        end
    end
    
    if plotflag
        % add the psth
        subplot(sp2)
        if errBars
            hold all
            [h(c).l,h(c).p] = boundedline(tv,sm_mu,...
                sm_err*-1,'cmap',MColor(c,:),'alpha');
        else
            hold all
            h(c).l = plot(tv,sm_mu,'color',MColor(c,:));
        end
        set(h(c).l,'linewidth',2);
    end
    
    psth(c).time = tv;
    psth(c).data = sm_mu;
end

if plotflag
    % finalize the psth plot
    subplot(sp2); axis tight
    cxlm = get(sp2,'xlim');
    cylm = get(sp2,'ylim');
    axis manual
    set(sp2,'fontsize',12*plotLoc(4));
    set(sp2,'ylim',[cylm(1)-(diff(cylm)*.025) cylm(2)+(diff(cylm)*.025)]);
    set(sp2,'tickdir','out','YTick',[0 10.*max(unique(round(get(sp2,'YTick')./10)))],...
        'xlim',cxlm,'XTick',100.*unique(ceil(get(sp2,'XTick')./100)));
    ylabel('Spikes/S')
    xlabel('Time (ms)')
    title(figTitle);
    if ~isempty(names)
        lhPSTH = legend([h.l],names,'location','best');
        set(lhPSTH,'box','off')
    end
    
    % create the outputs
    handles.psth=sp2;
    handles.lines=h;
    handles.figure=hf;
else
    handles=NaN;
end







