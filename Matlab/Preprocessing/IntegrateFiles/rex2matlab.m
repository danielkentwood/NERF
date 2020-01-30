% Converts REX .A and .E files to Trials struct .mat file
% Modified from simplerex2m by PNL 6/26/13, originally by MAS 


if length(rex_fname)==1
    disp('Canceled')
else
    REX_Trials = mrdr('-s ', '1001' , '-d ',[rex_path rex_fname]);         %% makes matlab structure REX_Trials from rex A&E files                                  
end

