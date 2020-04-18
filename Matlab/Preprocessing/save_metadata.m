
clear;
mats = dir('**/*.mat');
mats = mats(contains({mats.name},'_srt_spl'));

for i = 1:length(mats)
    disp(i)
    name = mats(i).name;
    load(name);
    meta.fname = name;
    meta.session_num = Trials(1).Session.num;
    meta.a2dRate  = Trials(1).a2dRate;
    save(name, 'Trials', 'meta');
    clear Trials meta
end