% checkRexCombine
clear all
clc
curdir = pwd;
cd('C:\REX_Data\Jiji')

% Open REX files manually
[rex_fnames,rex_fpath] = uigetfile('*.*A','Select the REX files','MultiSelect','on');
for i=1:length(rex_fnames)
    % Get recording dates
    extr_date = rex_fnames{i}(4:9);
    extr_year = extr_date(1:2);
    extr_mon = extr_date(3:4);
    extr_day = extr_date(5:6);
    form_date = ['20' extr_year '-' extr_mon '-' extr_day];
    sess_date(i) = str2num([num2str(datenum(form_date)) rex_fnames{i}(end-1)]);
end
% sort by date
[y,didx]=sort(sess_date);
rex_fnames=rex_fnames(didx);

combineREX

cd(curdir);