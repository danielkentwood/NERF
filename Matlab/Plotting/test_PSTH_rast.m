% set up time params
time_params.zero_time=0;
time_params.start_time=-550;
time_params.end_time=550;
time_params.dt=5;
time_params.pad=50;

% set up other params
other_params.errBars=1;
other_params.useSEs=1;
other_params.smoothflag=1;
other_params.smoothtype='gauss';
other_params.gauss_sigma = 10;
other_params.plotLoc = [0 0 1 1];

% build a fake dataset of spike times
numtrials=5;
spikerate = 200;
spikes = repmat({time_params.start_time:(1000/spikerate):time_params.end_time}, 1, numtrials);

% eventually, this will test both nda_PSTH and nda_raster
% currently, PSTH_rast duplicates their code, but this is unnecessary
PSTH_rast(spikes,time_params,other_params);
% Note that the spike rate will not be perfectly matched to the fake data;
% because we are smoothing it by convolving with a gaussian, there is a
% tradeoff between the level of smoothing and fidelity to the true number
% of spikes in a bin. We use a sigma of 10 for the gaussian kernel, which
% introduces an acceptably small amount of error to the estimated mean firing
% rate.