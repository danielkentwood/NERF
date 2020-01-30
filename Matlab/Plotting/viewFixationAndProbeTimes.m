% view timeline of events for a given trial
function viewFixationAndProbeTimes(Trials, start_trial)


if nargin<2
    start_trial=1;
end

trial_vec = start_trial:length(Trials);

for i = trial_vec
    
    codes=[Trials(i).Events.Code];
    codeTimes=[Trials(i).Events.Time];
    
    curSaccs=Trials(i).Saccades;
    
    fx=[curSaccs.t_start_prev_fix];
    sc=[curSaccs.t_start_sacc];
    fixStarts=fx-fx(1);
    saccStarts=sc-fx(1);
    probeTimes=Trials(i).probeXY_time(:,3)'-fx(1);
    
    h(1:length(fixStarts)) = plot([fixStarts;fixStarts],[zeros(1,length(fixStarts));ones(1,length(fixStarts))],'b','linewidth',2);
    hold on
    h(51:50+length(saccStarts)) = plot([probeTimes;probeTimes],[zeros(1,length(probeTimes));ones(1,length(probeTimes))*.75],'r','linewidth',1);
    h(101:100+length(probeTimes)) = plot([probeTimes;probeTimes],[zeros(1,length(probeTimes));ones(1,length(probeTimes))*.75],'r','linewidth',1);
    
    ylim([0 1.4])
    box off
    set(gca,'YTick',[])
    xlabel('Time (ms)')
    hl = legend(h([1 101]),'Fixation times','Probe times','location','northwest');
    set(hl, 'box', 'off')
    title(['Trial ' num2str(i) '. Hit any key to proceed to next trial'])
    hold off
    pause()
end