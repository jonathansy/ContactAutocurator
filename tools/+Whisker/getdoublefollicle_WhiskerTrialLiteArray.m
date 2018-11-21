function [x1, y1, x2, y2] = getdoublefollicle_WhiskerTrialLiteArray(w,varargin)
%
% Get the coordinates of follicles from all the trials included, in double view exp (2016/10/26 JK)
% Modified from viewdouble_WhiskerTrialLiteArray(w,varargin)
%
% USAGE:
%
% [x1, y1, x2, y2] = getdoublefollicle_WhiskerTrialLiteArray(w,tid)
%
g.plotOnlyFirstContacts = false; 

if isa(w,'Whisker.WhiskerTrialLiteArray') % Initialize
    
    if nargin==1  % tid, contact_tid not given.
        tid = 0;
    elseif nargin==2 % tid but not contact_tid given.
        tid = varargin{1};
    elseif nargin > 2
        error('Too many input arguments.')
    end
    
    g.w = w;
    g.tid = tid;
    g.maxInd = length(w);
else
    error('Invalid argument.')
end
x1 = []; y1 = []; x2 = []; y2 = []; 
for i = 1 : g.maxInd
    x1 = [x1;g.w.trials{i}.get_follicleCoordsX(g.tid(1))'];
    y1 = [y1;g.w.trials{i}.get_follicleCoordsY(g.tid(1))'];
    x2 = [x2;g.w.trials{i}.get_follicleCoordsX(g.tid(2))'];
    y2 = [y2;g.w.trials{i}.get_follicleCoordsY(g.tid(2))'];
end

end












