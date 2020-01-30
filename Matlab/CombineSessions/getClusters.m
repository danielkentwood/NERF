function clusterInfo = getClusters(Z,sess_mat)

f = figure();
dendrogram(Z)
set(f,'position',[0 72 1259 924])
ylims=ylim;
set(gca,'YTick',floor(ylims(1)):ceil(ylims(2)))
drawnow

cutoffQuest = questdlg('Manual cluster entry or cutoff value?', ...
    'Cluster definition','Manual','Cutoff','Manual');

if strcmp(cutoffQuest,'Manual')
    sessGroups=[];
    clusterLoop=1;
    cutoff=NaN;
    while clusterLoop
        choice = questdlg('Enter another cluster?', ...
            'Cluster ID','Yes','No','Yes');
        switch choice
            case 'Yes'
                sessGroups{end+1}=input('Enter session IDs in this cluster: ');
            case 'No'
                clusterLoop=0;
        end
    end
    numgroups=length(sessGroups);
    for i = 1:numgroups
        groups{i}=sess_mat(sessGroups{i});
    end
else
%     cutoff=input('Enter cutoff value: ');
    [~,cutoff]=ginput(1);
    T = cluster(Z,'Cutoff',cutoff,'Criterion','distance');
    numgroups = length(unique(T));
    for i = 1:numgroups
        groups{i}=sess_mat(T==i);
    end
end

disp('num sessions in group:')
ns = num2str(cellfun(@length,groups));
sprintf(ns)

clusterInfo.groups = groups;
clusterInfo.cutoff = cutoff;
clusterInfo.Z = Z;
clusterInfo.sess_mat=sess_mat;
