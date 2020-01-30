% GLM probe analysis

% load raw
fname = 'm15_d2_c21';

% preprocessing
Trials = saccade_detector(Trials);

Trials = cleanTrials(Trials);

Trials = convert_to_absolute_time(Trials);

[probes,fixations] = makeProbeStruct_GLM(Trials);

% save as csv
extract_spikes_csv(Trials,fname)
writetable(probes,['probes_' fname '.csv'])
writetable(fixations,['fixations_' fname '.csv'])