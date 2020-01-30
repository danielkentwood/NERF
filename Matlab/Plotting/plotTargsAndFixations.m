function plotTargsAndFixations(Trials)

ctr=1;
for i = 1:length(Trials)
    
    % get targets and fixations
    targX(i)=Trials(i).Target.x;
    targY(i)=Trials(i).Target.y;
    distX(i)=Trials(i).Distractor.x;
    distY(i)=Trials(i).Distractor.y;
    
    for s = 1:length(Trials(i).Saccades)
        fixX(ctr)=Trials(i).Saccades(s).meanX_prev_fix;
        fixY(ctr)=Trials(i).Saccades(s).meanY_prev_fix;
        
        sacX(ctr)=Trials(i).Saccades(s).x_sacc_end-Trials(i).Saccades(s).x_sacc_start;
        sacY(ctr)=Trials(i).Saccades(s).y_sacc_end-Trials(i).Saccades(s).y_sacc_start;
        ctr=ctr+1;
    end

    
end

figure
plot(fixX,fixY,'rx')
hold all
plot(targX,targY,'ko','linewidth',2)
plot(xlim,[0 0],'k')
plot([0 0],ylim,'k')
title('Targets and fixations')


figure
% plot(sacX,sacY,'ro')
plot([zeros(length(sacX),1),sacX(:)]',[zeros(length(sacY),1),sacY(:)]','linewidth',.5,'color',[.5 .5 .5])
hold all
plot(xlim,[0 0],'k')
title('Saccade vectors')
plot([0 0],ylim,'k')

figure
sacc_mags = sqrt(sacX.^2 + sacY.^2);
hist(sacc_mags,100)
title('Saccade magnitudes')