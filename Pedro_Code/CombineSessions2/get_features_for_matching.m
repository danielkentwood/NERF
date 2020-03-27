%processed_search_probe_path = '/data2/ribeiro/FEF/Data/FlashProbe/Jiji/PROCESSED_search_probe';
%processed_search_probe_path = '/data2/ribeiro/FEF/Data/FlashProbe/Maeve/PROCESSED_search_probe';

%plexonfiles = dir(sprintf('%s/**/spl_d*/*.pl*',processed_search_probe_path));


function [all_average_waveform_PC,all_isi_hist,unit_group_count,broken_files] = get_features_for_matching(plexonfiles,spike_bins)


all_average_waveform_unit = [];
all_isi_hist = [];
broken_files = [];
unit_groups = [];%stores the same index for all units found under the same folder and depth

unit_groups_dictionary = containers.Map(); %keeps track of which folders we have seen
unit_group_count = 0;

for file_idx = 1:length(plexonfiles)
    disp(file_idx/length(plexonfiles));
    cur_plexon_file = plexonfiles(file_idx);

    cur_path_to_plx = sprintf('%s/%s',cur_plexon_file.folder,cur_plexon_file.name);
    % get channel
    baseTrode = extractAfter(cur_plexon_file.folder,'PROCESSED_search_probe/c');
    cur_channel = str2num(baseTrode(1:2));

    %Get used units
    cur_mat_files = dir(sprintf('%s/%s*.mat',cur_plexon_file.folder,cur_plexon_file.name(1:end-4)));
    cur_units = [];
    for i = 1:length(cur_mat_files)
        tmp = extractAfter(cur_mat_files(i).name,'_u');
        %TODO: MAKE SURE THIS IS CORRECT!!!!!!!!!!!!!!!!!
        %TODO: MAKE SURE THIS IS CORRECT!!!!!!!!!!!!!!!!!
        %TODO: MAKE SURE THIS IS CORRECT!!!!!!!!!!!!!!!!!
        cur_units =[cur_units ,str2num(tmp(1:2))-1]; %TODO: MAKE SURE THIS IS CORRECT!!!!!!!!!!!!!!!!!
        %TODO: MAKE SURE THIS IS CORRECT!!!!!!!!!!!!!!!!!
        %TODO: MAKE SURE THIS IS CORRECT!!!!!!!!!!!!!!!!!
        %TODO: MAKE SURE THIS IS CORRECT!!!!!!!!!!!!!!!!!
    end

    %extract_features
    for unit = cur_units
        [n, npw, ts, wave] = plx_waves_v(cur_path_to_plx, cur_channel, unit);

        if wave == -1
            broken_files = [broken_files;cur_path_to_plx];
            break
        end
        
        %figure
        %histogram(diff(ts),'BinEdges',spike_bins)
        isi_hist = histcounts(diff(ts),'BinEdges',spike_bins);
        all_isi_hist = [all_isi_hist;isi_hist];
        
        average_waveform_unit = mean(wave,1);
        all_average_waveform_unit = [all_average_waveform_unit;average_waveform_unit];
        [coeff,score,latent,tsquared,explained,mu] = pca(all_average_waveform_unit);
        
        explained_cumsum = cumsum(explained);
        
        num_pca_components_to_use = find(explained_cumsum>=99,1);
        
        all_average_waveform_PC = score(:,1:num_pca_components_to_use);
        
        
        if unit_groups_dictionary.isKey(cur_plexon_file.folder)
            unit_groups = [unit_groups;unit_groups_dictionary(cur_plexon_file.folder)];
        else
            unit_groups_dictionary(cur_plexon_file.folder) = unit_group_count;
            unit_group_count = unit_group_count+1;
            unit_groups = [unit_groups;unit_groups_dictionary(cur_plexon_file.folder)];
        end
        
        
    end
    
end


disp("done")

end


