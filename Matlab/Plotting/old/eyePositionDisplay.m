% single trial eye position analysis

function eyePositionDisplay(x,y,screen_dim)

xvel = gradient(x);
yvel = gradient(y);

scr_x=screen_dim(1)/2;
scr_y=screen_dim(2)/2;

xrex=x./1.5;
yrex=y./1.5;


figure
plot([-scr_x scr_x],[scr_y scr_y],'k-')
hold on
plot([-scr_x scr_x],[-scr_y -scr_y],'k-')
plot([-scr_x -scr_x],[-scr_y scr_y],'k-')
plot([scr_x scr_x],[-scr_y scr_y],'k-')
plot(xrex,yrex,'r.')