% check integrity of REX and PLEXON files 

% create a temporary directory to hold the mat files

%%%%%%%% Change this to 'D' if you're on the other computer and need this.
root_directory_letter = 'C';

curdir = pwd;

if (7 ~= exist('tempMatDir')) % Not really sure why it's 7, but okay.
    mkdir(pwd,'tempMatDir');
end

manual=0;

cd([root_directory_letter ':\Data\Jiji\FlashProbe\']);

% Open REX file manually.
[plex_fnames,plex_fpath] = uigetfile('*.*','Select the Plexon file','MultiSelect','on');


%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% New code that's still being developed.
%%%%%%%%%%%%%%%%%%%
if (strcmp(class(plex_fnames),'char'))
    maybe_already_processed = checkForAlreadyProcessed(plex_fnames, plex_fpath);
    if (1 == maybe_already_processed)
        disp('You are probably going to duplicate work if you continue.');
        disp('There''s no shame in running it again and just deselecting the file!');
        disp(' ');
        continue_anyway = input('Continue processing anyway, or quit checkRexPlex early? (Type ''y'' to continue, or ''n'' to quit.) :: ');
        if (strcmp(continue_anyway,'y'))
            disp('Continuing anyway!');
        else
            disp('Stopping.');
            return
        end;
    else
        disp('');
        disp('No duplicated work detected.');
        disp('');
    end;
end;

if (strcmp(class(plex_fnames),'cell'))
    first_duplicate_warning_message = 0;
    
    for i = 1:length(plex_fnames)
        disp(i);
        current_fname = plex_fnames(i);
        maybe_already_processed = checkForAlreadyProcessed(current_fname, plex_fpath);
        if (1 == maybe_already_processed)
            if (first_duplicate_warning_message == 0)
                disp(' ');
                disp('You may be processing a file we''ve already done if you continue.');
                disp('You can always just run checkRexPlex again without the file.');
                disp(' ');
                first_duplicate_warning_message = 1;
            end;
%             continue_anyway = input('Continue processing anyway, or quit checkRexPlex early? (Type ''y'' to continue, or ''n'' to quit.) :: ');
%             if (strcmp(continue_anyway,'y'))
%                 disp('Continuing anyway!');
%             else
%                 disp('Stopping.');
%                 return
%             end;
        else
            disp('');
            disp('No duplicated work detected.');
            disp('');
            
            continue_anyway = input('Continue processing anyway, or quit checkRexPlex early? (Type ''y'' to continue, or ''n'' to quit.) :: ');
            if (strcmp(continue_anyway,'y'))
                disp('Continuing anyway!');
            else
                disp('Stopping.');
                return
            end;
        end;
    end;
end;
%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% End of new code.
%%%%%%%%%%%%%%%%%%%


if ischar(plex_fnames)
    plex_fnames={plex_fnames};
end

rex_path=[root_directory_letter ':\REX_Data\Jiji\'];         % "REX_Data" is not currently synced to the other computer, so this
                                                             % probably won't work in its current (= 1/25/2018) state.

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

cd([root_directory_letter ':\Data\Jiji\FlashProbe\']);
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