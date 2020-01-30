



function Trials = integrate_REXPLEX(par)

% get plexon variables
plex_fname = par.plx_fname;
plex_fpath = par.plx_fpath;
cd(plex_fpath)
% get rex and ead variables
rex_fname = par.rex_fnames;
ead_fname = par.ead_fnames;
ead_fpath = par.ead_fpath;
rex_fpath = par.rex_fpath;

% open ead file
open_ead
% set output name and path
output_fname=[plex_fname(1:end-4) '.mat'];
output_path=plex_fpath;

% open the REX file
combineREX

% open the PLEX files
batch_makeTrialPlx2

% combine them
combine_REX_PLEX

% Some housekeeping
Trials=rmfield(Trials,'all_events'); % this saves a ton of space, not sure if this field is ever used
Trials=rmfield(Trials,'PLEX_Events');
to_del=[];
for ii=1:length(Trials)
    if isempty(Trials(ii).Signals)
        to_del(end+1)=ii;
    else
        Trials(ii).Signals(3:4)=[]; % remove unnecessary joystick position channels
    end
end
Trials(to_del)=[];

%% Save file
save([output_path '\' output_fname],'Trials','-v7.3');
clear Trials

% create temporary directory (this becomes important later to help debug
% mrdr crashing from multiple uses)
mkdir(pwd,'tempMatDir');
cd tempMatDir
save curVars i plx_fnames plx_fpaths ead_fnames rex_fpath rex_fnames Strobed ead_fpath

% now clear all (NOTE: clear all is necessary to prevent mrdr from
% crashing)
pause(.5)
clear all

% and reload
load curVars
cd ..
rmdir('tempMatDir','s');



