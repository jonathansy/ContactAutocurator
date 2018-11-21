function view_WhiskerTrialLiteArray(w,varargin)
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
    figure('Color','white','Position',[1168 732 393 330]);
    g.h2 = axes;
    figure(h)
    
    %     cellfun(@(x) x.trackerFileName, wl.trials,'UniformOutput',false)
elseif strcmp(w,'next')
    h = gcf;
    g = get(h,'UserData');
    if g.ind < g.maxInd
        g.ind = g.ind + 1;
    end
    %     disp(['Called next: ' int2str(g.ind) '/' int2str(g.maxInd)])
    
elseif strcmp(w,'last')
    h = gcf;
    g = get(h,'UserData');
    if g.ind > 1
        g.ind = g.ind - 1;
    end
    %     disp(['Called last: ' int2str(g.ind) '/' int2str(g.maxInd)])
else
    error('Invalid argument.')
end

set(h,'UserData',g)

f = g.w.trials{g.ind}.get_time(g.tid) / g.w.trials{g.ind}.framePeriodInSec;

tit = g.w.trials{g.ind}.trackerFileName;
k = strfind(tit,'_');
tit = [int2str(g.ind) '/' int2str(g.maxInd) ': ' tit(1:(k-1)) '\_' tit((k+1):end)];


subplot(511)
y = g.w.trials{g.ind}.get_distanceToPoleCenter(g.tid);
if ~isempty(y), plot(f,y,'k.-'), else cla, end; ylabel('mm'); title([tit ' Distance to pole center']);
subplot(512); cla
y = g.w.trials{g.ind}.get_thetaAtContact(g.tid);
if ~isempty(y), plot(f,y,'k.-'), else cla,  end; hold on; ylabel('deg'); title('Theta at base (red) and contact (black)')
y = g.w.trials{g.ind}.get_thetaAtBase(g.tid);
if ~isempty(y), plot(f,y,'r.-'), else cla,  end;
subplot(513)
y = g.w.trials{g.ind}.get_deltaKappa(g.tid);
if ~isempty(y), plot(f,y,'k.-'), else cla,  end; ylabel('1/mm'); title('Change in kappa')
subplot(514)
y = g.w.trials{g.ind}.get_M0(g.tid);
if ~isempty(y), plot(f,y,'k.-'), else cla,  end; ylabel('newton-meters'); title('Moment at follicle')
subplot(515)
y = g.w.trials{g.ind}.get_Faxial(g.tid);
if ~isempty(y), plot(f,y,'k.-'), else cla,  end; ylabel('N'); title('F_{axial}')
xlabel('Time (frames)')
 
if ~isempty(g.contact_tid)
    contactTimes = round(g.w.trials{g.ind}.get_time(g.contact_tid) / g.w.trials{g.ind}.framePeriodInSec);
    if ~isempty(contactTimes)
        for k=1:5
            subplot(5,1,k)
            xdat = get(get(gca,'Children'),'XData');
            if ~isempty(xdat)
                ylm = get(gca,'YLim');
                if g.plotOnlyFirstContacts == true
%                     contactTimes = contactTimes(abs([1 diff(contactTimes)] - 1) > 1e-9);
                    contactTimes = contactTimes([2 diff(contactTimes)] > 1);
                end
                for q=1:length(contactTimes)
                    line([contactTimes(q) contactTimes(q)],ylm,'Color','b')
                end
            end
        end
    end
end

x = g.w.trials{g.ind}.get_follicleCoordsX(g.tid);
y = g.w.trials{g.ind}.get_follicleCoordsY(g.tid);
if ~isempty(x) && ~isempty(y), plot(g.h2,x,y,'k.'), end;
set(g.h2,'XLim',[0 180],'YLim',[0 250],'YDir','reverse','PlotBoxAspectRatio',[180 250 1]);
title(g.h2,'Follicle position')

end












