clear;clc;close all

rex_fnames = {'m15160705.001A','m15160706.002A','m15160708.002A','m15160711.002A',...
    'm15160714.002A','m15160719.002A','m15160721.002A','m15160930.001A',...
    'm15161116.000A','m15161221.001A','m15170104.000A','m15170104.001A',...
    'm15170828.000A','m15171009.002A','m15171012.001A'};

% 'm15160620.001A' - first file with all 3 eccentricites. Lower right target is off for some reason.
% 'm15160620.002A' - targets are symmetric, but are hypermetric (drastically)
% 'm15160629.001A' - targets are good. Low # of trials
% 'm15160701.001A' - targets are symmetric, but are hypometric
% 'm15160705.001A' - looks good
% 'm15160706.002A' - looks good
% 'm15160708.002A' - looks good
% 'm15160711.002A' - looks good
% 'm15160713.002A' - targets are symmetric, but are hypometric
% 'm15160714.002A' - looks good
% 'm15160718.002A' - targets are symmetric, but are hypometric
% 'm15160719.002A' - looks good
% 'm15160721.002A' - looks good
% 'm15160930.001A' - looks good
% 'm15161116.000A' - looks good
% 'm15161221.001A' - looks good
% 'm15170104.000A' - looks good
% 'm15170104.001A' - looks good
% 'm15170828.000A' - looks good
% 'm15170920.000A' - looks good, a few saccades land near fixation
% 'm15170920.001A' - BAD
% 'm15171003.001A' - targets are symmetric, but are hypometric
% 'm15171009.002A' - looks good
% 'm15171012.001A' - looks good



rex_fpath = 'D:\Data\Jiji\REX_Data\';

% load the files
Trials = processOnlyREX(rex_fnames,rex_fpath);

% preprocessing
Trials = saccade_detector(Trials);
Trials = cleanTrialsStruct_v2(Trials);
Trials = MGS_scrub(Trials);

% strip all data except for:
% 1. eye trace
% 2. target struct
% 3. saccade struct
% 4. trial start and end time
% 5. fixation dot onset and offset (for go signal)
% 6. events (just in case user wants to dig deeper)

fields = {'a2dRate','session','Distractor'};
Trials=rmfield(Trials,fields);









