function psth = temporal_untuned_pSacTH(Trials)

if ispc
    opengl software % use openGL software rather than hardware (since you are using alpha transparency and this isn't compatible with openGL hardware currently)
end

electrode = find(~cellfun(@isempty,{Trials(1).Electrodes.Units}));
unit = 1;

% temporal parameters
dt = 5;
pad = 50;
time_before = 500+pad;
time_after = 300+pad;

trialvec = 1:length(Trials);
ind=1;
for trial = 1:length(trialvec)
    curtrial=trialvec(trial);   
    for saccade_num = 1:length(Trials(curtrial).Saccades)
        % get saccade onset time
        start_time = Trials(curtrial).Saccades(saccade_num).t_start_sacc;
        
        % get neural data
        temp = {[Trials(curtrial).Electrodes(electrode).Units(unit).Times] - double(start_time)};
        data_cells{ind}=temp{1}';
        
        ind = ind + 1;
    end
end

time_params.zero_time=0;
time_params.start_time=-time_before;
time_params.end_time=time_after;
time_params.dt=dt;
time_params.pad=pad;

other_params.errBars=1;
other_params.useSEs=1;
other_params.smoothflag=1;
other_params.gauss_sigma = 10;
other_params.names{1} = 'untuned temporal';

fh=figure();
set(fh,'position',[495   219   810   764])
other_params.figHand=fh;
other_params.plotLoc = [0 0 1 1];
other_params.figTitle = 'Untuned temporal movement response';
[ph psth] = PSTH_rast(data_cells,time_params,other_params);









