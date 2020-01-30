% move_session_files


% choose monkey
monkey = questdlg('Which Monkey?', ...
    'Monkey Menu', ...
    'Maeve','Jiji','Maeve');

%% which task

% Ask user what they want to see
answerlist = {'simple_probe','search_probe','mgs'};
answerID = listdlg('ListString', answerlist,...
    'SelectionMode','single',...
    'Name','Select a task',...
    'ListSize',[300 300]);
task = answerlist{answerID};

% tf = 1;
% valid_tasks = {'mgs','search_probe','simple_probe'};
% while tf
%     task = input('Enter task (e.g., ''search_probe''): ');
%     if sum(strcmp(task,valid_tasks))>0
%         tf=0;
%     else
%         disp('ERROR: task must be one of the following:')
%         disp(valid_tasks)
%         disp('')
%     end
% end

%% Define directories
% define home directory
homedir = [experimentHomeFolder(monkey) 'RAW_' task];
cd(homedir)

% define ead directory
ead_dir = [experimentHomeFolder(monkey) 'EAD_files'];

%% deal with ead files
% first get all ead files
ead_names = dir('*spl_ead.pl*');

% move ead files
for i = 1:length(ead_names)
    movefile([homedir '\' ead_names(i).name],ead_dir)
end

%% move files
% now cycle through all possible channels, and move them to their
% respective folders

% define spike session directory
sessdir = [experimentHomeFolder(monkey) 'PROCESSED_' task];
% find existing directories
cd(sessdir)
ex_dir = dir;
ex_dir(~[ex_dir.isdir])=[];
ex_dir_list = {ex_dir.name};

numbase = '000';
plex_vec = [1:2:31 2:2:32];
for i = 1:32
    % get all session files for current channel
    cd(homedir)
    chanstr=num2str(i);
    chanfull=numbase;
    chanfull(end-(length(chanstr)-1):end)=chanstr;
    cursess_dir = dir(['*spl_c' chanfull '.pl*']);
    % if there aren't any, move on
    if isempty(cursess_dir)
        continue
    end
    
    % now see if the target folder exists
    cd(sessdir)
    gmrstr=num2str(plex_vec(i));
    gmrfull=numbase(2:3);
    gmrfull(end-(length(gmrstr)-1):end)=gmrstr;
    dir_name=['c' chanfull(2:3) '_GMR' gmrfull];
    exist_idx = find(cell2mat(strfind(ex_dir_list,dir_name)));
    % if it doesn't exist, make it
    if isempty(exist_idx)
        mkdir(dir_name)
    end
    
    % now move the files
    cd(homedir)
    for csd = 1:length(cursess_dir)
        movefile([homedir '\' cursess_dir(csd).name],[sessdir '\' dir_name])
    end
end

%% Organize by depth
% As soon as 'organize_by_depth.m' is complete, run it here
organize_by_depth(monkey, task);


