clear
clc
close all
cd('~/Desktop/FadeIn_Adam/odd & fade-in/fefcells/redone2')

%% fade, in vs out, tgt-locked
% this gives good evidence for relevance effects in a number of cells
% cell 60 is a good example

% no fade trials: 7, 34,
for i = setdiff(1:69,[7 34])
% for i = 60
    cellnum=i;
    load(['oddfade' num2str(cellnum) '.mat'])
    
    eval(['a=oddfade' num2str(cellnum) '.taskdata.fadein_oddball.spkdata.spksSac{1};']);
    eval(['b=oddfade' num2str(cellnum) '.taskdata.fadein_oddball.spkdata.spksSac{2};']);
    eval(['c=oddfade' num2str(cellnum) '.taskdata.standard_oddball.spkdata.spksSac{1};']);
    eval(['d=oddfade' num2str(cellnum) '.taskdata.standard_oddball.spkdata.spksSac{2};']);
    
    time_params(1).zero_time=0;
    time_params(1).start_time=-450;
    time_params(1).end_time=250;
    time_params(1).dt=5;
    time_params(2:4) = time_params(1);
    
    other_params.errBars=1;
    other_params.useSEs=1;
    other_params.smoothflag=1;
    other_params.smoothtype='gauss';
    other_params.gauss_sigma = 10;
    other_params.names = {'Fade, Target','Fade, Distractor','Flash, Target','Flash, Distractor'};
    nda_PSTH({a b c d},time_params,other_params);
%     PSTH_rast({a b c d},time_params,other_params);
    drawnow
    clear
end




% 
% %% in-RF, standard vs fade, sacc-locked

% for i = setdiff(1:69,[7 34])
%     cellnum=i;
%     load(['oddfade' num2str(cellnum) '.mat'])
%    
%     eval(['a=oddfade' num2str(cellnum) '.taskdata.standard_oddball.spkdata.spksSac{1};']);
%     eval(['b=oddfade' num2str(cellnum) '.taskdata.fadein_oddball.spkdata.spksSac{1};']);
%     time_params(1).zero_time=0;
%     time_params(1).start_time=-500;
%     time_params(1).end_time=200;
%     time_params(1).dt=5;
%     time_params(2) = time_params(1);
%     other_params.errBars=0;
%     other_params.smoothflag=1;
%     other_params.smoothtype='gauss';
%     other_params.gauss_sigma = 10;
%     PSTH_rast({a b},time_params,other_params);
%     clear
%     drawnow
% end
% 
% 
% %% standard, in vs out, stim-locked
% for i = 67
%     cellnum=i;
%     load(['oddfade' num2str(cellnum) '.mat'])
% 
%     eval(['a=oddfade' num2str(cellnum) '.taskdata.standard_oddball.spkdata.spksTgt{1};']);
%     eval(['b=oddfade' num2str(cellnum) '.taskdata.standard_oddball.spkdata.spksTgt{2};']);
%     time_params(1).zero_time=0;
%     time_params(1).start_time=-200;
%     time_params(1).end_time=500;
%     time_params(1).dt=5;
%     time_params(2) = time_params(1);
%     other_params.splineOrder=40;
%     other_params.errBars=0;
%     other_params.smoothflag=1;
%     PSTH_rast({a b},time_params,other_params)
%     clear
%     drawnow
% end
% %% standard, in vs out, tgt-locked
% for i = setdiff(1:69,[7 34])
%     cellnum=i;
%     load(['oddfade' num2str(cellnum) '.mat'])
%     
%     eval(['a=oddfade' num2str(cellnum) '.taskdata.standard_oddball.spkdata.spksTgt{1};']);
%     eval(['b=oddfade' num2str(cellnum) '.taskdata.standard_oddball.spkdata.spksTgt{2};']);
%     time_params(1).zero_time=0;
%     time_params(1).start_time=-250;
%     time_params(1).end_time=450;
%     time_params(1).dt=5;
%     time_params(2) = time_params(1);
%     other_params.errBars=0;
%     other_params.smoothflag=1;
%     other_params.smoothtype='gauss';
%     other_params.gauss_sigma = 10;
%     PSTH_rast({a b},time_params,other_params);
%     clear
%     drawnow
% end
% 
% 
% 
% %% standard, in vs out, stim-locked
% a=oddfade1.taskdata.standard_oddball.spkdata.spksTgt{1};
% b=oddfade1.taskdata.standard_oddball.spkdata.spksTgt{2};
% time_params(1).zero_time=0;
% time_params(1).start_time=-200;
% time_params(1).end_time=500;
% time_params(1).dt=5;
% time_params(2) = time_params(1);
% PSTH_rast({a b},time_params)
% 
% %% standard, in vs out, sacc-locked
% a=oddfade1.taskdata.standard_oddball.spkdata.spksSac{1};
% b=oddfade1.taskdata.standard_oddball.spkdata.spksSac{2};
% time_params(1).zero_time=0;
% time_params(1).start_time=-500;
% time_params(1).end_time=200;
% time_params(1).dt=5;
% time_params(2) = time_params(1);
% PSTH_rast({a b},time_params)
% 
% 
% 
