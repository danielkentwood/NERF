
function out = polar_tuning(Trials, varargin)

%% varargin default values (varargin is a struct with the following possible fields)
axesDims    = [.15 .15 .7 .7]; % [left bottom width height]
gauss_sigma = 15;
plotLoc     = [0 0 1 1];
figHand     = NaN;
figTitle    = '';
plotflag    = 1;
dt          = 10;
x_at_peak   = -50;
win_size    = 40;
pd          = 20;

Pfields = {'axesDims','gauss_sigma','plotLoc','figHand','figTitle',...
    'plotflag','dt','x_at_peak','win_size','pd'};
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





%% set params
% temporal params
st = x_at_peak-round(win_size/2)-pd;
et = x_at_peak+round(win_size/2)+pd;

% minus padding
st_pad = st+pd;
et_pad = et-pd;

% get time vectors
tv = (st:dt:et)';
tv_pad = st_pad:dt:et_pad;
[~,tv_ia,~]=intersect(tv,tv_pad);

% get electrode
electrode = find(~cellfun(@isempty,{Trials(1).Electrodes.Units}));
% unit
unit = 1;

%% start loop to extract saccade angles and firing rates
ind = 1;
for trial = 1:length(Trials)
    curtrial=Trials(trial);
    for saccade_num = 1:length(curtrial.Saccades)
        % get saccade
        cursacc = curtrial.Saccades(saccade_num);
        % get angle
        tx = cursacc.x_sacc_end-cursacc.x_sacc_start;
        ty = cursacc.y_sacc_end-cursacc.y_sacc_start;
        sacc_angle = atan2d(ty,tx);
        sacc_angle(sacc_angle<0)=sacc_angle(sacc_angle<0)+360;
        angle(ind) = sacc_angle;
        
        % get saccade onset time
        sacc_start_time = curtrial.Saccades(saccade_num).t_start_sacc;
        % get spike train
        temp = [curtrial.Electrodes(electrode).Units(unit).Times] - double(sacc_start_time);
%         spikeTrains = full(getSpkMat(temp, dt, et-st, 0));
        spikeTrains = buildSpikeTrain(temp, 0, st, et, dt);
        
        % create a function that convolves a spike train with a
        % gaussian kernel
        sm_gauss = gauss_spTrConvolve( spikeTrains, dt, gauss_sigma );
        sm_mu(ind) = mean(sm_gauss(tv_ia)).*1000/dt;
        
        % inc ind
        ind = ind + 1;
    end
end

%% fit the Von Mises model
X = [cos(deg2rad(angle))' sin(deg2rad(angle))'];
[fit_parameters, dev, stats] = glmfit(X, sm_mu, 'poisson');
xlin = [cos(deg2rad(1:360))' sin(deg2rad(1:360))'];
y = glmval(fit_parameters, xlin, 'log');

% output variable
out.x = 1:360;
out.y = y;
out.model_coeffs = fit_parameters;

% plotting
if plotflag
    figure();
    plot(angle, sm_mu,'.'); 
    hold on
    plot(1:360, y, 'r','linewidth', 2 );
    xlabel('Angle (degrees)')
    ylabel('Firing rate (Hz = spikes/s)')
    axis([0 360 0 (1.2*max(sm_mu) + 2*(1.2*max(sm_mu)==0))])
end



