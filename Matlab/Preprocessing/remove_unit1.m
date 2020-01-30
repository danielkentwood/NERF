% get rid of unit 1 (it only has unsorted spikes)

% Navigate to the directory tree you want to delete files in
% This will delete all of the first units for the current directory and all
% subdirectories.

clear;

% first, get all the processed .mat files
mats = dir('**/*.mat');
mats = mats(contains({mats.name},'_u01'));
names = {mats.name};
folders = {mats.folder};

% delete them
for i = 1:length(names)
    curfile = fullfile(folders{i},names{i});
    disp(['Deleting ' curfile])
    delete(curfile)
end

disp('All done deleting unsorted units')