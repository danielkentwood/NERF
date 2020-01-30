
for t=1:length(Trials)

x=Trials(t).Signals(1).Signal;
y=Trials(t).Signals(2).Signal;
eyePositionDisplay(x,y,[48 36]);





ginput();
close all
end
