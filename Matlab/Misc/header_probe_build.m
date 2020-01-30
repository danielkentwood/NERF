fileID=fopen('header_probe.h','w');

fprintf(fileID,'struct probe_loc {\n\tint probe_num;\n\tint midx;\n\tint midy;\n\tint leftx;\n\tint bottomy;\n\tint rightx;\n\tint topy;\n};\n');
fprintf(fileID,'struct probe_loc probe_list[] = {\n');

out = gridSpace(1024,768,128,128);

formatSpec = '{%i, %i, %i, %i, %i, %i, %i},\n';
for i=1:size(out,1)
    fprintf(fileID,formatSpec,out(i,:));    
end

fprintf(fileID,'};');
fclose(fileID);


%Note: need to manually remove final comma