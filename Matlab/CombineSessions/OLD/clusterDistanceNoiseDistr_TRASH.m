clear
clc

%% Navigate to the processed experiment folder

%% This will create a struct with all of the processed mat files, along with some metadata
sessfeatures = dir('**/*.mat');
plexonfiles = dir('**/*.plx');
fids = find(~cellfun(@isempty,regexp({sessfeatures.name},'_srt_spl_c(\d+)_u')));
sessfeatures = sessfeatures(fids);
to_del = [];
for i = 1:length(sessfeatures)
    % save plexon file name and check if it exists
    sessfeatures(i).plexon_name = [sessfeatures(i).name(1:(end-8)) '.plx']; % CHECK THAT THIS WORKS; HASN'T BEEN TESTED AFTER ADDING THE UNIT NAME REMOVAL
    plexon_yes = find(contains({plexonfiles.name},sessfeatures(i).plexon_name));
    if ~plexon_yes
        to_del = [to_del i];
    end
    
    % get depth
    curfolder = sessfeatures(i).folder;
    sessfeatures(i).depth = str2num(extractAfter(curfolder,'spl_d'));
    % get channel
    baseTrode = extractAfter(curfolder,'\c');
    sessfeatures(i).channel.Plexon = str2num(baseTrode(1:2));
    sessfeatures(i).channel.GMR = str2num(baseTrode(7:8));
    % get unit
    curname = sessfeatures(i).name;
    baseUnit = extractBetween(curname,'_u','.mat');
    sessfeatures(i).unit.Plexon = str2num(baseUnit{1})-1; % Subtract 1 because PLEXON doesn't count the unsorted spikes as a unit until it is read and saved to the Matlab file (so all matlab unit #s are shifted one up)
    
    % get task
    sessfeatures(i).task = extractBefore(extractAfter(curfolder, 'PROCESSED_'),'\c');
    
    % This will create a list of string IDs with info about GMR electrode and
    % depth
    alltrodedepths{i} = [num2str(sessfeatures(i).channel.Plexon) ',' num2str(sessfeatures(i).depth)];
end

% get rid of cases where there is no corresponding plexon file
sessfeatures(to_del)=[];
alltrodedepths(to_del)=[];
% Get all unique depth/electrode pairs
uniquetrodedepths = unique(alltrodedepths);

%% Now, we need to resample with replacement
% This will create a n x s matrix, where n is the number of resampling iterations and
% s is the session index (this should be the same number as the number of
% uniquetrodedepths. We'll come back to use this later, after all of
% the files have been loaded and the features extracted.
num_iter = 1; % for prototyping, we're just doing one iteration
for ni = 1:num_iter
    samples=[];
    for i = 1:length(uniquetrodedepths)
        curpair = uniquetrodedepths{i};
        matches = find(strcmp(alltrodedepths,curpair));
        
        samples(i) = ceil(rand()*numel(matches));
    end
    allsamples(:,ni)=samples;
end


%% Now load ALL the files and extract features for cluster analysis
% BREAK THIS OUT INTO A SEPARATE FILE EVENTUALLY

% The I/O is the bottleneck here. These files can take forever to load. So
% build a way of checking if a file has already been loaded and features
% extracted and saved.
% save into a variable called 'sess_features'

homedir = experimentHomeFolder;
wave_path = [homedir 'wavelet_coeff_files'];
wave_coeff_files = dir([wave_path filesep '*.mat']);
wave_coeff_names = {wave_coeff_files.name};


%% Loop through all the files, extract features
all_cc=[];
all_wf=[];
% for i = 1:length(sessfeatures)
for i = 1:10 % start small for development
    disp(['Feature extraction, ' num2str(i) ' of ' num2str(length(sessfeatures))])
    % set current session
    cursess = sessfeatures(i);
    
    % GET WAVEFORM FEATURES
    % first, check if saved file already exists
    C = strsplit(cursess.name,'.');
    wave_coeff_exists = contains(wave_coeff_names, C{1});
    % if it does, load it
    if any(wave_coeff_exists)
        load(fullfile(wave_path,wave_coeff_names{wave_coeff_exists}));
        disp('Waveform features loaded.')
        if inspk<0
            disp([fullfile(wave_path,wave_coeff_names{wave_coeff_exists}) ' is empty. Deleting file...'])
            delete(fullfile(wave_path,wave_coeff_names{wave_coeff_exists}));
            sessfeatures(i).bad_session = 1;
        end
        [n, npw, ts, wave2] = plx_waves_v(fullfile(cursess.folder,cursess.plexon_name), cursess.channel.Plexon, cursess.unit.Plexon);
    else % if it doesn't, make the file, save it and keep it
        % load corresponding plx file (to get waveforms)
        [n, npw, ts, wave2] = plx_waves_v(fullfile(cursess.folder,cursess.plexon_name), cursess.channel.Plexon, cursess.unit.Plexon);
        if wave2<0
            disp([fullfile(sessfeatures(i).folder,sessfeatures(i).plexon_name) ' is empty'])
            sessfeatures(i).bad_session = 1;
            continue
        end
        
        % extract waveform features using haar wavelet
        par.scales = 4; % level decomposition (3 or 4 is typical for 2D data)
        par.features = 'wav'; % type of feature extraction
        par.inputs = 3; % number of features to extract
        par.inputs = size(wave2,2); % for now, keep all coefficients
        disp('Extracting waveform features...')
        tic
        inspk = wave_features(wave2,par);
        disp(['Extraction took ' num2str(toc) ' sec.'])
        % save file
        coeff_fname = [C{1} '_WavCoeffs.mat'];
        save(fullfile(wave_path, coeff_fname), 'inspk')
    end
    
    
    all_cc = [all_cc; inspk];
    all_wf = [all_wf; wave2];
    
    
    
    
    %     isi = diff(ts); % get isi's
    %     isi(isi>0.5)=[]; % only look at isi's lower than .5 sec.
    %     [f,x]=hist(isi,100); %use hist function and get unnormalized values
    %     isi_pdf = f/sum(f); % pdf
    
    
    
    % get spike timing statistics
    
    % get waveform statistics
    
    % ***** TO DO *******
    % get action potential waveform shape(s) and traditional features
    % * median and std of waveform shape
    % * number of waveforms
    % * energy, peak, valley, peak to valley, spikewidth (this can also be used
    % to infer whether the cell is inhibitory or excitatory).
    % * these features might also be able to help designate whether a recording
    % is from a cell or is MUA.
    
    % get autocorrelation metric
    
    % (spend some time looking at spike sorting software, and include some
    % other features maybe? Whatever you do, it needs to be a single metric
    % extracted that you'll be comparing between sessions, not the raw
    % waveforms themselves -- otherwise the dataset would be too massive).
    
    
    
    %     % go to appropriate folder
    %     cd(sessfeatures(i).folder)
    %
    %     % load current mat file
    %     load(sessfeatures(i).name)
    %
    %     % preprocess
    %     Trials = saccade_detector(Trials);
    %     Trials = cleanTrials(Trials);
    
    
    
    
    
    
    
    % if probe task
    if contains(sessfeatures(i).task, 'probe')
        
        %         probe = make_probe_table(Trials); % this function should create a master probe table
        %
        %         make_probe_matrix % this function should give a matrix of [x,y,fr], where xy are probe locations [gaze centered to 0] and fr is firing rate
        %         make_movement_matrix % this function should give a matrix of [x,y,fr], where xy are movement endpoints [gaze centered to 0] and fr is firing rate
        %
        %         move_pre = inferTuning2(Trials,sessfeatures(i).channel.GMR,0); % get RF estimate for movement
        %         probe_pre = inferTuning2(Trials,sessfeatures(i).channel.GMR,0); % get RF estimate for visual probes
        %
        %         % right now, this code won't work. inferTuning2.m is tailored to
        %         % get movement RFs only. You need to change it (or write a new function) so that it can
        %         % accept a matrix of [x,y,fr], where the xy can be movement vectors
        %         % or probe locations.
        %
        %         % grab the probe-locked radial PSTHs
        %         sessfeatures(i).visual.radialPSTH = radial_PProbeTH(Trials,sessfeatures(i).channel.GMR,[-200 500],0);
        %         % grab the saccade-locked radial PSTHs
        %         sessfeatures(i).motor.radialPSTH = radial_PSacTH(Trials,sessfeatures(i).channel.GMR,0);
        %         % grab the downsampled RF estimates
        %         dsFactor=16;
        %         sessfeatures(i).motor.dsRF = getDownsampledRF(move_pre,dsFactor);
        %         sessfeatures(i).visual.dsRF = getDownsampledRF(probe_pre,dsFactor); % grab the downsampled RF estimate for probes
        
        % if MGS task
    elseif contains(sessfeatures(i).task, 'mgs')
        
        %         % do MGS preprocessing
        %         Trials = MGS_scrub(Trials);
        %
        %         make_movement_matrix % this function should give a matrix of [x,y,fr], where xy are probe locations and fr is firing rate
        %
        %         % grab the stim-locked radial PSTHs
        %         sessfeatures(i).visual.radialPSTH = radial_PStimTH(Trials,sessfeatures(i).channel.GMR,0);
        %         % grab the saccade-locked radial PSTHs
        %         sessfeatures(i).motor.radialPSTH = radial_PSacTH(Trials,sessfeatures(i).channel.GMR,0);
        
    end
end

par.scales = 4; % level decomposition (3 or 4 is typical for 2D data)
par.features = 'wav'; % type of feature extraction
par.inputs = 3; % number of features to extract
inspk = wave_features(wave2,par);

inspk = wavelet_coeff_KS(all_cc, par);


%% Now try cluster, get distances



% tsne?






% ******** TO DO **********
% Do a PCA on all the features and find which ones are the least correlated
% (i.e., which ones lead to the best separation of clusters).
% Find a way to optimize the weighting of the features based on this PCA.
%
% Try a number of clustering algorithms
% * K-means (kmeans.m)
% * Hierarchical clustering (pdist.m)
% * Self-organizing map:
%       * (https://www.mathworks.com/help/nnet/gs/cluster-data-with-a-self-organizing-map.html)
% * Gaussian mixture models (this can be used with PCA):
%       * (https://www.mathworks.com/help/stats/clustering-using-gaussian-mixture-models.html)
%       * (https://www.mathworks.com/help/stats/fitgmdist.html)















%%
%
%
%
% %% OLD CODE
% % grab all .mat sessions
% dm = dir('*.mat');
% numsess = length(dm);
%
% % grab all .plx sessions
% dp = dir('*.plx');
% plex_vec = [1:2:31 2:2:32];
%
%
%
% % choose experiment
% choice = questdlg('Which experiment?', ...
% 	'Experiment Menu', ...
% 	'Probes','MGS','MGS');
% % Handle response
% switch choice
%     case 'Probes'
%         disp([choice ' coming right up.'])
%         expID = 1;
%     case 'MGS'
%         disp([choice ' coming right up.'])
%         expID = 2;
% end
%
%
%
% psthID=0;
% for s = 1:numsess
%     % get mat sessname
%     sessname = dm(s).name;
%     data.sess(s).name = sessname;
%     % load the mat file
%     load(sessname)
%     % preprocess
%     Trials = saccade_detector(Trials);
%     Trials = cleanTrialsStruct_v2(Trials);
%
%     % get channel info
%     chan=find(~cellfun(@isempty,{Trials(1).Electrodes.Units}));
%     plex_chan = find(plex_vec==chan);
%
%     % get plx sessname
%     plxSess = dp(s).name;
%
%     % grab the radial movement PSTHs (saccade locked)
%     PSTH = radial_PSacTH(Trials,chan,0);
%     numUnits = length(PSTH.electrode(chan).unit);
%
%     % now grab the radial stim-locked PSTHs
%     % if probe task
%     if expID==1
%         % grab the probe-locked PSTHs
%         sPSTH = radial_PProbeTH(Trials,chan,[-200 500],0);
%     % if MGS task
%     elseif expID==2
%         % grab the stim-locked PSTHs
%         sPSTH = radial_PStimTH(Trials,chan,0);
%     end
%
%     % grab the downsampled movement RF estimation (otherwise the pdist function takes way too long)
%     dsFactor=16;
%     dsRF = getDownsampledRF(Trials,chan,dsFactor);
%
%     % concatenate PSTHs
%     for u = 2:numUnits
%         curunit = PSTH.electrode(chan).unit(u).data;
%         s_curunit = sPSTH(1).electrode(chan).unit(u).data;
%
%         allpsth=[];
%         peakpsth=[];
%         speakpsth=[];
%         for b = 1:length(curunit)
%             allpsth = [allpsth curunit(b).data];
%             peakave = mean(curunit(b).data(curunit(b).time>-80 & curunit(b).time<0));
%             speakave = mean(s_curunit(b).data(s_curunit(b).time>50 & s_curunit(b).time<150));
%             peakpsth = [peakpsth peakave]; % movement locked PSTH
%             speakpsth = [speakpsth speakave]; % stimulus locked PSTH
%         end
%         % normalize
%         peakpsth = peakpsth ./ max(peakpsth);
%         speakpsth = speakpsth ./ max(speakpsth);
%         bpeakpsth = [peakpsth speakpsth]; % combining the movement and stimulus-locked PSTHs
%
%         % grab plx info
%         [n, npw, ts, wave2] = plx_waves_v(plxSess, plex_chan, u-1);
%
%         % store
%         psthID = psthID+1;
%         data.psth_mat(psthID,:) = allpsth;
%         data.sess(s).unit(u-1).psthID = psthID;
%         data.sess_mat{psthID} = [sessname(1:end-4) '_u' num2str(u-1)];
%         data.wf_mat(psthID,:) = median(wave2);
%         data.peak_psth_mat(psthID,:) = bpeakpsth;
%         data.dsRF_mat(psthID,:)=dsRF{u-1}.Bs(:)';
%     end
%
%     clearvars -except data s dm numsess psthID dp plex_vec expID
% end
%
% psth_mat = data.psth_mat;
% sess = data.sess;
% sess_mat = data.sess_mat;
% wf_mat = data.wf_mat;
% peak_psth_mat = data.peak_psth_mat;
% dsRF_mat = data.dsRF_mat;
%
% close all
% %% waveform comparisons
% [mx,mxi]=max(wf_mat');
% [mi,mii]=min(wf_mat');
% ms1 = mxi-mii; % time to peak minus time to trough
% ms2=mx./(mx-mi); % peak normalized by peak-trough
% ms3=mi./(mx-mi); % trough normalized by peak-trough
% ms4 = mx./abs(mi); % ratio of peak/trough values
%
%
% %% hierarchical clustering
% w1 = .4; % stimulus-locked radial tuning weight
% w2 = 1; % waveform shape weight
% w3 = 1; % downsampled movement RF weighting
%
%
% Y = pdist(peak_psth_mat);
% Y2 = pdist(wf_mat);
% Y3 = pdist(dsRF_mat);
%
% YS = ((Y.*w1) + (Y2.*w2) + (Y3.*w3)) / 3; % weighted average of the distance scores
% Z = linkage(YS);
%
% clusterInfo = getClusters(Z,sess_mat);
%
% clusterInfo.wf_mat = wf_mat;
%
%
%
% %% now run session combine script
% sessCombine
%
%
%


