%processed_search_probe_path = '/data2/ribeiro/FEF/Data/FlashProbe/Jiji/PROCESSED_search_probe';
processed_search_probe_path = '/data2/ribeiro/FEF/Data/FlashProbe/Maeve/PROCESSED_search_probe';
plexonfiles = dir(sprintf('%s/**/spl_d*/*.pl*',processed_search_probe_path));

%PARAMS
spike_bins = [0,10,20,40,80,160,320,inf]/1000;

[all_average_waveform_PC,all_isi_hist,unit_group_count,broken_files] = get_features_for_matching(plexonfiles,spike_bins);




