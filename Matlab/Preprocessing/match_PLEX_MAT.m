% check if plexon and mat files match

clear
clc
close all

%% Navigate to the processed experiment folder

cd('D:\Data\Jiji\FlashProbe\PROCESSED_search_probe') % hardcoded for development.

%% This will create a struct with all of the processed mat files, along with some metadata
sessfeatures = dir('**/*.mat');
plexonfiles = dir('**/*.plx');
fids = find(~cellfun(@isempty,regexp({sessfeatures.name},'_srt_spl_c(\d+)_u')));
sessfeatures = sessfeatures(fids);
to_del = [];
spk_ts = [];
for i = 1:length(sessfeatures)
    
   curfolder = sessfeatures(i).folder;
    
   % save plexon file name and check if it exists
   sessfeatures(i).plexon_name = [sessfeatures(i).name(1:(end-8)) '.plx']; % CHECK THAT THIS WORKS; HASN'T BEEN TESTED AFTER ADDING THE UNIT NAME REMOVAL
   plexon_yes = find(contains({plexonfiles.name},sessfeatures(i).plexon_name));
   if ~plexon_yes
       disp([sessfeatures(i).name ' has no corresponding plexon file.'])
       continue
   end
    
   % get channel
   baseTrode = extractAfter(curfolder,'\c');
   sessfeatures(i).channel.Plexon = str2num(baseTrode(1:2));
   sessfeatures(i).channel.GMR = str2num(baseTrode(7:8));

   % get unit
   curname = sessfeatures(i).name;
   baseUnit = extractBetween(curname,'_u','.mat');
   sessfeatures(i).unit.Plexon = str2num(baseUnit{1});

   [n, npw, ts, wave2] = plx_waves_v(fullfile(sessfeatures(i).folder,sessfeatures(i).plexon_name), sessfeatures(i).channel.Plexon, sessfeatures(i).unit.Plexon-1);
   
   if wave2<0
      disp(fullfile(sessfeatures(i).folder,sessfeatures(i).plexon_name))
   end
       
   % THIS SCRIPT IS UNFINISHED. IT IS SUPPOSED TO CHECK IF THE PLEXON FILE
   % HAS BEEN RE-SORTED SINCE THE MATLAB FILE WAS SPLIT INTO UNITS. IT
   % CURRENTLY TELLS YOU IF THERE ARE MORE MATLAB UNITS THAN THERE ARE
   % PLEXON UNITS, BUT THIS MIGHT NOT CAPTURE EVERY CASE.

end



