function retval = checkForAlreadyProcessed(plex_fname, plex_fpath)
    % Scans through each file listed in "plex_fname" and prints
    % a message if files with that name have already been found
    % somewhere in the PROCESSED directory.
    %
    % A return value of 0 indicates that no duplicate work was found
    % in the appropriate PROCESSED directory.
    %
    % A return value of 1 indicates that duplicate work was found.
    %
    % A return value of -1 indicates that we weren't able to guess
    % where the PROCESSED_xxx path was, and hence couldn't come to
    % a conclusion either way.

    % Store the current directory for later use.
    % A retval oe
    tmpDir = pwd;
    retval = 0;
    
    % plex_fname_to_check_for_processing = strsplit(plex_fname,{'\n'},'CollapseDelimiters',true);
    
    plex_processed_path = '';

    % Try to guess where the PROCESSED directory we need is.
    plex_processed_path = guessProcessedPathLocation(plex_fpath);

    if (strcmp(plex_processed_path,'Unable to guess PROCESSED_xxx path.'))
        disp('Unable to do anything.');
        retval = -1;
        return
    else
        cd(plex_processed_path);

        
        % Some 'bottled lightning' code to get all of the directory
        % names into a string array. Probably best not to mess with.
        disp(['CDing to ' plex_processed_path]);
        [status, cmdout] = dos('dir /a-d /b /s');
        disp('Formatting cmdout...');
        cmdout = strsplit(cmdout,{'\n'},'CollapseDelimiters',true);
        % Bottled lightning resealed.

        % Check through the string array, and see if the
        % plex_fname has already been found in there.
        % STILL NEEDS DEBUGGING.
        for i = 1:length(cmdout)
            if (length(strfind(cmdout(i), plex_fname) > 0)
                disp(cmdout(i));
                disp('It looks like file');
                disp(['   ' plex_fname]);
                disp('may have been processed already.');
                retval = 1;
                break;
            end
        end
        if (retval == 0)
            disp(plex_fname);
            disp('has no duplicates detected.');
        end
    end

    cd(tmpDir);
    
    
end

function st = guessProcessedPathLocation(plex_fpath)
    % Simple helper function to guess where the PROCESSED_xxx
    % path location is.
    
    % Returns the value 'Unable to guess PROCESSED_xxx path.'
    % if it can't figure this out.
    
    switch plex_fpath
        case 'C:\Data\Jiji\FlashProbe\RAW_mgs\'
            st = 'C:\Data\Jiji\FlashProbe\PROCESSED_mgs\'
        case 'C:\Data\Jiji\FlashProbe\RAW_simple_probe\'
            st = 'C:\Data\Jiji\FlashProbe\PROCESSED_simple_probe\'
        case 'C:\Data\Jiji\FlashProbe\RAW_search_probe\'
            st = 'C:\Data\Jiji\FlashProbe\PROCESSED_search_probe\'
        otherwise
            st = 'Unable to guess PROCESSED_xxx path.'
    end
end