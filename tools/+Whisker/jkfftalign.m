
function [u,v] = jkfftalign(A,B)

N = min(min(size(A)), min(size(B)));

if min(size(B)) < min(size(A))
    yidx = round(size(B,1)/2-N/2) + 1 : round(size(B,1)/2+ N/2);
    xidx = round(size(B,2)/2-N/2) + 1 : round(size(B,2)/2+ N/2);
else
    yidx = round(size(A,1)/2-N/2) + 1 : round(size(A,1)/2+ N/2);
    xidx = round(size(A,2)/2-N/2) + 1 : round(size(A,2)/2+ N/2);
end
A = A(yidx,xidx);
B = B(yidx,xidx);

C = fftshift(real(ifft2(fft2(A).*fft2(rot90(B,2)))));
[~,i] = max(C(:));
[ii, jj] = ind2sub(size(C),i);

u = round(N/2-ii);
v = round(N/2-jj);