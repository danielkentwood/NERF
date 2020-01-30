% plot_RF_axis

function plot_RF_axis(deviation, travel, group, groupnames, animate)

colors='rgbkmc';

if nargin<5
    animate = 0;
end

figure()
u_group = unique(group);

if animate
    ylim([min([-0.1 min(travel)-.1]) max([1.1 max(travel)+0.1])])
    xlim([-20 20])
    hold on
    plot([0 0],[0 1],'k-')
    plot([-20 20], [0 0], 'k--')
    plot([-20 20], [1 1], 'k--')
    
    
    
    for step = 1:(length(deviation)/length(groupnames))
        for i = 1:length(u_group)
            cur_group = find(group==u_group(i));
            hold on
            plot(deviation(cur_group(step)),travel(cur_group(step)), [colors(i) '.'], 'markersize',10);
        end
        
        pause(0.25)
        drawnow
    end
    ylim([min([-0.1 min(travel)-.1]) max([1.1 max(travel)+0.1])])
    xlim([-20 20])
    
    plot([0 0],ylim,'k-')
    plot(xlim, [0 0], 'k--')
    plot(xlim, [1 1], 'k--')
else
    for i = 1:length(u_group)
        cur_group = group==u_group(i);
        hold on
        h(i)=plot(deviation(cur_group),travel(cur_group), [colors(i) 'o'], 'linewidth',2);
    end
    
    
    ylim([min([-0.1 min(travel)-.1]) max([1.1 max(travel)+0.1])])
    xlim([-20 20])
    
    plot([0 0],ylim,'k-')
    plot(xlim, [0 0], 'k--')
    plot(xlim, [1 1], 'k--')
    legend(h([1:length(groupnames)]),groupnames, 'location', 'best')
end

ylabel('Convergence')
xlabel('Deviation from RF axis (dva)')