% convert pl2 split to plx split conventions

% remember to choose the directory where the recently split files are
% located.
curdir = uigetdir(pwd);

% Convert the SPK convention to the c000 convention
bad_str = 'SPK';
good_str = 'c0';
changeFileNames(curdir,bad_str,good_str)

% Convert the analog_and_events convention to the ead convention
bad_str = 'analog_and_events';
good_str = 'ead';
changeFileNames(curdir,bad_str,good_str)