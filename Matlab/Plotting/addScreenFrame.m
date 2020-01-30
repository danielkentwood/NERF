function addScreenFrame(screen_dim,color)

scr_x=screen_dim(1)/2;
scr_y=screen_dim(2)/2;

hold on
plot([-scr_x scr_x],[scr_y scr_y],'color',color)
plot([-scr_x scr_x],[-scr_y -scr_y],'color',color)
plot([-scr_x -scr_x],[-scr_y scr_y],'color',color)
plot([scr_x scr_x],[-scr_y scr_y],'color',color)
