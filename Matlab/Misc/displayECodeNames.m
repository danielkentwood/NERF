function T = displayECodeNames(evec,ecodes)

ec_Names = cell(length(evec),1);
codelist = cell2mat(ecodes(:,2));

for i = 1:length(evec)
    curcode = evec(i);
    codedx = find(codelist==curcode);
    
    if isempty(codedx)
        ec_Names{i}='--';
    else
    ec_Names{i}=ecodes{codedx,1};
    end
end
e_codes = evec';
T = table(ec_Names,e_codes);
