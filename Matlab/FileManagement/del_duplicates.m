clear;clc;

filetype = '.pl*';
files = dir(['**/*' filetype]);
names = {files.name};
paths = {files.folder};

% first, look for files that have already been sorted and split
sortsplit = find(contains(names,'_srt_spl'));
% now, look for files that have only been split
pat = '\d_spl_c';
justsplit = find(~cellfun(@isempty,regexp(names,pat)));

% now get the base file ID of these
ss_base = cellfun(@(x) strrep(x,'_srt_spl_','_'),names(sortsplit), 'un', 0);
js_base = cellfun(@(x) strrep(x,'_spl_','_'),names(justsplit), 'un', 0);

% now find the intersect between these two
is_files = intersect(ss_base,js_base);
% put back in the spl tag
is_spl = cellfun(@(x) strrep(x,'_c','_spl_c'),is_files, 'un', 0);
% get the names and directory paths for the duplicate files
dupes = justsplit(contains(names(justsplit),is_spl));
dup_names = names(dupes);
dup_paths = paths(dupes);

% list all the files that you are about to delete, and ask the user
% if they want to delete them.
disp('We will be deleting the following files:')
disp('')

for i = 1:length(dup_names)
    fid = [dup_paths{i} '\' dup_names{i}];
    disp(fid);
end

delFlag = input('Do you want to delete the files listed above? Enter 1 for yes, 0 for no:');
if delFlag
    % now go through and delete all the files that are no longer needed
    for i = 1:length(dup_names)
        fid = [dup_paths{i} '\' dup_names{i}];
        try 
            delete(fid);
            disp(['Deleted ' fid]);
        catch
            warning([dup_names{i} ' was not deleted!'])
        end
    end
else
    disp('Entire hard drive successfully deleted.') 
    pause(3)
    disp('Just kidding. Nothing will be deleted.')
end