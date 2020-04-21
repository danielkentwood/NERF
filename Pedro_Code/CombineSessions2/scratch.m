%processed_search_probe_path = '/data2/ribeiro/FEF/Data/FlashProbe/Jiji/PROCESSED_search_probe';
processed_search_probe_path = '/data2/ribeiro/FEF/Data/FlashProbe/Maeve/PROCESSED_search_probe';
plexonfiles = dir(sprintf('%s/**/spl_d*/*.pl*',processed_search_probe_path));

%PARAMS
spike_bins = [0,10,20,40,80,160,320,inf]/1000;

[all_average_waveform_PC,all_isi_hist,unit_groups,plx_source_file,unit_number,broken_files] = get_features_for_matching(plexonfiles,spike_bins);



%%


S = struct();
S.all_average_waveform_PC = all_average_waveform_PC;
S.all_isi_hist = all_isi_hist;
S.unit_groups = unit_groups;
S.plx_source_file = plx_source_file;
S.unit_number = unit_number;