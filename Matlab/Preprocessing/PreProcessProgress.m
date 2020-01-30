    function PreProcessProgress()
% PreProcessProgress.m
%
% This script will search in the current directory and all subdirectories
% for plexon files. It will then divide them according to which step in
% preprocessing they are currently at. It then asks the user which files
% they would like to see. 
% 
% Daniel Wood, 4/5/18
% 
% NOTE: There may be some errors in the way that files were saved. For 
% example, a bunch of files in 
% 'C:\Data\Jiji\FlashProbe\PROCESSED_search_probe\c14_GMR27\spl_d1' had
% merged mat files that appear to be split and sorted, but the
% corresponding plexon files are only labeled as split, not sorted. This
% could be a labeling issue, or it could be that the person didn't ever
% sort the plexon file. You can use this script to find those files. 


%% JUST ASSUME THAT WE WANT TO BE IN THE HOME DIRECTORY
% Otherwise the function isn't very useful
homedir = experimentHomeFolder;
cd(homedir)

%% GET ALL PLEXON FILES INTO A SINGLE ARRAY
plexonfiles = dir('**/*.pl*');
names = {plexonfiles.name};
folders = {plexonfiles.folder};


%% FIND ALL THE THROWAWAY FILES THAT YOU DON'T NEED

% bad files
bad = contains(folders,'bad files');
% ead files
ead = contains(folders,'EAD_files');
% old channel files
oldchan = contains(folders,'depth');
% old task files
oldtask = contains(folders,'OLD TASK');



%% NOW FIND THE FILES WITH LABELS OF INTEREST

% find all the split (only) plexon files
% spl1 = contains(names,'_spl_c');
spl = cell2mat(cellfun(@(x) strcmp(x(15:17),'spl'), names, 'UniformOutput', false)) & ...
    ~ead;
% ALTERNATIVE TO 'contains' (for earlier MATLAB versions)
% spl = ~cellfun(@isempty,regexp(names,'_spl_c'));
spl_base = cellfun(@(x) x(1:13), names(spl), 'UniformOutput', false);
spl_find = find(spl);

% find all the split and sorted plexon files
srtspl = contains(names,'_srt_spl') & ~ead;
% ALTERNATIVE TO 'contains'
% srtspl = ~cellfun(@isempty,regexp(names,'_srt_spl'));
srtspl_base = cellfun(@(x) x(1:13), names(srtspl), 'UniformOutput', false);
srtspl_find = find(srtspl);


% find all the raw plexon files
raw = ~(spl | srtspl | ead | bad | oldchan | oldtask);
raw_base = cellfun(@(x) x(1:13), names(raw), 'UniformOutput', false);
raw_find = find(raw);


%% IDENTIFY WHICH FILES NEED THE NEXT STEP IN PREPROCESSING

% 1. SPLITTING BY CHANNEL
% For the files to split, you need to find all the raw files whose base
% filenames aren't already tagged as having been split or sorted.
% Make sure you look for the setdiff between the raw files and the
% conjoined spl and srtspl files
[c,ia_split] = setdiff(raw_base,union(spl_base, srtspl_base));
to_split_names = names(raw_find(ia_split));
to_split_folders = cellfun(@(x) x(24:end), folders(raw_find(ia_split)), 'UniformOutput', false);



% 2. SORTING
% For the files to sort, you need to find all the split files whose base
% filenames aren't already tagged as having been sorted. Make sure you are
% comparing the full filename here, since it is the specific channels and
% not just the base filenames that we are interested in.
% first, change the names in the srtspl list so that they look like they
% were only split and not also sorted
fakesplit = cellfun(@(x) x([1:13 18:end]), names(srtspl), 'UniformOutput', false);
[c,ia_sort] = setdiff(names(spl),fakesplit);
to_sort_names = names(spl_find(ia_sort));
to_sort_folders = cellfun(@(x) x(24:end), folders(spl_find(ia_sort)), 'UniformOutput', false);



% 3. MERGING
% for the files to merge, you need to find all the sorted files without a
% corresponding mat file (or set of mat files if it has already been split
% into units). 
% First, get all the mat files
matfiles = dir('**/*.mat');
matnames = {matfiles.name};
matfolders = {matfiles.folder};
% Now, identify all the uninteresting mat files in there
% find stuff that isn't an actual session file
goodmatnames = contains(matnames,{'m15','m18'})& ...
    ~contains(matnames,{'m15_','m18_'}) & ...
    ~contains(matnames,{'m15RF','m18RF'}) & ...
    ~contains(matnames,'_u') & ...
    contains(matnames,'_srt_spl_');
gmn_find = find(goodmatnames);
matnames_nox = cellfun(@(x) x(1:(end-4)),matnames(goodmatnames), 'UniformOutput',false);
srtspl_nox = cellfun(@(x) x(1:(end-4)), names(srtspl), 'UniformOutput', false);
[c,ia_merge] = setdiff(srtspl_nox, matnames_nox);
to_merge_names = names(srtspl_find(ia_merge));
to_merge_folders = cellfun(@(x) x(24:end), folders(srtspl_find(ia_merge)), 'UniformOutput', false);



% 4. SPLITTING BY UNIT
unit_splits = contains(matnames,{'m15','m18'})& ...
    ~contains(matnames,{'m15_','m18_'}) & ...
    ~contains(matnames,{'m15RF','m18RF'}) & ...
    contains(matnames,'_u');
us_find = find(unit_splits);
matnames_no_u = cellfun(@(x) x(1:(end-8)),matnames(unit_splits), 'UniformOutput',false);
% Which merged .mat files have already been split into their units? Spit
% out a list of the original .mat files that have alread been split
[c, uisct] = intersect(matnames_nox, matnames_no_u);
unit_done = matnames(gmn_find(uisct));
unit_done_folder = cellfun(@(x) x(24:end), matfolders(gmn_find(uisct)), 'UniformOutput', false);
% Which merged .mat files still need to be split into units? Give a list of
% the original mat files that haven't been split yet
[c, udiff] = setdiff(matnames_nox, unique(matnames_no_u));
unit_needed = matnames(gmn_find(udiff));
unit_needed_folder = cellfun(@(x) x(24:end), matfolders(gmn_find(udiff)), 'UniformOutput', false);


% 5. WHICH FILES HAVE BEEN SORTED, BUT THE ORIGINAL SPLIT FILE WASN'T DELETED
[c,ia_sorted] = intersect(names(spl),fakesplit);
already_sorted = names(spl_find(ia_sorted));
sorted_folders = cellfun(@(x) x(24:end), folders(spl_find(ia_sorted)), 'UniformOutput', false);



%% ASK AND DISPLAY

% Ask user what they want to see
answerlist = {'PLX files to split',...
    'PLX files to sort',...
    'Sorted _spl_ PLX files to delete',...
    'PLX files to merge',...
    'MAT files to split by unit',...
    'MAT files already split by unit'};
answerID = listdlg('ListString', answerlist,...
    'SelectionMode','single',...
    'ListSize',[350 300],...
    'Name','What do you want to see?');
answer = answerlist{answerID};

% Handle response
switch answer
    case 'PLX files to split'
        [b,i]=sort(to_split_folders);
        disp(['Displaying list of ' num2str(length(to_split_names)) ' ' answer '.'])
        disp([to_split_names(i)',to_split_folders(i)'])
    case 'PLX files to sort'
        [b,i]=sort(to_sort_folders);
        disp(['Displaying list of ' num2str(length(to_sort_names)) ' ' answer '.'])
        disp([to_sort_names(i)',to_sort_folders(i)'])
    case 'Sorted _spl_ PLX files to delete'
        [b,i]=sort(sorted_folders);
        disp(['Displaying list of ' num2str(length(already_sorted)) ' ' answer '.'])
        disp([already_sorted(i)',sorted_folders(i)'])
    case 'PLX files to merge'
        [b,i]=sort(to_merge_folders);
        disp(['Displaying list of ' num2str(length(to_merge_names)) ' ' answer '.'])
        disp([to_merge_names(i)',to_merge_folders(i)'])
    case 'MAT files to split by unit'
        [b,i]=sort(unit_needed_folder);
        disp(['Displaying list of ' num2str(length(unit_needed)) ' ' answer '.'])
        disp([unit_needed(i)', unit_needed_folder(i)'])
    case 'MAT files already split by unit'
        [b,i]=sort(unit_done_folder);
        disp(['Displaying list of ' num2str(length(unit_done)) ' ' answer '.'])
        disp([unit_done(i)', unit_done_folder(i)'])
end

