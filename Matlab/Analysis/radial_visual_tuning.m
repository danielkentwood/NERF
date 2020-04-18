function radial_visual_tuning(Trials,lock_event,remap)

switch nargin
    case 2
        remap = 1;
    case 1
        lock_event = 'saccade';
        remap = 1;
end

bin_size = 15;
win_start = -200;
win_end = 200;
window = win_start:bin_size:win_end;

psth_mat = [];
for i=1:(length(window)-1)
    PSTH = radial_PProbeTH(Trials,[window(i) window(i+1)],lock_event,remap);
    for k = 1:8
        psth_mat(i,:,k) = PSTH(k).y;
    end
end

subplot_vec = [6 3 2 1 4 7 8 9];
figure('position',[701 370 1146 927])
for i = 1:8
    subplot(3,3,subplot_vec(i))
    im_mat = flipud(psth_mat(:,:,i));
    imagesc(PSTH(1).x,window(1:(end-1)),im_mat)
    set(gca,'Ydir','normal')
    hold on
    plot([0 0],ylim,'k-')
    plot(xlim,[0 0],'k-')
    xlabel(['time to probe (ms)'])
    ylabel(['bin relative to ' lock_event ' (ms)'])
    title([PSTH(i).name ' degrees'])
    hold off
end