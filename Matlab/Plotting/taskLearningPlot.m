% learning the task

numsession=Trials(end).Session.num;
for i = 1:length(Trials)
    cursess(i)=Trials(i).Session.num;
end

for i = 1:numsessionTrials
    correctHoriz(i)=mean(isHoriz(logical(rewarded)&logical(cursess==i)));
    correctVert(i)=1-correctHoriz(i);
end
    

plot(correctHoriz*100,'linewidth',2)
hold on
plot(correctVert*100,'linewidth',2)

set(gca,'FontSize',15)
box off
xlabel('Session number')
ylabel('Percent Correct')
lh = legend('Horiz Targ Correct','Vert Targ Correct','Location','Best');
set(lh,'Box','off')
