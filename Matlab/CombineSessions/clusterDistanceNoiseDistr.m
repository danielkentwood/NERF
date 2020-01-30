% clusterDistanceNoiseDisr
clear;

%% Navigate to the processed experiment folder
% Ask user what they want to see
answerlist = {'simple_probe','search_probe','mgs'};
answerID = listdlg('ListString', answerlist,...
    'SelectionMode','single',...
    'Name','Select a Task Directory',...
    'ListSize',[300 300]);
answer = answerlist{answerID};

% Handle response
switch answer
    case 'simple_probe'
        taskPath = [experimentHomeFolder 'PROCESSED_simple_probe'];
    case 'search_probe'
        taskPath = [experimentHomeFolder 'PROCESSED_search_probe'];
    case 'mgs'
        taskPath = [experimentHomeFolder 'PROCESSED_mgs'];
end

cd(taskPath)


%% get session metadata
get_sess_metadata

%% Now, we need to resample with replacement
% This will create a n x s matrix, where n is the number of resampling iterations and
% s is the session index (this should be the same number as the number of
% uniquetrodedepths. We'll come back to use this later, after all of
% the files have been loaded and the features extracted.
num_iter = 1; % for prototyping, we're just doing one iteration
for ni = 1:num_iter
    samples=[];
    rand_sess_id=[];
    for i = 1:length(uniquetrodedepths)
        curpair = uniquetrodedepths{i};
        matches = find(strcmp(alltrodedepths,curpair));
        samples(i) = ceil(rand()*numel(matches));
        rand_sess_id(i) = matches(samples(i));
    end
    allsamples(:,ni)=samples;
    all_rand_sess_ids(:,ni)=rand_sess_id;
end


%% Loop through all the files, extract features
for i = 1:num_iter
    out(i) = extract_features(sessfeatures, all_rand_sess_ids(:,i));
    
    % Get 2D projection through tsne
    % show comparison of 4 different tsne distance algorithms
    % (the cosine algorithm seems to consistently be the best)
    tsne_proj = compare_tsne_algos(out(i).all_features);
    
end




