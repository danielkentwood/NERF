%% load stuff
if exist('sessList','var') && ~exist('Trials','var')
    Trials = open_merged(sessList);
end


%% Preprocess
Trials = saccade_detector(Trials);
Trials = cleanTrials(Trials);
Trials = MGS_scrub(Trials);

%% get stimulus locked tuning (radial)
radial_PStimTH(Trials) 


%% get saccade-locked tuning (radial)
r_mov_par.figHand = gcf;
PSTH_r_mov = radial_PSacTH(Trials, r_mov_par);

for i = 1:length(PSTH_r_mov), y_all(i,:) = PSTH_r_mov(i).y; end

[pstd_yall, pyi] = max(std(y_all));
x_at_peak_std = PSTH_r_mov(1).x(pyi);



%% get estimate of movement RF
% Using x_at_peak from untuned temporal response, plot movement RF map
params.dt=10;
params.x_at_peak=x_at_peak_std;
params.x_at_peak=-100;
params.win_size=40;
params.xwidth=40;
params.ywidth=30;
params.pad = 20;
moveRF_preview(Trials,params);



















