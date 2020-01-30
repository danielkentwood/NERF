% open_ead.m
%
% Opens the ead file and extracts event info from the Strobed channel

function Strobed = open_ead(fname)

% Get events
% This works on plx and pl2 files
[nevs, tsevs, svStrobed] = plx_event_ts(fname, 257);

% Some processing
% Combine Ecodes and their timestamps
disp(['Event data extracted from ' fname]);
Strobed = zeros(length(svStrobed),2);
Strobed(:,2)=svStrobed;
Strobed(:,1)=tsevs;

