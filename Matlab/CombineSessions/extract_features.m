
% extract_features
function out = extract_features(sessfeatures, sessIDX)

feat_path = [experimentHomeFolder 'feature_files'];
feat_files = dir([feat_path filesep '*.mat']);
feat_names = {feat_files.name};



% Loop through all the files, extract features

all_polar_tuning_coeffs=[];
all_spike_wavelet_coeffs=[];
for i = 1:length(sessIDX)
    % for i = 1:1000 % start small for development
    disp(['Feature extraction, ' num2str(i) ' of ' num2str(length(sessIDX))])
    % set current session
    cursess = sessfeatures(sessIDX(i));
    
    % see if features have already been extracted and saved for this
    % session
    C = strsplit(cursess.name,'.');
    feat_exists = contains(feat_names, C{1});
    
    % if so, just load them up
    if any(feat_exists)
        if sum(feat_exists)>1
            disp('uh-oh. more than one file is trying to load.')
            debug
        else
            load(fullfile(feat_path,feat_names{feat_exists}));
            disp('features loaded.')
            if spike_wavelet_coeffs<0
                disp([fullfile(feat_path,feat_names{feat_exists}) ' is empty. Deleting file...'])
                delete(fullfile(feat_path,feat_names{feat_exists}));
                sessfeatures(i).bad_session = 1;
            end
        end
    else % if it doesn't, make the file and save it
        
        % read waveforms
        [n, npw, ts, wave2] = plx_waves_v(fullfile(cursess.folder,cursess.plexon_name), cursess.channel.Plexon, cursess.unit.Plexon);
        if wave2<0
            disp([fullfile(cursess.folder,cursess.plexon_name) ' is empty'])
            sessfeatures(i).bad_session = 1;
            continue
        end
        par.scales = 5; % level decomposition (3 or 4 is typical for 2D data, 5 for 1D)
        par.features = 'wav'; % type of feature extraction
        par.inputs = size(wave2,2);
        median_waveform = median(wave2);
        spike_wavelet_coeffs = wave_features(median_waveform, par);
        
        % NOW LOAD MAT FILE AND GET TUNING FEATURES
        % load current mat file
        load(fullfile(cursess.folder,cursess.name))
        % preprocess
        Trials = saccade_detector(Trials);
        Trials = cleanTrials(Trials);
        % find point of greatest variability in radial PSTHs for movement
        r_mov_par.plotflag=0;
        r_mov_par.errBars=0;
        PSTH_r_mov = radial_PSacTH(Trials, r_mov_par);
        for i = 1:length(PSTH_r_mov), y_all(i,:) = PSTH_r_mov(i).y; end
        [pstd_yall, pyi] = max(std(y_all));
        x_at_peak_std = PSTH_r_mov(1).x(pyi);
        % get coeffs for polar tuning fit
        params.plotflag=0;
        params.x_at_peak=x_at_peak_std;
        pol_fit = polar_tuning(Trials, params);
        polar_tuning_coeffs = pol_fit.model_coeffs;
        
        % save features
        feat_fname = [C{1} '_feats.mat'];
        save(fullfile(feat_path, feat_fname), 'spike_wavelet_coeffs',...
            'polar_tuning_coeffs', 'median_waveform')
    end
    
    all_spike_wavelet_coeffs = [all_spike_wavelet_coeffs; spike_wavelet_coeffs];
    all_polar_tuning_coeffs = [all_polar_tuning_coeffs; polar_tuning_coeffs'];
end


% reduce dimensionality of the spike wavelet coeffs
par.scales = 4; % level decomposition (3 or 4 is typical for 2D data)
par.features = 'wav'; % type of feature extraction
par.inputs = 15;
all_spike_wavelet_coeffs = wavelet_coeff_KS(all_spike_wavelet_coeffs, par);


%% Extract features through wavelet decomposition
out.spike_wavelet_coeffs = all_spike_wavelet_coeffs;
out.polar_tuning_coeffs = all_polar_tuning_coeffs;
out.all_features = [all_spike_wavelet_coeffs all_polar_tuning_coeffs];



