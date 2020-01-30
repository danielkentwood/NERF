% separate units
% This will go through and open each mat file, check for the different
% units, and then separate it out into its component units, saving a new
% file for each one, and then deleting the original.

clear;

main_dir = pwd;

% first, get all the processed .mat files
mats = dir('**/*.mat');
mats = mats(contains({mats.name},'_srt_spl'));

% now, check for cases where we've already split into units, and remove
% them from the file list
done = contains({mats.name},'_u');
mats_done = mats(done);
mats(done)=[];

% create base unit name (we'll use this later)
base_unit = '_u00';

checkflag=1;
for i = 1:length(mats)
    % start by assuming you want to save the unit files and delete the
    % original
    del_orig = 1;
    save_flag = 1;
    
    % get the channel
    idx = regexp(mats(i).folder,'GMR');
    chan = str2double(mats(i).folder((idx+3):(idx+4)));
    
    % load the file
    load(fullfile(mats(i).folder,mats(i).name))
    
    % check how many units there are
    % remember the first unit is unsorted
    n_units = length(Trials(1).Electrodes(chan).Units);
    
    % before saving the individual units as separate files, check if they
    % already exist
    uname = [mats(i).name(1:(end-4)) '_u'];
    idx_exist = find(contains({mats_done.name},uname));
    num_exist = length(idx_exist);
    
    % if the unit files already exist...
    if num_exist>0
        % if we are still checking what the user wants to do...
        if checkflag
            disp('This file has already been split into the following unit files:')
            for pmd = 1:num_exist
                disp(mats_done(idx_exist(pmd)).name)
            end
            to_do = input('Do you want to overwrite these unit files? Enter 0 for NO, 1 for YES, 2 for NO ALL, 3 for YES ALL: ');
            
            if to_do>1
                checkflag=0;
                to_do = to_do-2;
            end
            if ~to_do
                save_flag=0;
                del_orig_pre = input('Do you still want to delete the original base file? Enter 0 for NO, 1 for YES: ');
                del_orig = del_orig_pre;
            end
        else % if we have already been told what to do every time...
            switch to_do
                case 0
                    save_flag=0;
                    del_orig = del_orig_pre;
                case 1
                    if num_exist>0
                        disp('Deleting following unit files:')
                        for pmd = 1:num_exist
                            disp(mats_done(idx_exist(pmd)).name)
                            delete(fullfile(mats_done(idx_exist(pmd)).folder,mats_done(idx_exist(pmd)).name))
                        end
                    end
                    save_flag=1;
            end
        end
    end
    
    if save_flag
        % go through and save the individual units
        orig_trials = Trials;
        for nu = 1:n_units
            Trials = orig_trials;
            % cycle through all trials and save only the current unit
            for tr = 1:length(orig_trials)
                Trials(tr).Electrodes(chan).Units = Trials(tr).Electrodes(chan).Units(nu);
            end
            % now save the single-unit Trials struct under a new name
            us = num2str(nu);
            u_str = base_unit;
            u_str((end-(length(us)-1)):end)=us;
            new_name = fullfile(mats(i).folder,[mats(i).name(1:(end-4)) u_str '.mat']);
            save(new_name,'Trials')
        end
        del_orig = 1;
    end
        
    % Delete the original file
    if del_orig
        disp(['Deleting ' fullfile(mats(i).folder,mats(i).name)]) 
        delete(fullfile(mats(i).folder,mats(i).name));
    end
    
end

cd(main_dir)
% now remove all of the first units (because they are just unsorted spikes)
remove_unit1
% extract saccades, clean up behavior, and save files again
batch_ExtractCleanSave
