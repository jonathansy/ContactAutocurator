function P = InterXFast(W,M)
%
% W: A 2xN vector giving x-values in row 1 and y-values in row 2 for a whisker.
% M: A 2xN vector giving x-values in row 1 and y-values in row 2 for a mask.
%
% We find only the closest point on the whisker to the mask. If the distance is
% more than half the farthest distance between a pair of adjacent points on the
% whisker, the whisker and mask are assumed to have no intersection. In that case
% return argument P is empty ([]).
%


% if more than 1 spacing-width minimum distance, cannot be a crossing.


% Here is one way to do it to finite accuracy
if size(W,1) ~= 2 || size(M,1) ~= 2
    error('Input are not 2xN matrices.')
end

nW = size(W,2);
nM = size(M,2);

d = zeros(nW,nM);
for kW=1:nW
    for kM=1:nM
        d(kW,kM)= sqrt((W(1,kW) - M(1,kM)).^2 + (W(2,kW) - M(2,kM)).^2);
    end
end

[minnum, ind] = min(min(d,[],2));


resolutionLimit = max( sqrt(diff(W(1,:)).^2 + diff(W(2,:)).^2) ) / 2; % Half the farthest distance 
                                                                      %between a pair of adjacent points on the whisker

if numel(ind) > 1
    ind = ind(1);
    minnum = minnum(1);
    disp('Found >1 mask-whisker intersection; taking first.')
end

if minnum > resolutionLimit
    P = [];
else
    P = W(:,ind);
end




