
% changeFileNames(path,bad_str,good_str,filetype,verbose)
% -path is the directory where you want to change 
% -filetype is a selector string (e.g., '*.jpg')
% default values:
% filetype='*.*';
% -verbose=true;
%
% If you put '**\*' as the path argument, this function will go through the
% current directory and all sub-directories, and change the filenames as
% requested. This relies on functionality available in MATLAB 2018+.
%
% Daniel Wood, 2/27/18

function changeFileNames(path,bad_str,good_str,filetype,verbose)

% defaults
if nargin<3
    error('changeFileNames:TooFewInputs',...
        'Requires at least 3 inputs');
end
switch nargin
    case 3
        filetype='*.*';
        verbose=true;
    case 4
        verbose=true;
end

curpath = pwd;

if strcmp(path,'**\*')
    dm = dir(['**\' filetype]);
else
    cd(path)
    dm = dir(filetype);
end

names = {dm.name};
folders = {dm.folder};
fids = find(contains(names,bad_str));

for i = fids
    % get current filename
    curfile = names{i};
    
    % find where the bad string is, and how many characters are before and
    % after it
    idx = regexp(curfile,bad_str);
    prebad = idx-1;
    postbad = length(curfile)-(idx+(length(bad_str)-1));
    
    % replace the bad string with the good string
    if isempty(postbad)
        newfile = [curfile(1:prebad) good_str];
    else 
        newfile = [curfile(1:prebad) good_str curfile((end-(postbad-1)):end)];
    end
    
    % rename the file
    [success,~,~] = movefile([folders{i} '\' curfile], [folders{i} '\' newfile]);
    
    % keep track of success and failure
    if verbose
        if success
            disp([curfile ' successfully renamed to ' newfile]);
        else
            disp('Renaming failed')
        end
    end
end

cd(curpath)

