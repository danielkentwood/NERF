function inspk = wavelet_coeff_KS(cc, par)

scales = par.scales;
feature = par.features;
inputs = par.inputs;
nspk = size(cc,1);
ls = size(cc,2);

for i=1:ls                                  % KS test for coefficient selection
    thr_dist = std(cc(:,i)) * 3;
    thr_dist_min = mean(cc(:,i)) - thr_dist;
    thr_dist_max = mean(cc(:,i)) + thr_dist;
    aux = cc(find(cc(:,i)>thr_dist_min & cc(:,i)<thr_dist_max),i);
    
    if length(aux) > 10;
        [ksstat]=test_ks(aux);
        sd(i)=ksstat;
    else
        sd(i)=0;
    end
end
[max_sd ind]=sort(sd);
coeff(1:inputs)=ind(ls:-1:ls-inputs+1);

inspk=zeros(nspk,inputs);
for i=1:nspk
    for j=1:inputs
        inspk(i,j)=cc(i,coeff(j));
    end
end