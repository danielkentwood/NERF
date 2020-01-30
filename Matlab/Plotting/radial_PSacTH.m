function PSTH = radial_PSacTH(Trials, varargin)

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
gauss_sigma = 15;
plotLoc     = [0.55 0 .43 1];
figHand     = 100;
figLoc      = [221 111 1365 769];
figTitle    = '';
names       = {};
plotflag    = 1;
plot_type   = 'single'; % other option is 'subplots'
angle_type  = 'saccade'; % other option is 'target'


Pfields = {'sep', 'rasterSpace', 'axesDims', 'MColor', 'useSEs', 'errBars','smoothflag',...
    'gauss_sigma','plotLoc','figHand','figLoc','figTitle','names','plotflag','plot_type','angle_type'};
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
time_before = 500;
time_after = 500;

ind = 1;
for trial = 1:length(Trials)
    curtrial= Trials(trial);
    
    for saccade_num = 1:length(curtrial.Saccades)
        
        cursacc = curtrial.Saccades(saccade_num);
        
        % get saccade angle
        switch angle_type
            case 'target'
                tx = curtrial.Target.x - cursacc.x_sacc_start;
                ty = curtrial.Target.y - cursacc.y_sacc_start;
            case 'saccade'
                tx = cursacc.x_sacc_end-cursacc.x_sacc_start;
                ty = cursacc.y_sacc_end-cursacc.y_sacc_start;
        end
        sacc_angle = atan2d(ty,tx);
        sacc_angle(sacc_angle<0)=sacc_angle(sacc_angle<0)+360;
        data_struct(ind).angle = sacc_angle;
        
        % get saccade onset time
        start_time = curtrial.Saccades(saccade_num).t_start_sacc;
        
        % get neural data
        temp = {[curtrial.Electrodes(electrode).Units(unit).Times] - double(start_time)};
        data_cells{ind}=temp{1}';
        
        ind = ind + 1;
    end
end

% bin by angle
numbins=8;
bin_edges=linspace(0,360,numbins+1);
[n_ang,bin_edges,ang_bins]=histcounts([data_struct.angle],bin_edges);

time_params(1).zero_time=0;
time_params(1).start_time=-time_before;
time_params(1).end_time=time_after;
time_params(1).dt=dt;
time_params(1).pad=pad;
time_params(2:numbins)=time_params(1);

other_params.errBars=errBars;
other_params.useSEs=useSEs;
other_params.smoothflag=smoothflag;
other_params.gauss_sigma = gauss_sigma;
other_params.plotflag = plotflag;
other_params.figTitle = figTitle;

for tb = 1:numbins
    other_params.names{tb}=[num2str(bin_edges(tb)) '-' num2str(bin_edges(tb+1))];
    all_spikes2{tb}=data_cells(ang_bins==tb);
end


switch plot_type
    case 'single'
        % single plot
        if plotflag
            if isfloat(figHand)
                figHand = figure(figHand);
            end
            set(figHand,'position',figLoc)
            other_params.figHand=figHand;
            other_params.plotLoc = plotLoc;
        end
        [ph, PSTH] = PSTH_rast(all_spikes2,time_params,other_params);
    case 'subplots'
        % create subplots
        if plotflag
            set(fh(unit),'Position',[41          69        1053         904])
            other_params.figHand=fh(unit);
            heights=1/2;
            widths=1/(numbins/2);
            binlefts=0:widths:(1-widths);
            lefts=repmat(binlefts,1,2);
            bottoms=[.5*ones(1,length(binlefts)) zeros(1,length(binlefts))];
            other_params.names = [];
        end
        for tb = 1:numbins
            all_spikes={data_cells(ang_bins==tb)};
            if plotflag
                other_params.plotLoc = [lefts(tb) bottoms(tb) widths heights];
                other_params.figTitle = [num2str(bin_edges(tb)) '-' num2str(bin_edges(tb+1))];
            end
            PSTH(tb) = PSTH_rast(all_spikes,time_params,other_params);
        end
end



