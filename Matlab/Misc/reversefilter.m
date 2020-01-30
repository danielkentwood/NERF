function x = reversefilter(b, a, y)

 

tmp = filter(b, a, y(end:-1:1));

z = tmp(end:-1:1);

if(size(z,1) < size(z,2))

    x = transpose(z);

else

    x = z;

end