function out = moveRF_preview(Trials,params)

if ispc
    opengl software % use openGL software rather than hardware (since you are using alpha transparency and this isn't compatible with openGL hardware currently)
end



% % varargin default values (varargin is a struct with the following possible fields)
% xwidth      = 200;
% ywidth      = 200;
% filtsize    = [10 10];
% filtsigma   = 2;
% plotflag    = 1;
% fig_Handle   = [];
% axes_Handle  = [];
% 
% Pfields = {'xwidth','ywidth','filtsize','filtsigma','plotflag','fig_Handle','axes_Handle'};
% for i = 1:length(Pfields) % if a params structure was provided as an input, change the requested fields
%     if ~isempty(varargin)&&isfield(varargin{1}, Pfields{i}), eval(sprintf('%s = varargin{1}.(Pfields{%d});', Pfields{i}, i)); end
% end
% if ~isempty(varargin)  % if there is a params input
%     fnames = fieldnames(varargin{1}); % cycle through field names and make sure all are recognized
%     for i = 1:length(fnames)
%         recognized = max(strcmp(fnames{i},Pfields));
%         if recognized == 0, fprintf('fieldname %s not recognized\n',fnames{i}); end
%     end
% end




% temporal params
dt = params.dt;
x_at_peak = params.x_at_peak;
win_size = params.win_size;
time_before = x_at_peak-round(win_size/2);
time_after = x_at_peak+round(win_size/2);

% spatial params
% xwidth=200;
% ywidth=200;
xwidth=params.xwidth;
ywidth=params.ywidth;
xvec = -xwidth:xwidth;
yvec = -ywidth:ywidth;

% get electrode
electrode = find(~cellfun(@isempty,{Trials(1).Electrodes.Units}));
% unit
unit = 1;

trialvec = 1:length(Trials);
ind = 1;
for trial = 1:length(trialvec)
    curtrial=trialvec(trial);
    
    for saccade_num = 1:length(Trials(curtrial).Saccades)
        % get saccade
        sx1 = Trials(curtrial).Saccades(saccade_num).x_sacc_start;
        sy1 = Trials(curtrial).Saccades(saccade_num).y_sacc_start;
        sx2 = Trials(curtrial).Saccades(saccade_num).x_sacc_end;
        sy2 = Trials(curtrial).Saccades(saccade_num).y_sacc_end;
        % center it at [0, 0]
        rallx(ind) = ceil(sx2-sx1);
        rally(ind) = ceil(sy2-sy1);
        
        % get saccade onset time
        start_time = Trials(curtrial).Saccades(saccade_num).t_start_sacc + time_before;
        end_time = Trials(curtrial).Saccades(saccade_num).t_start_sacc + time_after;
        
        % get firing rates
        temp = {[Trials(curtrial).Electrodes(electrode).Units(unit).Times] - double(start_time)};
        firing_rate(ind) = mean(full(getSpkMat(temp,dt,end_time-start_time,0)))*1000/dt;
        
        ind = ind + 1;
    end
end

plot_params.xwidth      = xwidth;
plot_params.ywidth      = ywidth;
plot_params.filtsize    = [10 10];
plot_params.filtsigma   = 2;

[out, h] = plotRF(rallx, rally, firing_rate, plot_params);



