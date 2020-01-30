function out = getDownsampledRF(pre,ds_factor)

for i = 1:length(pre)
    %% downsample
    fun = @(block_struct) mean( block_struct.data(:) );  %// anonymous function to get average of a block
    B = blockproc(pre{i}.Ig,[ds_factor ds_factor],fun); %// process N by N  blocks
    
    out{i}.x = pre{i}.x(1:ds_factor:end);
    out{i}.y = pre{i}.y(1:ds_factor:end);
    out{i}.Bs = B(out{i}.y>=-40 & out{i}.y<=40,out{i}.x>=-40 & out{i}.x<=40);
end

