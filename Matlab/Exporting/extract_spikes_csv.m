% extract spike times, save in .csv file
function extract_spikes_csv(Trials,fname)

chan=find(~cellfun(@isempty,{Trials(1).Electrodes.Units}));
numUnits = length(Trials(1).Electrodes(chan).Units);

for u = 1:(numUnits-1)
    unit(u).Times = [];
end

for i = 1:length(Trials)
    for u = 1:(numUnits-1)
        unit(u).Times = [unit(u).Times; Trials(i).Electrodes(chan).Units(u+1).Times];
    end
end

for i = 1:(numUnits-1)
    csvwrite(['spiketimes_' fname '_u' num2str(i) '.csv'],unit(i).Times)
end





