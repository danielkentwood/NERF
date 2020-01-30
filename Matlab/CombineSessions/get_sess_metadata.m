% get_sess_metadata

% This script creates a struct with all of the processed mat files, along with the following metadata about them:
% - Depth
% - Channel
% - Unit
% - Task

% The output is three variables:
% - sessfeatures
% - alltrodedepths
% - Uniquetrodedepths



%% This will create a struct with all of the processed mat files, along with some metadata
sessfeatures = dir('**/*.mat');
plexonfiles = dir('**/*.pl*');
fids = find(~cellfun(@isempty,regexp({sessfeatures.name},'_srt_spl_c(\d+)_u')));
sessfeatures = sessfeatures(fids);
to_del = [];
for i = 1:length(sessfeatures)
    % save plexon file name and check if it exists    
    plexon_yes = find(contains({plexonfiles.name},sessfeatures(i).name(1:(end-8))));
    
    sessfeatures(i).plexon_name = plexonfiles(plexon_yes).name;
    if ~plexon_yes
        to_del = [to_del i];
    end
    
    % get depth
    curfolder = sessfeatures(i).folder;
    sessfeatures(i).depth = str2num(extractAfter(curfolder,'spl_d'));
    % get channel
    baseTrode = extractAfter(curfolder,'\c');
    sessfeatures(i).channel.Plexon = str2num(baseTrode(1:2));
    sessfeatures(i).channel.GMR = str2num(baseTrode(7:8));
    % get unit
    curname = sessfeatures(i).name;
    baseUnit = extractBetween(curname,'_u','.mat');
    sessfeatures(i).unit.Plexon = str2num(baseUnit{1})-1; % Subtract 1 because PLEXON doesn't count the unsorted spikes as a unit until it is read and saved to the Matlab file (so all matlab unit #s are shifted one up)
    
    % get task
    sessfeatures(i).task = extractBefore(extractAfter(curfolder, 'PROCESSED_'),'\c');
    
    % This will create a list of string IDs with info about GMR electrode and
    % depth
    alltrodedepths{i} = [num2str(sessfeatures(i).channel.Plexon) ',' num2str(sessfeatures(i).depth)];
end

% get rid of cases where there is no corresponding plexon file
sessfeatures(to_del)=[];
alltrodedepths(to_del)=[];
% Get all unique depth/electrode pairs
uniquetrodedepths = unique(alltrodedepths);
