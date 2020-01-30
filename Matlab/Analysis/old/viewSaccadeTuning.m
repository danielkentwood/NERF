function viewSaccadeTuning(Trials,varargin)

if ispc
    opengl software % use openGL software rather than hardware (since you are using alpha transparency and this isn't compatible with openGL hardware currently)
end

% how many channels are there?
for i = 1:length(Trials(1).Electrodes)
    chanList(i)=~isempty(Trials(1).Electrodes(i).Units);
end
chanList=find(chanList);

% spike train parameters
time_before=400;
time_after=200;
fr_time_before=70;
fr_time_after=0;
dt=5;
sigma=10;
timevec=-time_before:dt:time_after;

Pfields = {'time_before','time_after','fr_time_before','fr_time_after','dt','sigma'};
for i = 1:length(Pfields) % if a params structure was provided as an input, change the requested fields
    if ~isempty(varargin)&&isfield(varargin{1}, Pfields{i}), eval(sprintf('%s = varargin{1}.(Pfields{%d});', Pfields{i}, i)); end
end
if ~isempty(varargin)  % if there is a params input
    fnames = fieldnames(varargin{1}); % cycle through field names and make sure all are recognized
    for i = 1:length(fnames)
        recognized = max(strcmp(fnames{i},Pfields));
        if recognized == 0, fprintf('fieldname %s not recognized\n',fnames{i}); end
    end
end




% inferTuning Params
params.xwidth=50;
params.ywidth=50;
params.filtsize=[20 20];
params.filtsigma=3;

x=[];y=[];t=[];
st = 0;
for i = 1:length(Trials)
    for sc = 1:length(Trials(i).Saccades)
        st=st+1;
        csc=Trials(i).Saccades(sc);
        x(end+1)=csc.x_sacc_end-csc.x_sacc_start;
        y(end+1)=csc.y_sacc_end-csc.y_sacc_start;
        t(end+1)=csc.t_start_sacc;
        
        start_time = t(end)-time_before;
        end_time = t(end)+time_after;
        
        for tr=chanList
            for u = 1:length(Trials(i).Electrodes(tr).Units)
                if sc==1 && st==1
                    trode(tr).fr{u}=[];
                end
                cu = Trials(i).Electrodes(tr).Units(u);
                spikes=cu.Times;
                
                spikeTimes=spikes(spikes>start_time & spikes<end_time)-double(t(end));
                sTrain = buildSpikeTrain(spikeTimes,0,-time_before,time_after,dt);
                sTrain_g = gauss_spTrConvolve(sTrain,dt,sigma);
                trode(tr).fr{u}(end+1)=mean(sTrain(timevec>-fr_time_before & timevec<fr_time_after)).*1000;
            end
        end
    end
end


for tr=1:length(trode)
    for u=2:length(trode(tr).fr)
        inferTuning(x,y,trode(tr).fr{u},params);
    end
end
                

            
        