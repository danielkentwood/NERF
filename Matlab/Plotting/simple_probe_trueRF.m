

% first, run radial_PProbeTH_simple_probe.m
% this will let you see the response of the probe in the fixation reference
% frame, as well as the remapped reference frame
PSTH = radial_PProbeTH_simple_probe(Trials);

% now, see where the most variable part of the PPTH occurs
for i = 1:length(PSTH{2}) 
    y_all(i,:) = PSTH{2}(i).y; 
end
avg_var = mean(std(y_all));
std_var = std(std(y_all));
[peak_y_var, pyv_idx] = max(std(y_all));
if peak_y_var < (avg_var+std_var*2)
    disp('CAUTION: Peak variability isn''t much greater than mean variability')
else
    disp('All good')
end

% decide on a window size, get bounds of window based on max variability 
win_size = 40;
early_bound = PSTH{2}(1).x(pyv_idx)-win_size/2;
late_bound = PSTH{2}(1).x(pyv_idx)+win_size/2;
% win_idx = 




% GOAL: to map RF of cell at rest (before target)
% see plotRF for making color map...
% Tanaz: write pseudocode to accomplish this goal...

%{
Note: plotRF arguments: ????? 
x -> vector of probe x-vals
y -> vector of probe y-vals
fr -> vector of firing rates
varargin -> ??
%}

%{
Similar to simple_probe_analysis... so based on that...

- QUESTIONS: 
- Why is time_before_probe = 0? Don't we want to see reponse a
bit before probe to see how it changes?
- What is sTimes in line 127?

Process:
- Look at the event codes and times of those codes: 
- For each trial, only want to look at firing rates BEFORE target onset
    So, find the time of the target,
    Only count the probes that occur before that target
- Make sure no saccades during the time that you are looking at - if we do
this, dont we not have to subtract current ey eposn (like 135-136)
- For each probe position, we want the ?avg? firing rate of the cell when the
    probe is flashed
- Plot these values in the color map
%}

