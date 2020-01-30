clear
clc
close all

% grab all .mat sessions
dm = dir('*.mat');
numsess = length(dm);

% grab all .plx sessions
dp = dir('*.plx');
plex_vec = [1:2:31 2:2:32];

% choose experiment
choice = questdlg('Which experiment?', ...
	'Experiment Menu', ...
	'Probes','MGS','MGS');
% Handle response
switch choice
    case 'Probes'
        disp([choice ' coming right up.'])
        expID = 1;
    case 'MGS'
        disp([choice ' coming right up.'])
        expID = 2;
end



psthID=0;
for s = 1:numsess
    % get mat sessname
    sessname = dm(s).name;
    data.sess(s).name = sessname;
    % load the mat file
    load(sessname)
    % preprocess
    Trials = saccade_detector(Trials);
    Trials = cleanTrialsStruct_v2(Trials);
    
    % get channel info
    chan=find(~cellfun(@isempty,{Trials(1).Electrodes.Units}));
    plex_chan = find(plex_vec==chan);
    
    % get plx sessname
    plxSess = dp(s).name;
    
    % grab the PSTHs (saccade locked)
%     PSTH = radial_PSacTH(Trials);
    numUnits = 1;
    
%     if expID==1
%         % grab the probe locked PSTHs
%         pPSTH = radial_PProbeTH(Trials);
%     elseif expID==2
%         % grab the stim locked PSTHs
%         pPSTH = radial_PStimTH(Trials,chan,0);
%     end
    
%     % grab the downsampled movement RF estimation
%     dsFactor=16;
%     dsRF = getDownsampledRF(Trials,chan,dsFactor);
    
    % concatenate PSTHs
    for u = 1:numUnits

        
%         allpsth=[];
%         peakpsth=[];
%         ppeakpsth=[];
%         for b = 1:length(curunit)
%             curunit = PSTH;
%             p_curunit = pPSTH(1).bin;
%             allpsth = [allpsth PSTH(b).y];
%             peakave = mean(curunit(b).data(curunit(b).time>-80 & curunit(b).time<0));
%             ppeakave = mean(p_curunit(b).data(p_curunit(b).time>50 & p_curunit(b).time<150));
%             peakpsth = [peakpsth peakave];
%             ppeakpsth = [ppeakpsth ppeakave];
%             
%         end
%         % normalize
%         peakpsth = peakpsth ./ max(peakpsth);
%         ppeakpsth = ppeakpsth ./ max(ppeakpsth);
%         bpeakpsth = [peakpsth ppeakpsth];
        
        % grab plx info
        [n, npw, ts, wave2] = plx_waves_v(plxSess, plex_chan, u-1);
        
        % store
        psthID = psthID+1;
        data.psth_mat(psthID,:) = allpsth;
        data.sess(s).unit(u-1).psthID = psthID;
        data.sess_mat{psthID} = [sessname(1:end-4) '_u' num2str(u-1)]; 
        data.wf_mat(psthID,:) = median(wave2);
        data.peak_psth_mat(psthID,:) = bpeakpsth;
        data.dsRF_mat(psthID,:)=dsRF{u-1}.Bs(:)';
    end

    clearvars -except data s dm numsess psthID dp plex_vec expID
end

psth_mat = data.psth_mat;
sess = data.sess;
sess_mat = data.sess_mat;
wf_mat = data.wf_mat;
peak_psth_mat = data.peak_psth_mat;
dsRF_mat = data.dsRF_mat;

close all
%% waveform comparisons
[mx,mxi]=max(wf_mat');
[mi,mii]=min(wf_mat');
ms1 = mxi-mii; % time to peak minus time to trough
ms2=mx./(mx-mi); % peak normalized by peak-trough
ms3=mi./(mx-mi); % trough normalized by peak-trough
ms4 = mx./abs(mi); % ratio of peak/trough values


%% hierarchical clustering
w1 = .4;
w2 = 1;
w3 = 1;
Y = pdist(peak_psth_mat);
Y2 = pdist(wf_mat);
Y3 = pdist(dsRF_mat);

YS = ((Y.*w1) + (Y2.*w2) + (Y3.*w3)) / 3;
Z = linkage(YS);

clusterInfo = getClusters(Z,sess_mat);

clusterInfo.wf_mat = wf_mat;



%% now run session combine script
sessCombine





