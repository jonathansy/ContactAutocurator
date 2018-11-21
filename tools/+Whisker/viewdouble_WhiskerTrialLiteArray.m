function viewdouble_WhiskerTrialLiteArray(w,varargin)
%
% Ad hoc viewer for Whisker.WhiskerTrialLiteArray objects.
%
% USAGE:
%
% view_WhiskerTrialLiteArray(w,tid)
% view_WhiskerTrialLiteArray(w,tid,contact_tid)
% view_WhiskerTrialLiteArray(w,tid,contact_tid,'plotOnlyFirstContacts') -- plots vertical lines only
%       for the first contact frame in a group of contiguous contact frames.
%
g.plotOnlyFirstContacts = false; 

if isa(w,'Whisker.WhiskerTrialLiteArray') % Initialize
    
    if nargin==1  % tid, contact_tid not given.
        tid = 0;
        contact_tid = [];
    elseif nargin==2 % tid but not contact_tid given.
        tid = varargin{1};
        contact_tid = [];
    elseif nargin==3 % tid but not contact_tid given.
        tid = varargin{1};
        contact_tid = varargin{2};
    elseif nargin==4 % 
        tid = varargin{1};
        contact_tid = varargin{2};
        if strcmp('plotOnlyFirstContacts',varargin{3})
            g.plotOnlyFirstContacts = true;
        else
            error('Invalid fourth argument')
        end
    elseif nargin > 4
        error('Too many input arguments.')
    end
    
    g.w = w;
    g.tid = tid;
    g.contact_tid = contact_tid;
    
    h=figure('Color','white','Position',[62 90 1086 974]); ht = uitoolbar(h);
    mname = mfilename(1);
    a = .20:.05:0.95; b(:,:,1) = repmat(a,16,1)'; b(:,:,2) = repmat(a,16,1); b(:,:,3) = repmat(flipdim(a,2),16,1);
    bbutton = uipushtool(ht,'CData',b,'TooltipString','Back');
    fbutton = uipushtool(ht,'CData',b,'TooltipString','Forward','Separator','on');
    set(fbutton,'ClickedCallback',['Whisker.' mname '(''next'')'])
    set(bbutton,'ClickedCallback',['Whisker.' mname '(''last'')'])
    g.ind = 1; % Add a field to keep track of the current index.
    g.maxInd = length(w);
%     figure('Color','white','Position',[1168 732 393 330]);
%     g.h2 = axes;
%     figure(h)
    
    %     cellfun(@(x) x.trackerFileName, wl.trials,'UniformOutput',false)
elseif strcmp(w,'next')
    h = gcf;
    g = get(h,'UserData');
    if g.ind < g.maxInd
        cla
        g.ind = g.ind + 1;
    end
    %     disp(['Called next: ' int2str(g.ind) '/' int2str(g.maxInd)])
    
elseif strcmp(w,'last')
    h = gcf;
    g = get(h,'UserData');
    if g.ind > 1
        cla
        g.ind = g.ind - 1;
    end
    %     disp(['Called last: ' int2str(g.ind) '/' int2str(g.maxInd)])
else
    error('Invalid argument.')
end

set(h,'UserData',g)

f = g.w.trials{g.ind}.get_time(g.tid) / g.w.trials{g.ind}.framePeriodInSec;
touch_ind = g.w.trials{g.ind}.th_touch_frames;

tit = g.w.trials{g.ind}.trackerFileName;
tit = [int2str(g.ind) '/' int2str(g.maxInd) ': ' tit];



subplot(211)
y = g.w.trials{g.ind}.get_thetaAtBase(g.tid(1));
y2 = g.w.trials{g.ind}.get_thetaAtBase(g.tid(2));
plot(f,y,'r.', f,y2,'k.'), ylabel('deg'), hold on, 
plot(f(touch_ind),y(touch_ind),'b.', f(touch_ind),y2(touch_ind),'g.')
title([tit ' Theta at base, top view (red) and front view (black)']), hold off
subplot(212)
y = g.w.trials{g.ind}.get_deltaKappa(g.tid(1));
y2 = g.w.trials{g.ind}.get_deltaKappa(g.tid(2));
plot(f,y,'r.', f,y2,'k.'), ylabel('1/mm'), hold on,
plot(f(touch_ind),y(touch_ind),'b.', f(touch_ind),y2(touch_ind),'g.')
title('Change in kappa, top view (red) and front view (black)'), hold off
xlabel('Time (frames)')

% x = g.w.trials{g.ind}.get_follicleCoordsX(g.tid(1));
% y = g.w.trials{g.ind}.get_follicleCoordsY(g.tid(1));
% x2 = g.w.trials{g.ind}.get_follicleCoordsX(g.tid(2));
% y2 = g.w.trials{g.ind}.get_follicleCoordsY(g.tid(2));
% if ~isempty(x) && ~isempty(y), plot(g.h2,x,y,'r.', x2,y2,'k.'), end; hold on; 
% set(g.h2,'XLim',[0 500],'YLim',[0 300],'YDir','reverse','PlotBoxAspectRatio',[500 300 1]);
% title(g.h2,'Follicle position')


end












