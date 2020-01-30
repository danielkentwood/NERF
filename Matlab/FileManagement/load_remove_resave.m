% load_remove_resave
function load_remove_resave(num_files)

disp('loading, removing, or resaving....')

num_u = num_files;
for i = 1:num_u
    load(['merge_unit_' num2str(i)])
    if exist('Trials','var')
        clear Trials
        save(['merge_unit_' num2str(i)], 'sessList')
    end
end
   
disp('Done removing!')