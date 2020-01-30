% batch_ExtractCleanSave

%% This script makes sure that all mat session files have been preprocessed with saccade detection and clean-up routines
matdir = dir('**/*.mat');
fids = find(~cellfun(@isempty,regexp({matdir.name},'_srt_spl_c(\d+)_u')));
matdir = matdir(fids);
names = {matdir.name};
folders = {matdir.folder};


for nm = 1:length(names)
   curfile = fullfile(folders{nm}, names{nm});
   disp(['Loading file ' num2str(nm) ' of ' num2str(length(names)) '...'])
   load(curfile)
   
   pre_check = any(~cellfun(@isempty,{Trials.Saccades}));
   if ~pre_check
       disp('Extracting saccades and cleaning...')
       Trials = saccade_detector(Trials);
       Trials = cleanTrials(Trials);
       disp(['Saving ' curfile(25:end)])
       save(curfile,'Trials')
   end
end

