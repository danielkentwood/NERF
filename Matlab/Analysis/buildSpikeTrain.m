% buildSpikeTrain.m
%
% Inputs    spikeTimes: a vector or a cell array of vectors containing
%               spike times.
%           zeroTime: the time of the event to which you wish to lock.
%           startTime: how much time before the zeroTime do you wish to
%               include?
%           endTime: how much time after the zeroTime do you wish to
%               include?
%           dt: bin size for the spike train
%
% Output    Sm: the spike train (vector for single trial or matrix for
%               multiple trials).
%
% DKW, 1.4.16

function Sm = buildSpikeTrain(spikeTimes,zeroTime,startTime,endTime,dt)

nospikes=0;
if isempty(spikeTimes)
    nospikes = 1;
    numtrials =1;
elseif iscell(spikeTimes)
    numtrials=length(spikeTimes);
elseif isvector(spikeTimes)
    spikeTimes = {spikeTimes};
    numtrials=1;
elseif ismatrix(spikeTimes)
    error('spikeTimes input needs to be either a vector or a cell array of vectors, not a matrix')
end

% Get time vector
T = length(startTime:endTime);
% if startTime<=0
%    T=T-1;
% end
% Use time vector to create a sparse matrix which will act as an empty bin
% structure to fill up with spikes.
S = sparse(zeros(numtrials,ceil(T/dt)));

if nospikes
    Sm=full(S);
else
    for tr=1:numtrials
        % get spike times
        spTs = spikeTimes{tr};
        % align them to zero event
        spTs=spTs-double(zeroTime);
        % align to start time
        spTs=spTs-double(startTime);
        
        % only keep the ones within the specified window
        if startTime<=0
            spTs=spTs(spTs>0 & spTs<=(endTime-startTime+dt));
        else
            spTs=spTs(spTs>0 & spTs<=endTime-startTime);
        end
        
        for j=1:length(spTs)
            S(tr,ceil((spTs(j))/dt)) = S(tr,ceil(spTs(j)/dt))+1; % We divide by the bin interval because we are filling up bins
        end
    end 
    Sm=full(S);
end
