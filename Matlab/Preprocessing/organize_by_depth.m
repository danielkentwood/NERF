function organize_by_depth(monkey,task)
% organize_by_depth

switch nargin
    case 0
        % choose monkey
        monkey = questdlg('Which Monkey?', ...
            'Monkey Menu', ...
            'Maeve','Jiji','Maeve');
        task=0;
    case 1
        task=0;
end

%% choose experiment and get info about depths
[task, chan] = trodeChangeMap(monkey,task,0);
% make a list of filenames, along with info about channel, depth
ctr = 1;
for ch = 1:length(chan)
    cur_chan = chan(ch);
    for dp = 1:length(cur_chan.depth)
        for fn = 1:length(cur_chan.group{dp})
            fnames{ctr} = cur_chan.group{dp}{fn};
            finfo(ctr,1) = ch;
            finfo(ctr,2) = dp;
            ctr = ctr+1;
        end
    end
end

%% move all split files to the correct PROCESSED task folder
homedir = experimentHomeFolder(monkey);
raw_dir = [homedir 'RAW_' task];
processed_dir = [homedir 'PROCESSED_' task];

% cd(raw_dir)
% % get all plexon files
% plexonfiles = dir('**/*.pl*');
% names = {plexonfiles.name};
% folders = {plexonfiles.folder};
% spl = contains(names,'spl') & ...
%     ~contains(folders, 'EAD_files');
% spl_names = names(spl);
% spl_folders = folders(spl);
% 
% for i = 1:length(spl_names)
%     status = movefile([spl_folders{i} '\' spl_names{i}],processed_dir);
% end

%% get list of all files that have been split and split_sorted
% go to the experiment directory
cd(processed_dir)
% get all plexon files
plexonfiles = dir('**/*.pl*');
names = {plexonfiles.name};
folders = {plexonfiles.folder};
spl = contains(names,'spl') & ...
    ~contains(folders, 'EAD_files');
spl_names = names(spl);
spl_folders = folders(spl);

GMR_chans = [1:2:31 2:2:32];
chan_nums = cell2mat(cellfun(@(x,y) str2num(x(y+3:y+4)), names(spl), regexp(names(spl),'_c\d*'), 'UniformOutput', false));
chan_nums_GMR = GMR_chans(chan_nums);

% get all mat files
matfiles = dir('**/*.mat');
matnames = {matfiles.name};
matfolders = {matfiles.folder};
spl_mat = contains(matnames,'spl');
spl_mat_names = matnames(spl_mat);
spl_mat_names_nox = cellfun(@(x) x(1:26), spl_mat_names, 'UniformOutput', false);
spl_mat_folders = matfolders(spl_mat);
spl_mat_folders_trunc = cellfun(@(x) x(25:end), spl_mat_folders,'UniformOutput',false);

%% make sure they are in the correct depth folder

% do plexon first
for i = 1:length(spl_names)
    % identify an existing file and its channel
    fn = spl_names{i};
    fn_base = fn(1:13);
    pl_chan = chan_nums(i);
    gmr_chan = chan_nums_GMR(i);
    
    % figure out which depth it should be at
    idx = strcmp(fnames,fn_base) & gmr_chan==finfo(:,1)';
    if sum(idx)==1
        depth = finfo(idx,2);
    elseif sum(idx)==0
        error('Error. Mismatch between depth list and file list')
        % This usually means that you have a base plexon file in the processed
        % folder that isn't in the raw folder. Check the "Bad" Plexon
        % folder for the missing file from the raw folder?
    elseif sum(idx)>1
        % currently the function doesn't handle this. You just have to go and
        % delete the duplicate file in the RAW folder. Hesitant to automate
        % this step because it involves deleting.
        error('MyComponent:TooManyFiles',...
            ['Error. \nMore than one version of file in RAW folder. \n' ...
            'Filename: %s.'],fn_base)
    end
    
    % get folder names
    true_folder = spl_folders{i};
    pl_str = ['0' num2str(pl_chan)]; pl_str = pl_str(end-1:end);
    gmr_str = ['0' num2str(gmr_chan)]; gmr_str = gmr_str(end-1:end);
    chan_folder = [homedir 'PROCESSED_' task '\c' pl_str '_GMR' gmr_str];
    
    % verify that the correct folder exists
    depth_folder = ['spl_d' num2str(depth)];
    chan_depth_folder = fullfile(chan_folder,depth_folder);
    f_exist = exist(chan_depth_folder); % this will return a 7 if the folder already exists
    
    % create folder if it doesn't exist
    if f_exist~=7
        [success, message, messID] = mkdir(chan_folder,depth_folder);
        if success ~=1
            disp(message)
        end
    end
    
    % check if it is in the correct folder
    already_in_correct_folder = strcmp(true_folder,chan_depth_folder);
    
    % if it isn't, put it there
    if ~already_in_correct_folder
        status = movefile([true_folder '\' fn],chan_depth_folder);
    end
    
    
    % DEAL WITH .MAT FILES
    % See if there is a .mat file (or multiple files) corresponding to current .plx file
    fn_nox = fn(1:end-4);
    mat_matches = find(strcmp(spl_mat_names_nox, fn_nox));
    for nm = 1:length(mat_matches)
        cur_mat = spl_mat_names{mat_matches(nm)};
        cur_mat_folder = spl_mat_folders{mat_matches(nm)};
        
        % is the mat file already in the correct folder?
        mat_in_correct_folder = strcmp(cur_mat_folder,chan_depth_folder);
        
        % if it isn't, put it there
        if ~mat_in_correct_folder
            status = movefile([cur_mat_folder '\' cur_mat],chan_depth_folder);
        end
    end
    
    
end
