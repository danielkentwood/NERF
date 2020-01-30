function PSTH = radial_PStimTH(Trials, varargin)

if ispc
    opengl software % use openGL software rather than hardware (since you are using alpha transparency and this isn't compatible with openGL hardware currently)
end

%% varargin default values (varargin is a struct with the following possible fields)
sep         = .075; % proportion of vertical separation between raster and psth
rasterSpace = .4; % vertical proportion of total plot that the raster takes up
axesDims    = [.15 .15 .7 .7]; % [left bottom width height]
MColor      = [1 0 0; 0 0 1; 0 1 .2; 1 .65 0; .5 .5 0; .2 .2 .2; 1 0 1; .5 .2 1]; % default colormap
errBars     = 1; % to turn psth error bars on and off
useSEs      = 0; % use SEM (1) or 95% CI (0) for the psth
smoothflag  = 1; % use smoothing
gauss_sigma = 10;
plotLoc     = [0.05 0 .43 1];
figLoc      = [221 111 1365 769];
figHand     = NaN;
figTitle    = '';
names       = {};
plotflag    = 1;



Pfields = {'sep', 'rasterSpace', 'axesDims', 'MColor', 'useSEs', 'errBars','smoothflag',...
    'gauss_sigma','plotLoc','figLoc','figHand','figTitle','names','plotflag'};
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



% set trode and unit
electrode = find(~cellfun(@isempty,{Trials(1).Electrodes.Units}));
unit = 1;

% temporal parameters
dt = 5;
pad = 50;
time_before = 100;
time_after = 500;

ind = 1;
% get trial-level info
for trial = 1:length(Trials)
    ecodes = [Trials(trial).Events(:).Code];
    
    % get target angle
    tx = Trials(trial).Target.x;
    ty = Trials(trial).Target.y;
    targ_angle = atan2d(ty,tx);
    targ_angle(targ_angle<0)=targ_angle(targ_angle<0)+360;
    data_struct(ind).angle = targ_angle;
    
    % target onset
    times = [Trials(trial).Events.Time];
    targ_on = times(ecodes==4020);
    t_targ_on = double(targ_on(1));
    
    % get neural data
    vis_temp = {[Trials(trial).Electrodes(electrode).Units(unit).Times] - t_targ_on};
    data_cells{ind}=vis_temp{1}';
    ind = ind + 1;
end

% bin by angle
numbins=8;
bin_edges=linspace(0,360,numbins+1);
[n_ang,bin_edges,ang_bins]=histcounts([data_struct.angle],bin_edges);

time_params(1).zero_time=0;
time_params(1).start_time=-time_before;
time_params(1).end_time=time_after;
time_params(1).dt=dt;
time_params(1).pad = 40;
time_params(2:numbins)=time_params(1);

other_params.errBars=errBars;
other_params.useSEs=useSEs;
other_params.smoothflag=smoothflag;
other_params.gauss_sigma = gauss_sigma;
other_params.plotLoc = plotLoc;
other_params.figHand = figHand;
other_params.plotflag = plotflag;
other_params.figTitle = figTitle;

for tb = 1:numbins
    other_params.names{tb}=[num2str(bin_edges(tb)) '-' num2str(bin_edges(tb+1))];
    all_spikes2{tb}=data_cells(ang_bins==tb);
end

PSTH.electrode(electrode).unit(unit).data = PSTH_rast(all_spikes2,time_params,other_params);
set(gcf,'position',figLoc)
        
        
        




