clear all

% REX_Trials = mrdr('-s ', '1001' , '-d ','D:\Data\FlashProbe\Jiji\REX_Data\m15180830.002');
% fname = 'C:\Users\SegravesLab\Desktop\TEST\m15180830_srt_002.pl2';

REX_Trials = mrdr('-s ', '1001' , '-d ','D:\Data\FlashProbe\Maeve\REX_Data\m18190117.000');
fname = 'D:\Data\FlashProbe\Maeve\RAW_search_probe\m18190117_000_srt.pl2';

trial = read_pl2(fname);


%% check number of trials in each one
numREX = length(REX_Trials);
numPLX = length(trial);

if numREX>numPLX
    
    
   REX_Trials = REX_Trials((1+(numREX-numPLX)):end); 
end

%% Add time stamps to REX eye data

start_ecode = 1001;
pre_buffer=100;

for t = 1:length(REX_Trials)
    
    wsc_idx = find([REX_Trials(t).Events.Code]==start_ecode);
    if isempty(wsc_idx)
        keyboard
    end
    window_start_time = REX_Trials(t).Events(wsc_idx).Time; 
    
    REX_Trials(t).Signals(1).Time = (1:length(REX_Trials(t).Signals(1).Signal)) + double(window_start_time - pre_buffer); % Bc REX signals are in ms starting with 1;
    REX_Trials(t).Signals(2).Time = (1:length(REX_Trials(t).Signals(2).Signal)) + double(window_start_time - pre_buffer); % Bc REX signals are in ms starting with 1;
end

%% compare REX and PLEX (within the start and end codes)

t = 12;

figure
subplot(1,2,1)
plot(REX_Trials(t).Signals(1).Signal, REX_Trials(t).Signals(2).Signal, '.r')
subplot(1,2,2)

scode = 1001;
ecode = 4079;
stime = trial(t).events.time(trial(t).events.code==scode);
etime = trial(t).events.time(trial(t).events.code==ecode);
e_idx = trial(t).eye.time>=stime & trial(t).eye.time<=etime;
plot(trial(t).eye.x(e_idx),trial(t).eye.y(e_idx),'.k')

disp('***************')
disp(['REX length = ' num2str(length(REX_Trials(t).Signals(1).Signal))])
disp(['PLEX length = ' num2str(length(find(e_idx)))])
disp(['Difference = ' num2str(length(REX_Trials(t).Signals(1).Signal) - length(find(e_idx)))])
disp('***************')


%% get average difference
for t = 1:length(trial)
    scode = 1001;
    ecode = 4079;
    stime = trial(t).events.time(trial(t).events.code==scode);
    etime = trial(t).events.time(trial(t).events.code==ecode);
    e_idx = trial(t).eye.time>=stime & trial(t).eye.time<=etime;
    diffs(t) = length(REX_Trials(t).Signals(1).Signal) - length(find(e_idx));
end
md = median(diffs);
disp(['MEDIAN of diffs is ' num2str(md)])


%% compare REX and PLEX (with start/end codes and buffers)

t = 21;
buffer = 100;
scode = 1001;
ecode = 4079;
difference = 2;

% ensure REX has equal or +1 samples compared to PLX
while abs(difference)>1
    stime = trial(t).events.time(trial(t).events.code==scode)-buffer;
    etime = trial(t).events.time(trial(t).events.code==ecode)+buffer;
    e_idx = trial(t).eye.time>=stime & trial(t).eye.time<=etime;
    numPLX = length(find(e_idx));
    numREX = length(REX_Trials(t).Signals(1).Signal);
    difference = numREX-numPLX;
    
    buffer = buffer+floor(difference/2); 
end
    
disp('***************')
disp(['REX length = ' num2str(numREX)])
disp(['PLEX length = ' num2str(numPLX)])
disp(['Difference = ' num2str(difference)])

b1 = polyfit(REX_Trials(t).Signals(1).Signal(1:end-difference),trial(t).eye.x(e_idx)',1);
b2 = polyfit(REX_Trials(t).Signals(2).Signal(1:end-difference),trial(t).eye.y(e_idx)',1);
offsetx = median(REX_Trials(t).Signals(1).Signal(1:end-difference) - (trial(t).eye.x(e_idx)./b1(1))');
offsety = median(REX_Trials(t).Signals(2).Signal(1:end-difference) - (trial(t).eye.y(e_idx)./b2(1))');

disp(['SlopeX = ' num2str(b1(1))])
disp(['SlopeY = ' num2str(b2(1))])
disp(['OffsetX = ' num2str(offsetx)])
disp(['OffsetY = ' num2str(offsety)])
disp('***************')

figure
subplot(1,2,1)
plot(REX_Trials(t).Signals(1).Signal, '.r')
hold on
plot(trial(t).eye.x(e_idx)./b1(1) + offsetx,'.k')

subplot(1,2,2)
plot(REX_Trials(t).Signals(2).Signal, '.r')
hold on
plot(trial(t).eye.y(e_idx)./b2(1) + offsety,'.k')


%% get average slope and intercept for fit between REX and PL2 eye data
scode = 1001;
ecode = 4079;

















for t = 1:length(trial)
    rex_events = [REX_Trials(1).Events.Code];
    rex_etimes = [REX_Trials(1).Events.Time];
    
    rexT = REX_Trials(t).Signals(1).Time;
    rex_stime = rex_etimes(rex_events==scode);
    rex_etime = rex_etimes(rex_events==ecode);
    rex_e_idx = rexT>=rex_stime & rexT<=rex_etime;
    
    
    rexX = REX_Trials(t).Signals(1).Signal(rex_e_idx);
    rexY = REX_Trials(t).Signals(2).Signal(rex_e_idx);
    
    stime = trial(t).events.time(trial(t).events.code==scode);
    etime = trial(t).events.time(trial(t).events.code==ecode);
    e_idx = trial(t).eye.time>=stime & trial(t).eye.time<=etime;
    
    plxX = trial(t).eye.x(e_idx);
    plxY = trial(t).eye.y(e_idx);
    
    
    
    
    
    
    
    buffer = 100;
    difference = 2;
    
    
    
    % ensure REX has equal or +1 samples compared to PLX
    while abs(difference)>1
        stime = trial(t).events.time(trial(t).events.code==scode)-buffer;
        etime = trial(t).events.time(trial(t).events.code==ecode)+buffer;
        e_idx = trial(t).eye.time>=stime & trial(t).eye.time<=etime;
        numPLX = length(find(e_idx));
        numREX = length(REX_Trials(t).Signals(1).Signal);
        difference = numREX-numPLX;
        
        buffer = buffer+floor(difference/2);
        difference
    end
    
    
    b1 = polyfit(REX_Trials(t).Signals(1).Signal(1:end-difference),trial(t).eye.x(e_idx)',1);
    b2 = polyfit(REX_Trials(t).Signals(2).Signal(1:end-difference),trial(t).eye.y(e_idx)',1);
    offsetx = median(REX_Trials(t).Signals(1).Signal(1:end-difference) - (trial(t).eye.x(e_idx)./b1(1))');
    offsety = median(REX_Trials(t).Signals(2).Signal(1:end-difference) - (trial(t).eye.y(e_idx)./b2(1))');
    
    SlopeX(t) = b1(1);
    SlopeY(t) = b2(1);
    OffsetX(t) = offsetx;
    OffsetY(t) = offsety;
    
end

msx = mean(SlopeX(SlopeX>0));
msy = mean(SlopeY(SlopeY>0));
mox = mean(OffsetX(OffsetX>0));
moy = mean(OffsetY(OffsetY>0));

disp(['Mean SlopeX = ' num2str(msx)])
disp(['Mean SlopeY = ' num2str(msy)])
disp(['Mean OffsetX = ' num2str(mox)])
disp(['Mean OffsetY = ' num2str(moy)])




%%

buffer = 102;
scode = 1001;
ecode = 4079;

for t = 1:length(trial)
    
    % extract snippet from PLEX eye data
    stime = trial(t).events.time(trial(t).events.code==scode)-buffer;
    etime = trial(t).events.time(trial(t).events.code==ecode)+buffer;
    e_idx = trial(t).eye.time>=stime & trial(t).eye.time<=etime;
    
    
%     disp('***************')
%     disp(['REX length = ' num2str(length(REX_Trials(t).Signals(1).Signal))])
%     disp(['PLEX length = ' num2str(length(find(e_idx)))])
%     
%     disp(['Difference = ' num2str(difference)])
    
    % get length difference betweeen REX and PLEX
    difference = length(REX_Trials(t).Signals(1).Signal) - length(find(e_idx));
    disp(difference)
    if abs(difference) < 0
        difference
    end
    
%     b1 = polyfit(REX_Trials(t).Signals(1).Signal(1:end-difference),trial(t).eye.x(e_idx)',1);
%     b2 = polyfit(REX_Trials(t).Signals(2).Signal(1:end-difference),trial(t).eye.y(e_idx)',1);
%     offsetx = median(REX_Trials(t).Signals(1).Signal(1:end-difference) - (trial(t).eye.x(e_idx)./b1(1))');
%     offsety = median(REX_Trials(t).Signals(2).Signal(1:end-difference) - (trial(t).eye.y(e_idx)./b2(1))');
    
end





