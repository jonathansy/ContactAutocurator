function [m,T] = jkalignx(img,varargin)

% Aligns images in fname for all indices in idx
% 
% m - mean image after the alignment
% T - optimal translation for each frame
% 
if nargin < 2
    idx = 1:size(img,3);
else
    idx = varargin{1};
end

if(length(idx)==1)
    
    A = img(:,:,idx(1));
    m = A;
    T = [0 0];
    
elseif (length(idx)==2)
    
    A = img(:,:,idx(1));
    B = img(:,:,idx(2));
    
    [u, v] = jkfftalign(A,B);
    
    Ar = circshift(A,[u,v]);
    m = (Ar+B)/2;
    T = [[u v] ; [0 0]];
    
else
    
    idx0 = idx(1:floor(end/2));
    idx1 = idx(floor(end/2)+1 : end);

    [A,T0] = jkalignx(img, idx0);
    [B,T1] = jkalignx(img, idx1);
   
    [u, v] = jkfftalign(A,B);
     
    Ar = circshift(A,[u, v]);
    m = (Ar+B)/2;
    T = [(ones(size(T0,1),1)*[u v] + T0) ; T1];
    
end
