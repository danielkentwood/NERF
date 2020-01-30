


mats = dir('**/*.mat');
fids = find(~cellfun(@isempty,regexp({mats.name},'merge_unit')));
merge_mats = mats(fids);
names = {merge_mats.name};
paths = {merge_mats.folder};


exploit=[];
explore=[];

for cur_file_id = 1:length(names)
    fname = ['RF_info_unit_' names{cur_file_id}(end-4) '.mat'];
    % check if file exists
    if exist(fullfile(paths{cur_file_id},fname),'file')==2
        disp(['Loading ' fullfile(paths{cur_file_id},fname) '...'])
        load(fullfile(paths{cur_file_id},fname))
        disp('Finished loading')
    else
        disp(['Loading ' fullfile(paths{cur_file_id},names{cur_file_id})])
        load(fullfile(paths{cur_file_id},names{cur_file_id}))
        extract_remapping
        % save stuff
        save(fullfile(paths{cur_file_id},fname),'exploreRF','exploitRF','psRF')
        disp('RF info saved')
    end
    
    exploit(cur_file_id,:) = exploitRF.RFxy_keep(1,:);
    explore(cur_file_id,:) = exploreRF.RFxy_keep(1,:);
%     trode(cur_file_id,:) = GMR;
    
    clear sessList Trials probe
end

