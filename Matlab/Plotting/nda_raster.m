function nda_raster(spikeTimes,time_params,varargin)

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
plotLoc     = [0 0 1 1];
figHand     = NaN;
figTitle    = '';
names       = {};


Pfields = {'axesDims', 'MColor','plotLoc','figHand','figTitle','names'};
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
if isfloat(figHand)
    hf = figure;
else
    hf = figure(figHand);
end
hold on

rasterBounds=[plotLoc(1)+axesDims(1)*plotLoc(3) plotLoc(2)+axesDims(2)*plotLoc(4) ....
    plotLoc(3)*axesDims(3) plotLoc(4)*axesDims(4)];
sp1 = subplot('position',rasterBounds);
set(hf, 'color', [1 1 1]);

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
    
    % convert spike timestamps to spike train histogram
    sTms = spikeTimes{c};
    spikeTrains = buildSpikeTrain(sTms,zt,st,et,dt);
    sm_raw = spikeTrains;
    
    % add the raster
    subplot(sp1)
    for t = 1:length(sTms)
        spTimes = sTms{t}';
        spTimes = spTimes(spTimes>st & spTimes<et);
        nsp = length(spTimes);
        ypl = repmat([j; j+.9], 1,  nsp);
        j=j+1;
        plot([spTimes'; spTimes'], ypl, 'color',MColor(c,:), 'linewidth', 1); hold on;
    end
    xlim([st et])
    % keep tabs of how many total rows there are in the raster
    rastRows(c) = size(sm_raw,1);
end

% finalize the raster plot
totalRastRows=sum(rastRows);
subplot(sp1);
axis manual
cxlm = get(sp1,'xlim');
set(sp1,'visible', 'off','ylim',[0 totalRastRows],'xlim',cxlm);

% create the output struct
handles.raster=sp1;
handles.figure=hf;







