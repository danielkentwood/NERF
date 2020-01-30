function newgrid = resize_grid(grid,oldx,oldy,newx,newy)
% takes a 2-d grid and resamples it
% just pass the original grid, the original x and y edges, and 
% the new x and y edges
% returns the new resampled grid

% DKW 6.03.16

[tstx,tsty] = meshgrid(1:length(newx)-1,1:length(newy)-1);

[nx,oldx,tbx]=histcounts(newx,oldx);
[ny,oldy,tby]=histcounts(newy,oldy);

newgrid = grid(sub2ind(size(grid),tby(tsty),tbx(tstx)));
