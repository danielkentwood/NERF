% combine_units 
chan = 26;
toadd = 3;
toaddto = 2;

for i = 1:length(Trials)
   spksToAdd = Trials(i).Electrodes(chan).Units(toadd).Times;
   spksToAddTo = Trials(i).Electrodes(chan).Units(toaddto).Times;
   combined = sort(unique([spksToAdd; spksToAddTo]));
   
   Trials(i).Electrodes(chan).Units(toaddto).Times = combined(:);
   Trials(i).Electrodes(chan).Units(toadd)=[]; 
end