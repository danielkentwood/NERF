% batch integrate
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% What it does:
%%% batch_integrate goes through a given depth folder
%%% and builds the data files we need, out of the sorted Plex files -
%%% things like "m5555555_001_srt_spl_c012.plx".
%
% To use batch integrate,
% - First have a folder which has *all* of its Plex files sorted already,
% - run batch_integrate,
% - navigate to the folder that has the Plex files in it, and
% - hit Select Folder.
%
% There are some error messages that currently come up, but you shouldn't
% be too worried about the "invalid ecode" ones.
%
% If any other warning/error messages come up, look at the Google Drive
% notes to see if there's any help there. Otherwise make a note of it
% and ask someone else to help out with figuring out what's going on.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear;clc

% define starting directory
main_path = pwd;

% define GMR number convention
GMR_nums=[1:2:31 2:2:32];



% get REX directory
homedir = experimentHomeFolder;
cd([homedir '\REX_Data'])

rex_fpath=[pwd '\'];
rex_path=[rex_fpath 'm1*.*A'];
rexDir = dir(rex_path);
rex_names = {rexDir.name};
rexList = cellfun(@(x) x(1:13), rex_names, 'un', 0);
cd(main_path)

% get all plexon files in or below the current directory.
plx_files = dir('**/*.pl*');
plx_names = {plx_files.name};
plx_paths = {plx_files.folder};
% look for files that have already been sorted and split
plx_ss = find(contains(plx_names,'_srt_spl'));
% now get the base file ID of these
plx_base = cellfun(@(x) x(1:end-4), plx_names(plx_ss), 'un', 0);

% Overwrite?
choice = questdlg('Overwrite existing integrated files?', ...
    'Overwrite?', ...
    'Yes','No','No');
% Handle response
switch choice
    case 'Yes'
        plx_fnames = plx_names(plx_ss);
        plx_fpaths = plx_paths(plx_ss);
        plexListPre = cellfun(@(x) x(1:13), plex_fnames, 'UniformOutput', false);
        
    case 'No'
        mat_files = dir('**/*.mat');
        mat_names = {mat_files.name};
        mat_ss = find(contains(mat_names,'_srt_spl'));
        mat_base = cellfun(@(x) x(1:26), mat_names(mat_ss), 'un', 0);
        % now find the intersect between these two
        [is_files, ia] = setdiff(plx_base,mat_base);
        % get the names and directory paths for the duplicate files
        plx_to_merge_idx = plx_ss(contains(plx_names(plx_ss),is_files));
        plx_fnames = plx_names(plx_to_merge_idx);
        plx_fpaths = plx_paths(plx_to_merge_idx);
        % convert to REX format for comparison
        plexListPre = cellfun(@(x) x(1:13), plx_fnames, 'UniformOutput', false);
        
        % display list of files to merge
        p2merge_path_nox = cellfun(@(x) x(25:end), plx_fpaths, 'un', 0);
        disp([plx_fnames' p2merge_path_nox'])
        disp('The files listed above have not yet been merged.')
end
fakeRexList = cellfun(@(x) strrep(x,'_','.'), plexListPre, 'UniformOutput', false);

% find match between rexList and plexList
rex_fnames = cellfun(@(x) rex_names{(contains(rexList,x))}, fakeRexList, 'un', 0);

% find the events and analog file(s)
ead_fpath=[homedir 'EAD_files'];
EADDir = dir([ead_fpath '\*.pl*']);
eadnames = {EADDir.name};
eadnames_rex = cellfun(@(x) strrep(x,'_','.'), cellfun(@(x) x(1:13), eadnames, 'un', 0), 'un', 0)';
ead_fnames = cellfun(@(x) eadnames{(contains(eadnames_rex,x))}, fakeRexList, 'un', 0);

% START THE LOOP HERE
for i = 1:length(plx_fnames)
    % get plexon variables
    plex_fname = plx_fnames{i};
    plex_fpath = plx_fpaths{i};
    cd(plex_fpath)
    % get rex and ead variables
    rex_fname = rex_fnames{i};
    ead_fname = ead_fnames{i};
    % open ead file
    Strobed = open_ead([ead_fpath '\' ead_fname]);
    % set output name and path
    output_fname=[plex_fname(1:end-4) '.mat'];
    output_path=plex_fpath;
    
    % open the REX file
    combineREX
    
    % open the PLEX files
    batch_makeTrialPlx2
    
    % combine them
    combine_REX_PLEX
    
    % Some housekeeping
    Trials=rmfield(Trials,'all_events'); % this saves a ton of space, not sure if this field is ever used
    Trials=rmfield(Trials,'PLEX_Events');
    to_del=[];
    for ii=1:length(Trials)
        if isempty(Trials(ii).Signals)
            to_del(end+1)=ii;
        else
            Trials(ii).Signals(3:4)=[]; % remove unnecessary joystick position channels
        end
    end
    Trials(to_del)=[];
    
    %% Save file
    save([output_path '\' output_fname],'Trials','-v7.3');
    clear Trials
    
    % report on progress
    disp('-----------------------------')
    disp('-----------------------------')
    disp([num2str(i) ' of ' num2str(length(plx_fnames)) ' files processed']) % I'd like to add a line here to output the name of the next file to be processed. Hm.
    disp('-----------------------------')
    disp('-----------------------------')
    
    % create temporary directory (this becomes important later to help debug
    % mrdr crashing from multiple uses)
    mkdir(pwd,'tempMatDir');
    cd tempMatDir
    save curVars i plx_fnames plx_fpaths ead_fnames rex_fpath rex_fnames Strobed ead_fpath
    % now clear all (NOTE: clear all is necessary to prevent mrdr from
    % crashing)
    pause(.5)
    clear all
    close all
    % and reload
    load curVars
    cd ..
    rmdir('tempMatDir','s');
end
clear
disp('Conversion complete!')