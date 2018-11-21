function view_M0_Fax(g)
%
% Ad hoc viewer.
%
%
%
if isstruct(g) % Initialize
    
    h=figure('Color','white','Position',[62 90 1086 974]); ht = uitoolbar(h);
    mname = mfilename(1);
    a = .20:.05:0.95; b(:,:,1) = repmat(a,16,1)'; b(:,:,2) = repmat(a,16,1); b(:,:,3) = repmat(flipdim(a,2),16,1);
    bbutton = uipushtool(ht,'CData',b,'TooltipString','Back');
    fbutton = uipushtool(ht,'CData',b,'TooltipString','Forward','Separator','on');
    set(fbutton,'ClickedCallback',['Whisker.' mname '(''next'')'])
    set(bbutton,'ClickedCallback',['Whisker.' mname '(''last'')'])
    g.ind = 1; % Add a field to keep track of the current index.
    g.maxInd = length(g.fileNames);
    figure('Color','white','Position',[1168 732 393 330]);
    g.h2 = axes; 
    figure(h)
    
    %     ax1pos = [0.1280 0.7671 0.5 0.1512]; %[left, bottom, width, height];
%     g.ax.ax1 = axes('Position',ax1pos);
% %     g.ax.ax2 = axes('Position',ax1pos - [0 ax1pos(
    
elseif strcmp(g,'next')
    h = gcf;
    g = get(h,'UserData');
        if g.ind < g.maxInd
            g.ind = g.ind + 1;
        end
%     disp(['Called next: ' int2str(g.ind) '/' int2str(g.maxInd)])
    
elseif strcmp(g,'last')
    h = gcf;
    g = get(h,'UserData');
        if g.ind > 1
            g.ind = g.ind - 1;
        end
%     disp(['Called last: ' int2str(g.ind) '/' int2str(g.maxInd)])
end

set(h,'UserData',g)

f = g.frames{g.ind};

tit = g.fileNames{g.ind};
k = strfind(tit,'_');
tit = [int2str(g.ind) '/' int2str(g.maxInd) ': ' tit(1:(k-1)) '\_' tit((k+1):end)];

subplot(511)
plot(f,g.distanceToPole{g.ind},'k.-'); title([tit ' Distance to pole center'])
subplot(512); cla
plot(f,g.thetaAtBase{g.ind},'r.-'); hold on
plot(f,g.thetaAtContact{g.ind},'k.-'); ylabel('deg'); title('Theta at base (red) and contact (black)')
subplot(513)
plot(f,g.dkappa{g.ind},'k.-'); ylabel('1/mm'); title('Change in kappa')
subplot(514)
plot(f,g.M0{g.ind},'k.-'); ylabel('newton-meters'); title('Moment at follicle')
subplot(515)
plot(f,g.Faxial{g.ind},'k.-'); ylabel('N'); title('F_{axial}')
xlabel('Time (frames)')
if ~isempty(g.contactFrames)
    if ~isempty(g.contactFrames{g.ind})
        for k=1:5
            subplot(5,1,k)
            ylm = get(gca,'YLim');
            c = g.contactFrames{g.ind};
            for q=1:length(c)
                line([c(q) c(q)],ylm,'Color','b')
            end
        end
    end
end

plot(g.h2,g.follX{g.ind},g.follY{g.ind},'k.')
set(g.h2,'XLim',[0 180],'YLim',[0 250],'YDir','reverse','PlotBoxAspectRatio',[180 250 1]); 
title(g.h2,'Follicle position')

end












