num_saccs=[];
isrewarded=[];
for i=1:length(Trials) 
    num_saccs(i)=length(Trials(i).Saccades);
    isrewarded(i)=Trials(i).Reward;
end

ns_wr=num_saccs(logical(isrewarded)); %number of saccades on trials with reward
mu_ns_wr=mean(ns_wr);
    


%%
% for now, only looking at trials with reward

for i = 1:length(Trials)
   if Trials(i).Reward==0
       continue
   end
   
   startcode=
   rwdcode=
   
   
    
end