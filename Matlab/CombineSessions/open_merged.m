% sessCombine
function Trials = open_merged(sessfeatures)
tic
numsessions = length(sessfeatures);
allTrials=[];
for ns = 1:numsessions
    disp(['Session ' num2str(ns) ' of ' num2str(numsessions)])
    
    % load session
    sessname = sessfeatures(ns).name;
    sesspath = sessfeatures(ns).folder;
    load(fullfile(sesspath,sessname));
    % concatenate sessions
    allTrials=[allTrials Trials];
    clear Trials
end
Trials = allTrials;

disp(['Finished combining sessions in ' num2str(toc) ' seconds!'])

















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
