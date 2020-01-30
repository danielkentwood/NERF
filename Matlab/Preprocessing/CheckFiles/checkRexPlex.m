% check integrity of REX and PLEXON files 

% create a temporary directory to hold the mat files
curdir = pwd;

if (7 ~= exist([curdir '\tempMatDir'])) % Not really sure why it's 7, but okay.
    mkdir(pwd,'tempMatDir');
end

manual=0;

homedir = experimentHomeFolder;
cd(homedir)

% Open REX file manually.
[plex_fnames,plex_fpath] = uigetfile('*.*','Select the Plexon file','MultiSelect','on');

if ischar(plex_fnames)
    plex_fnames={plex_fnames};
end

rex_path = [homedir '\REX_Data\'];        

for i = 1:length(plex_fnames)
    cd([curdir '\tempMatDir'])
    % save current workspace
    save curVars
    % now clear (clear all is necessary to prevent mrdr from crashing)
    clear all
    % and reload
    load curVars
    
    cd(rex_path)
    plex_fname = plex_fnames{i};
    if manual
        % Open REX file manually
        [rex_fname,rex_path] = uigetfile('*.*A','Select the REX file','MultiSelect','on');
    else
        rex_fname=[plex_fname(1:9) '.' plex_fname(11:13) 'A'];
    end
    
    rex2matlab
    plexCheck
    
    out(i).rt = num2str(length(REX_Trials));
    out(i).pl = num2str(length(tsad));
    out(i).ps = num2str(length(start_trials));
    out(i).pe = num2str(length(end_trials));
    out(i).pn = plex_fname;
end


% Is this the output for bad files? I think so, but I'm not sure.
for i = 1:length(out)
    
disp('---------------------------------------------------')
disp('---------------------------------------------------')
disp(['Number of Rex Trials: ' out(i).rt])
disp(['Number of Plexon LFPs: ' out(i).pl])
disp(['Number of Plexon E-code starts: ' out(i).ps])
disp(['Number of Plexon E-code ends: ' out(i).pe])
disp(out(i).pn)
disp('---------------------------------------------------')
disp('---------------------------------------------------')

end


% remove the directory
cd([curdir '\tempMatDir\..'])
rmdir('tempMatDir','s');

cd(homedir)
load handel.mat;
sound(y);
clear all


% disp('---------------------------------------------------')
% disp('---------------------------------------------------')
% disp(['Number of Rex Trials: ' num2str(length(REX_Trials))])
% disp(['Number of Plexon LFPs: ' num2str(length(tsad))])
% disp(['Number of Plexon E-code starts: ' num2str(length(start_trials))])
% disp(['Number of Plexon E-code ends: ' num2str(length(end_trials))])
% disp(plex_fname)
% disp('---------------------------------------------------')
% disp('---------------------------------------------------')