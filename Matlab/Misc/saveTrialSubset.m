% save subset of Trials
% replace the 'strfind' and the if-then conditions with the sessions you
% want to keep

for i=1:length(Trials)
    sessName = Trials(i).Session.name;
    is18 = strfind(sessName,'0418');
    is19 = strfind(sessName,'0419');
    
    if ~isempty(is18) || ~isempty(is19)
        keepVec(i)=1;
    else keepVec(i)=0;
    end
end

oldTrials=Trials;
Trials(~keepVec)=[];

