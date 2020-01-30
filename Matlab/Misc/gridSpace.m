function outList = gridSpace(w,h,node_w,node_h)

num_w = round(w/node_w);
num_h = round(h/node_h);

x=linspace(0,w,num_w+1);
y=linspace(0,h,num_h+1);

midx=x(1:end-1)+(diff(x)/2);
midy=y(1:end-1)+(diff(y)/2);

leftx = x(1:end-1);
rightx = x(2:end);

bottomy = y(1:end-1);
topy = y(2:end);

nodenum=1;
outList = [];
numnodes = num_h*num_w;

for xi = 1:length(midx)
    for yi = 1:length(midy)
        outList(nodenum,:)=[nodenum midx(xi) midy(yi) leftx(xi) bottomy(yi) rightx(xi) topy(yi)];         
        nodenum=nodenum+1;
    end
end





