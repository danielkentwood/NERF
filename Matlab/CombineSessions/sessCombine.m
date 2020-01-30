% sessCombine
function sessCombine(sessfeatures,idx)

num_clus = length(unique(idx));
newdir = 'merged_units';
for i=1:num_clus % first clus # is 0 (if you're using HDBC algorithm)
    disp(['Cluster ' num2str(i) ' of ' num2str(num_clus-1)])
    % how many sessions in this cluster?
    numsessions = sum(idx==i);
    % see if there are multiple sessions in the group
    if numsessions>1
        % if there isn't a new folder already
        if ~isfolder(newdir)
            mkdir(newdir)
        end
        % get all sessions in current cluster
        sessList = sessfeatures(idx==i);
        new_unit = ['merge_unit_' num2str(i) '.mat'];
        disp('Saving merged unit...')
        save(fullfile(newdir, new_unit),'sessList','-v7.3')
        disp(['Done saving unit ' num2str(i)])
    else
        continue
    end
end
disp('Finished combining sessions!')

















%% OLD CODE


% curdir = pwd;
% groups = clusterInfo.groups;
% for i=1:length(groups)
%     numsessions = length(groups{i});
%     % see if there are multiple sessions in the group
%     if numsessions>1
%         sessList = groups{i};
%         newdir = ['group_' num2str(i)];
%         mkdir(newdir)
%         allTrials=[];
%         for ns = 1:numsessions
%             sessname = groups{i}{ns}(1:end-3);
%             unit = str2num(groups{i}{ns}(end))+1;
%             load([sessname '.mat']);
%             chan = find(~cellfun(@isempty,{Trials(1).Electrodes.Units}));
%             numunits = length(Trials(1).Electrodes(chan).Units);
%             todelete=setdiff(1:numunits,unit);
%
%             for tr = 1:length(Trials)
%                 Trials(tr).Electrodes(chan).Units(todelete)=[];
%             end
%
%             allTrials=[allTrials Trials];
%             clear Trials
%         end
%         cd(newdir)
%         Trials = allTrials;
%         save('groupData','Trials','sessList','clusterInfo','-v7.3')
%         cd(curdir)
%     else
%         continue
%     end
%
% end
