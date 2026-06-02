function drawRayDiagram(ax, u, h, f1, f2, d, mode, out)

cla(ax);
hold(ax,'on');
grid(ax,'on');


% GUARD: NaN in out fields
if mode == 1
    criticalFields = [out.v, out.hi, out.m];
else
    criticalFields = [out.v1, out.m1, out.h1];
    if ~out.hasInfinity && isempty(out.badCase)
        criticalFields = [criticalFields, out.v2, out.m2, out.hi];
    end
end

if any(isnan(criticalFields)) && ~out.hasInfinity && isempty(out.badCase)
    text(ax, 0.5, 0.5, {'Diagram unavailable:', out.status}, ...
        'Units','normalized','HorizontalAlignment','center', ...
        'FontSize',15,'Color','r','FontWeight','bold');
    title(ax,'Ray Diagram (Unavailable)');
    xlabel(ax,'x (m)'); ylabel(ax,'y (m)');
    hold(ax,'off');
    return;
end


% EXTREME ANGLE CHECK
angleRad = atan(abs(h)/max(u,1e-9));
angleDeg = rad2deg(angleRad);

showParaxialWarning = false;
if u < 0.5 || angleDeg > 30
    showParaxialWarning = true;
end

if abs(f1) < 0.1 || (mode==2 && abs(f2) < 0.1)
    warning('drawRayDiagram:smallFocal','Very small focal length detected.');
end

if mode==1 && isfinite(out.m) && abs(out.m) > 100
    warning('drawRayDiagram:highMag','Very high magnification (m = %.1f).', out.m);
end


% HELPER FUNCTIONS
    function yt = yOnLineAtX(x1,y1,x2,y2,xt)
        if abs(x2-x1) < 1e-12
            yt = y2;
        else
            t = (xt-x1)/(x2-x1);
            yt = y1 + t*(y2-y1);
        end
    end

    function [xc1,yc1,xc2,yc2,visible] = clipRayY(x1,y1,x2,y2,yLo,yHi)
        visible = true;
        xc1=x1; yc1=y1; xc2=x2; yc2=y2;
        if (y1>yHi && y2>yHi) || (y1<yLo && y2<yLo)
            visible = false; return;
        end
        dy = y2-y1; dx = x2-x1;
        tMin = 0; tMax = 1;
        if abs(dy) > 1e-12
            t_hi = (yHi-y1)/dy; t_lo = (yLo-y1)/dy;
            tMin = max(tMin, min(t_hi,t_lo));
            tMax = min(tMax, max(t_hi,t_lo));
        end
        if tMin > tMax; visible = false; return; end
        xc1 = x1+tMin*dx; yc1 = y1+tMin*dy;
        xc2 = x1+tMax*dx; yc2 = y1+tMax*dy;
    end

    function plotClipped(x1,y1,x2,y2,yLo,yHi,colorVal,lineStyle,lineWidth)
        [xc1,yc1,xc2,yc2,vis] = clipRayY(x1,y1,x2,y2,yLo,yHi);
        if vis && (abs(xc2-xc1)>1e-10 || abs(yc2-yc1)>1e-10)
            plot(ax,[xc1 xc2],[yc1 yc2],lineStyle,'Color',colorVal,'LineWidth',lineWidth);
        end
    end

    function yL = safeLabelY(yTip, yHi)
        minOff = 0.10 * yHi;
        if yTip >= 0
            yL = max(yTip, minOff);
        else
            yL = min(yTip, -minOff);
        end
    end

    function result = tooClose(x1, x2, xMin, xMax)
        result = abs(x1-x2) < 0.06*(xMax-xMin);
    end

    function putLabel(xPos, yPos, labelStr, vAlign, hAlign, col)
        text(ax, xPos, yPos, labelStr, ...
            'VerticalAlignment', vAlign, ...
            'HorizontalAlignment', hAlign, ...
            'FontSize', 13, ...
            'Color', col, ...
            'BackgroundColor', [1 1 1], ...
            'EdgeColor', 'none', ...
            'Clipping', 'on', ...
            'Margin', 1);
    end

    function arrowLabel(xPos, yTip, labelStr, col)
        % Places label just beyond arrow tip, clear of arrowhead
        offset = 0.08 * yHi;
        if yTip < 0
            text(ax, xPos, yTip - offset, labelStr, ...
                'VerticalAlignment','top','HorizontalAlignment','center', ...
                'FontSize',13,'Color',col,'BackgroundColor',[1 1 1], ...
                'EdgeColor','none','Clipping','on','Margin',1);
        else
            text(ax, xPos, yTip + offset, labelStr, ...
                'VerticalAlignment','bottom','HorizontalAlignment','center', ...
                'FontSize',13,'Color',col,'BackgroundColor',[1 1 1], ...
                'EdgeColor','none','Clipping','on','Margin',1);
        end
    end

    % Storage for focal labels — collected first, drawn together to handle overlaps
    focalLblList = {};

    function collectFocalLabels(xLens, fLen, col, suffix)
        if fLen == 0; return; end
        sides = [xLens + fLen, xLens - fLen];
        for k = 1:2
            xF = sides(k);
            if xF >= xMin && xF <= xMax
                focalLblList{end+1} = {xF, xF, ['f' suffix], col}; %#ok<AGROW>
            end
        end
    end

    function drawFocalLabels()
        % Draw all collected focal labels with two-row stagger to avoid overlaps
        n = numel(focalLblList);
        if n == 0; return; end
        xLbls = zeros(1,n);
        for i = 1:n; xLbls(i) = focalLblList{i}{2}; end

        threshold = 0.08 * (xMax - xMin);
        rows = zeros(1,n);
        [~, sortIdx] = sort(xLbls);
        lastX = -inf; lastRow = 0;
        for i = 1:n
            si = sortIdx(i);
            if abs(xLbls(si) - lastX) < threshold
                rows(si) = 1 - lastRow;
            else
                rows(si) = 0;
            end
            lastRow = rows(si);
            lastX   = xLbls(si);
        end

        yRow0 = -tickSize * 3;
        yRow1 = -tickSize * 7;

        for i = 1:n
            entry = focalLblList{i};
            xTick = entry{1}; xLbl = entry{2};
            lbl   = entry{3}; col  = entry{4};
            plot(ax,[xTick xTick],[-tickSize tickSize],'-','Color',col,'LineWidth',2);
            yLbl = yRow0; if rows(i)==1; yLbl = yRow1; end
            text(ax, xLbl, yLbl, lbl, ...
                'HorizontalAlignment','center','VerticalAlignment','top', ...
                'FontSize',15,'Color',col,'FontWeight','bold', ...
                'Clipping','on','BackgroundColor',[1 1 1]);
        end
    end

    function bigOffScaleMsg(xPos, yPos, vVal, hiVal)
        text(ax, xPos, yPos, ...
            {sprintf('Image forms at v = %.4g m', vVal), ...
             sprintf('Image height = %.4g m', hiVal), ...
             'Too far off-scale to display fully.', ...
             'Dotted rays show correct direction — image is where they converge.'}, ...
            'HorizontalAlignment','center','VerticalAlignment','middle', ...
            'FontSize',13,'Color',[0.6 0 0],'FontWeight','bold', ...
            'BackgroundColor',[1 0.95 0.95],'EdgeColor',[0.8 0 0], ...
            'Clipping','on','LineWidth',1.5,'Margin',8);
    end

    function drawAfterL2(yHit, col)
        % Draw post-L2 ray segment: solid to real Final Image,
        % or dashed (forward) + dotted (back-ext) for virtual Final Image
        if ~isVirtualFinal
            plotClipped(xL2,yHit, xFinal,yFinal, yLo,yHi, col,'-',1.6);
        else
            yFarFwd = yOnLineAtX(xFinal,yFinal, xL2,yHit, xFar);
            plotClipped(xL2,yHit, xFar,yFarFwd,   yLo,yHi, col,'--',1.6);
            plotClipped(xL2,yHit, xFinal,yFinal,   yLo,yHi, col,':',1.2);
        end
    end


% ADAPTIVE X-AXIS LIMITS
xObj = -u; xL1 = 0;

if mode==1
    xImg = out.v;

    % FIX: cap x range so a far virtual image doesn't shrink the diagram
    xImgCapped = sign(xImg) * min(abs(xImg), 3*max(abs(u), abs(f1)));
    positions = [xObj, xL1, xImgCapped];
    spread    = max(positions)-min(positions);
    margin    = max(0.25*spread,0.5);
    xMax = max(positions)+margin;
    xMin = min(positions)-margin;
else
    xL2    = d;
    xI1    = out.v1;
    xFinal = d+out.v2;
    yI1    = out.m1*h;
    yFinal = out.hi;

    % FIX: cap far positions so large d or v2 doesn't shrink the diagram
    refScale     = max([abs(u), abs(f1), 1]);
    xI1capped    = sign(xI1)    * min(abs(xI1),    10*refScale);
    xFinalCapped = sign(xFinal) * min(abs(xFinal),  10*refScale);

    % Include image-side focal points so f_1 and f_2 labels are always in range
    xF1img   = xL1 + f1;
    xF2img   = xL2 + f2;
    xF1capped = sign(xF1img) * min(abs(xF1img), 10*refScale);
    xF2capped = sign(xF2img) * min(abs(xF2img), 10*refScale);

    positions = [xObj,xL1,xL2,xI1capped,xFinalCapped,xF1capped,xF2capped];
    spread    = max(positions)-min(positions);
    margin    = max(0.25*spread,1.0);
    xMax = max(positions)+margin;
    xMin = min(positions)-margin;
end

if (xMax-xMin) < 1.0
    center = (xMax+xMin)/2;
    xMax = center+0.5; xMin = center-0.5;
end

% Cap for very large spans
MAX_X_SPAN = 20*max(abs(u),max(abs(f1),1));
if (xMax-xMin) > MAX_X_SPAN
    xMax = xMin+MAX_X_SPAN;
    offScreenNote = true;
else
    offScreenNote = false;
end


% Y-LIMITS
MAX_IMG_FACTOR = 4;

if mode==1
    objHeight  = abs(h);
    imgHeight  = abs(out.hi);
    displayImg = min(imgHeight, MAX_IMG_FACTOR*max(objHeight,0.1));
    yMax_display = max([objHeight,displayImg,0.5]);
else
    objHeight  = abs(h);
    intHeight  = abs(yI1);
    finHeight  = abs(yFinal);
    ref        = max(objHeight,0.1);
    displayInt = min(intHeight, MAX_IMG_FACTOR*ref);
    displayFin = min(finHeight, MAX_IMG_FACTOR*ref);
    yMax_display = max([objHeight,displayInt,displayFin,0.5]);
end

yPad = 0.25*yMax_display;
yHi  =  yMax_display+yPad;
yLo  = -yHi;

ySpan = max(1,abs(h));
if mode==2 && isfinite(yI1) && isfinite(yFinal)
    ySpan = max([ySpan,abs(yI1),abs(yFinal),yMax_display]);
else
    ySpan = max(ySpan,yMax_display);
end

xlim(ax,[xMin xMax]); ylim(ax,[yLo yHi]);


% OFF-SCALE FLAGS (used to suppress redundant small notices)
if mode==1
    isImgOffScale = abs(out.hi) > MAX_IMG_FACTOR*max(abs(h),0.1);
    isTwoLensOffScale = false;
    isI1OffScale = false;
    isFinalOffScale = false;
else
    isImgOffScale = false;
    ref = max(abs(h),0.1);
    isI1OffScale     = abs(yI1)    > MAX_IMG_FACTOR*ref;
    isFinalOffScale  = abs(yFinal) > MAX_IMG_FACTOR*ref;
    isTwoLensOffScale = isI1OffScale || isFinalOffScale;
end


% OPTICAL AXIS + OBJECT
plot(ax,[xMin xMax],[0 0],'k-','LineWidth',1);

if xObj < xMin
    text(ax, xMin+0.02*(xMax-xMin), yHi*0.70, ...
        sprintf('Object at x=%.3g m (off-screen)', xObj), ...
        'FontSize',11,'Color','k', ...
        'BackgroundColor',[1 1 1],'EdgeColor',[0.7 0.7 0.7],'Clipping','on');
else
    if abs(h) < 1e-9
        plot(ax,xObj,0,'ko','MarkerFaceColor','k','MarkerSize',8);
        text(ax,xObj,yHi*0.12,'Point Object (h=0)', ...
            'HorizontalAlignment','center','FontSize',13,'Color','k', ...
            'BackgroundColor',[1 1 1],'Clipping','on');
    else
        drawArrow(ax,xObj,0,xObj,h,'k');
        putLabel(xObj, safeLabelY(h,yHi), 'Object','bottom','center','k');
    end
end

% Only show off-screen note when there is no big off-scale message already
if offScreenNote && ~isImgOffScale && ~isTwoLensOffScale
    text(ax,xMin+0.02*(xMax-xMin),yHi*0.82, ...
        'Note: Some elements off-screen', ...
        'FontSize',10,'Color',[0.6 0 0],'BackgroundColor',[1 1 1],'Clipping','on');
end

tickSize = min(0.05,0.02*ySpan);


% SINGLE LENS
if mode==1

    plot(ax,[xL1 xL1],[yLo yHi],'b-','LineWidth',2);
    putLabel(xL1, yHi*0.92, 'Lens 1','top','left','b');
    plot(ax,[ f1  f1],[-tickSize tickSize],'b-','LineWidth',2);
    plot(ax,[-f1 -f1],[-tickSize tickSize],'b-','LineWidth',2);
    collectFocalLabels(xL1, f1, 'b', '');
    drawFocalLabels();

    % FIX: guard image arrow — dot only if image height is off-scale
    if ~isImgOffScale && abs(h) >= 1e-9
        drawArrow(ax,xImg,0,xImg,out.hi,'g');
    else
        plot(ax,xImg,0,'go','MarkerFaceColor','g','MarkerSize',8);
    end

    imgLabelStr = 'Image';
    if out.v < 0; imgLabelStr = 'Image (Virtual)'; end
    if tooClose(xImg,xL1,xMin,xMax)
        putLabel(xImg, safeLabelY(-abs(out.hi)*0.5,yHi), imgLabelStr,'top','center','g');
    else
        arrowLabel(xImg, out.hi, imgLabelStr, 'g');
    end

    if isImgOffScale
        bigOffScaleMsg(xMin + 0.72*(xMax-xMin), yHi*0.72, out.v, out.hi);
    end

    xFar      = xMax;
    isVirtual = (out.v < 0);

    % Ray 1 (PINK): horizontal incident → through back focal
    try
        plotClipped(xObj,h, 0,h, yLo,yHi,'m','-',1.6);
        if isVirtual
            yFar1 = yOnLineAtX(0,h, f1,0, xFar);
            plotClipped(0,h, xFar,yFar1,  yLo,yHi,'m','--',1.6);
            plotClipped(0,h, xImg,out.hi, yLo,yHi,'m',':',1.2);
        else
            plotClipped(0,h, xImg,out.hi, yLo,yHi,'m','-',1.6);
        end
    catch ME
        warning('drawRayDiagram:pinkRay','Pink ray: %s',ME.message);
    end

    % Ray 2 (CYAN): through optical centre, undeviated
    try
        plotClipped(xObj,h, 0,0, yLo,yHi,'c','-',1.6);
        if isVirtual
            yFar2 = yOnLineAtX(xObj,h, 0,0, xFar);
            plotClipped(0,0, xFar,yFar2,  yLo,yHi,'c','--',1.6);
            plotClipped(0,0, xImg,out.hi, yLo,yHi,'c',':',1.2);
        else
            plotClipped(0,0, xImg,out.hi, yLo,yHi,'c','-',1.6);
        end
    catch ME
        warning('drawRayDiagram:cyanRay','Cyan ray: %s',ME.message);
    end

    % Ray 3 (GREEN): through front focal (-f1), exits L1 horizontal at h1
    % Skip if object is at front focal (u=f1) — degenerate case
    try
        if abs(u - abs(f1)) > 1e-6
            xFobj    = -f1;
            yAtLens3 = yOnLineAtX(xObj,h, xFobj,0, 0);  % = out.hi mathematically
            if abs(yAtLens3) <= yHi * 3
                plotClipped(xObj,h, 0,yAtLens3, yLo,yHi,[0 0.6 0],'-',1.6);
                if isVirtual
                    plotClipped(0,yAtLens3, xFar,yAtLens3, yLo,yHi,[0 0.6 0],'--',1.6);
                    plotClipped(0,yAtLens3, xImg,out.hi,   yLo,yHi,[0 0.6 0],':',1.2);
                else
                    plotClipped(0,yAtLens3, xImg,out.hi,   yLo,yHi,[0 0.6 0],'-',1.6);
                end
            end
        end
    catch ME
        warning('drawRayDiagram:greenRay','Green ray: %s',ME.message);
    end

    if showParaxialWarning
        if u < 0.5
            warnTxt = sprintf('WARNING: Object very close (u=%.2f m)\nParaxial approx invalid',u);
        else
            warnTxt = sprintf('WARNING: Large angles (%.1f deg)\nParaxial approximation violated',angleDeg);
        end
        text(ax,mean([xMin xMax]),yHi*0.85,warnTxt, ...
            'HorizontalAlignment','center','VerticalAlignment','middle', ...
            'FontSize',12,'FontWeight','bold','Color',[0.8 0 0], ...
            'BackgroundColor',[1 1 0.8],'EdgeColor',[0.8 0 0], ...
            'Clipping','on','LineWidth',2,'Margin',5);
    end

    title(ax,'Ray Diagram (Principal Rays)');
    xlabel(ax,'x (m)'); ylabel(ax,'y (m)');
    hold(ax,'off');
    return;
end


% TWO LENSES
if abs(d) < 1e-9
    if abs(f1+f2) < 1e-9
        f_eff_str = 'Inf (f1=-f2)';
        f_eff = Inf;
    else
        f_eff = (f1*f2)/(f1+f2);
        f_eff_str = sprintf('%.3g m', f_eff);
    end

    plot(ax,[0 0],[yLo yHi],'Color',[0.5 0 0.5],'LineWidth',3);
    text(ax, 0, yHi*0.92, ...
        sprintf('Lenses in contact  f_{eff}=%s', f_eff_str), ...
        'HorizontalAlignment','left','Color',[0.5 0 0.5],'FontSize',15, ...
        'BackgroundColor',[1 1 1],'Clipping','on');

    if isfinite(f_eff)
        plot(ax,[ f_eff  f_eff],[-tickSize tickSize],'Color',[0.5 0 0.5],'LineWidth',2);
        plot(ax,[-f_eff -f_eff],[-tickSize tickSize],'Color',[0.5 0 0.5],'LineWidth',2);
        collectFocalLabels(0, f_eff, [0.5 0 0.5], '_{eff}');
        drawFocalLabels();
    end

    xFc = out.v2; yFc = out.hi;
    if isfinite(xFc) && isfinite(yFc)
        isFcOffScale = abs(yFc) > MAX_IMG_FACTOR*max(abs(h),0.1);
        if ~isFcOffScale && abs(h) >= 1e-9
            drawArrow(ax,xFc,0,xFc,yFc,'g');
        else
            plot(ax,xFc,0,'go','MarkerFaceColor','g','MarkerSize',8);
        end
        isVirtContact = (out.v2 < 0);
        lStr = 'Final Image'; if isVirtContact; lStr = 'Final Image (Virtual)'; end
        if tooClose(xFc,0,xMin,xMax)
            putLabel(xFc, safeLabelY(-abs(yFc)*0.5,yHi), lStr,'top','center',[0 0.5 0]);
        else
            arrowLabel(xFc, yFc, lStr, [0 0.5 0]);
        end

        % Big message in upper-right corner if contact lens final image is off-scale
        if isFcOffScale
            bigOffScaleMsg(xMin + 0.72*(xMax-xMin), yHi*0.72, out.v2, out.hi);
        end

        if isfinite(f_eff)
            xFar = xMax;

            % Ray 1 (PINK)
            try
                plotClipped(xObj,h, 0,h, yLo,yHi,'m','-',1.6);
                if isVirtContact
                    yFar1 = yOnLineAtX(0,h, f_eff,0, xFar);
                    plotClipped(0,h, xFar,yFar1, yLo,yHi,'m','--',1.6);
                    plotClipped(0,h, xFc,yFc,    yLo,yHi,'m',':',1.2);
                else
                    plotClipped(0,h, xFc,yFc,    yLo,yHi,'m','--',1.6);
                end
            catch
            end

            % Ray 2 (CYAN)
            try
                plotClipped(xObj,h, 0,0, yLo,yHi,'c','-',1.6);
                if isVirtContact
                    yFar2 = yOnLineAtX(xObj,h, 0,0, xFar);
                    plotClipped(0,0, xFar,yFar2, yLo,yHi,'c','--',1.6);
                    plotClipped(0,0, xFc,yFc,    yLo,yHi,'c',':',1.2);
                else
                    plotClipped(0,0, xFc,yFc,    yLo,yHi,'c','--',1.6);
                end
            catch
            end

            % Ray 3 (GREEN)
            try
                xFobj    = -f_eff;
                yAtLens3 = yOnLineAtX(xObj,h, xFobj,0, 0);
                plotClipped(xObj,h,     0,yAtLens3,    yLo,yHi,[0 0.6 0],'-',1.6);
                if isVirtContact
                    plotClipped(0,yAtLens3, xFar,yAtLens3, yLo,yHi,[0 0.6 0],'--',1.6);
                    plotClipped(0,yAtLens3, xFc,yFc,       yLo,yHi,[0 0.6 0],':',1.2);
                else
                    plotClipped(0,yAtLens3, xFc,yFc,       yLo,yHi,[0 0.6 0],'--',1.6);
                end
            catch
            end
        end
    end

    title(ax,'Ray Diagram (Lenses in Contact, d = 0)');
    xlabel(ax,'x (m)'); ylabel(ax,'y (m)');
    hold(ax,'off');
    return;
end


% LENS 1 (d > 0 only)
plot(ax,[xL1 xL1],[yLo yHi],'b-','LineWidth',2);
putLabel(xL1, yHi*0.92, 'Lens 1','top','left','b');
plot(ax,[ f1  f1],[-tickSize tickSize],'b-','LineWidth',2);
plot(ax,[-f1 -f1],[-tickSize tickSize],'b-','LineWidth',2);
collectFocalLabels(xL1, f1, 'b', '_1');


% LENS 2
plot(ax,[xL2 xL2],[yLo yHi],'r-','LineWidth',2);
if tooClose(xL1,xL2,xMin,xMax)
    putLabel(xL2, yHi*0.75, 'Lens 2','top','left','r');
else
    putLabel(xL2, yHi*0.92, 'Lens 2','top','left','r');
end
plot(ax,[xL2+f2 xL2+f2],[-tickSize tickSize],'r-','LineWidth',2);
plot(ax,[xL2-f2 xL2-f2],[-tickSize tickSize],'r-','LineWidth',2);
collectFocalLabels(xL2, f2, 'r', '_2');
drawFocalLabels();

if isI1OffScale || isFinalOffScale
    msgLines = {};
    if isI1OffScale
        msgLines{end+1} = sprintf('Image 1 height = %.4g m (off-scale)', yI1);
    end
    if isFinalOffScale
        msgLines{end+1} = sprintf('Final image height = %.4g m (off-scale)', yFinal);
    end
    msgLines{end+1} = 'Too far off-scale to display fully.';
    msgLines{end+1} = 'Rays shown are correct — image is where dotted lines converge.';
    text(ax, xMin + 0.72*(xMax-xMin), yHi*0.72, msgLines, ...
        'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'FontSize',13,'Color',[0.6 0 0],'FontWeight','bold', ...
        'BackgroundColor',[1 0.95 0.95],'EdgeColor',[0.8 0 0], ...
        'Clipping','on','LineWidth',1.5,'Margin',8);
end


% CASE FLAGS
isVirtualInt   = (out.v1 < 0);
isVirtualObj2  = isfield(out,'u2') && (out.u2 < 0);
isVirtualFinal = (out.v2 < 0);


% INTERMEDIATE IMAGE MARKER
if isVirtualInt
    if ~isI1OffScale
        drawArrow(ax,xI1,0,xI1,yI1,[0.7 0.7 0.7]);
    else
        plot(ax,xI1,0,'o','Color',[0.7 0.7 0.7],'MarkerFaceColor',[0.7 0.7 0.7],'MarkerSize',8);
    end
    if tooClose(xI1,xL2,xMin,xMax)
        putLabel(xI1, -safeLabelY(abs(yI1),yHi), 'Image 1 (Virtual)','top','center',[0.6 0.6 0.6]);
    else
        arrowLabel(xI1, yI1, 'Image 1 (Virtual)', [0.6 0.6 0.6]);
    end
elseif isVirtualObj2
    if ~isI1OffScale
        drawArrow(ax,xI1,0,xI1,yI1,[0.8 0.4 0]);
    else
        plot(ax,xI1,0,'o','Color',[0.8 0.4 0],'MarkerFaceColor',[0.8 0.4 0],'MarkerSize',8);
    end
    if tooClose(xI1,xL2,xMin,xMax)
        putLabel(xI1, -safeLabelY(abs(yI1),yHi), 'Virtual Object (L2)','top','center',[0.8 0.4 0]);
    else
        arrowLabel(xI1, yI1, 'Virtual Object (L2)', [0.8 0.4 0]);
    end
else
    if ~isI1OffScale
        drawArrow(ax,xI1,0,xI1,yI1,[0 0.6 0]);
    else
        plot(ax,xI1,0,'o','Color',[0 0.6 0],'MarkerFaceColor',[0 0.6 0],'MarkerSize',8);
    end
    if tooClose(xI1,xL2,xMin,xMax)
        putLabel(xI1, -safeLabelY(abs(yI1),yHi), 'Image 1','top','center',[0 0.5 0]);
    else
        arrowLabel(xI1, yI1, 'Image 1', [0 0.5 0]);
    end
end


% FINAL IMAGE MARKER
if isVirtualFinal
    if ~isFinalOffScale
        drawArrow(ax,xFinal,0,xFinal,yFinal,[0.8 0.8 0.8]);
    else
        plot(ax,xFinal,0,'o','Color',[0.8 0.8 0.8],'MarkerFaceColor',[0.8 0.8 0.8],'MarkerSize',8);
    end
    if tooClose(xFinal,xL2,xMin,xMax)
        putLabel(xFinal, -safeLabelY(abs(yFinal),yHi), 'Final Image (Virtual)','top','center',[0.5 0.5 0.5]);
    else
        arrowLabel(xFinal, yFinal, 'Final Image (Virtual)', [0.5 0.5 0.5]);
    end
else
    if ~isFinalOffScale
        drawArrow(ax,xFinal,0,xFinal,yFinal,'g');
    else
        plot(ax,xFinal,0,'go','MarkerFaceColor','g','MarkerSize',8);
    end
    if tooClose(xFinal,xL2,xMin,xMax)
        putLabel(xFinal, -safeLabelY(abs(yFinal),yHi), 'Final Image','top','center',[0 0.5 0]);
    else
        arrowLabel(xFinal, yFinal, 'Final Image', [0 0.5 0]);
    end
end

xFar = xMax;

skipGreenP1 = abs(u - f1) < 1e-6;
yAtL1_green = NaN;
if ~skipGreenP1
    try
        yAtL1_green = yOnLineAtX(xObj,h, -f1,0, 0); catch; skipGreenP1=true; end
end

skipGreenP2 = isfield(out,'u2') && abs(out.u2 - f2) < 1e-6;
yAtL2_green2 = NaN;
if ~skipGreenP2
    try
        yAtL2_green2 = yOnLineAtX(xI1,yI1, xL2-f2,0, xL2); catch; skipGreenP2=true; 
    end
end


% ======== PHASE 1: Object → L1 → Image 1 ========

% Pink P1
try
    plotClipped(xObj,h, 0,h, yLo,yHi,'m','-',1.6);
    if isVirtualInt
        yFarP1 = yOnLineAtX(0,h, f1,0, xFar);
        plotClipped(0,h, xFar,yFarP1, yLo,yHi,'m','--',1.6);
        plotClipped(0,h, xI1,yI1,     yLo,yHi,'m',':',1.2);
    else
        plotClipped(0,h, xI1,yI1, yLo,yHi,'m','-',1.6);
    end
catch ME; warning('drawRayDiagram:pinkP1','%s',ME.message); 
end

% Cyan P1
try
    plotClipped(xObj,h, 0,0, yLo,yHi,'c','-',1.6);
    if isVirtualInt
        yFarC1 = yOnLineAtX(xObj,h, 0,0, xFar);
        plotClipped(0,0, xFar,yFarC1, yLo,yHi,'c','--',1.6);
        plotClipped(0,0, xI1,yI1,     yLo,yHi,'c',':',1.2);
    else
        plotClipped(0,0, xI1,yI1, yLo,yHi,'c','-',1.6);
    end
catch ME; warning('drawRayDiagram:cyanP1','%s',ME.message); 
end

% Green P1
try
    if ~skipGreenP1 && isfinite(yAtL1_green) && abs(yAtL1_green) <= yHi*3
        plotClipped(xObj,h, 0,yAtL1_green, yLo,yHi,[0 0.6 0],'-',1.6);
        if isVirtualInt
            plotClipped(0,yI1, xFar,yI1, yLo,yHi,[0 0.6 0],'--',1.6);
        else
            plotClipped(0,yI1, xI1,yI1, yLo,yHi,[0 0.6 0],'-',1.6);
        end
    end
catch ME; warning('drawRayDiagram:greenP1','%s',ME.message); 
end


% ======== PHASE 2 ========

if ~isVirtualInt
    try
        plotClipped(xI1,yI1, xL2,yI1, yLo,yHi,'m','-',1.6);
        drawAfterL2(yI1, 'm');
    catch ME; warning('drawRayDiagram:pinkP2','%s',ME.message);
    end

    % Cyan P2: through optical centre of L2
    try
        plotClipped(xI1,yI1, xL2,0, yLo,yHi,'c','-',1.6);
        drawAfterL2(0, 'c');
    catch ME; warning('drawRayDiagram:cyanP2','%s',ME.message); 
    end

    % Green P2: through front focal of L2, exits horizontal at yFinal
    try
        if ~skipGreenP2 && isfinite(yAtL2_green2) && abs(yAtL2_green2) <= yHi*3
            plotClipped(xI1,yI1, xL2,yAtL2_green2, yLo,yHi,[0 0.6 0],'-',1.6);
            if ~isVirtualFinal
                plotClipped(xL2,yFinal, xFar,yFinal, yLo,yHi,[0 0.6 0],'-',1.6);
            else
                plotClipped(xL2,yFinal, xFar,yFinal, yLo,yHi,[0 0.6 0],'--',1.6);
            end
        end
    catch ME; warning('drawRayDiagram:greenP2','%s',ME.message); 
    end

else
    yAtL2_pinkV  = yOnLineAtX(0,h, f1,0, xL2);        % pink from (0,h) toward (f1,0)
    yAtL2_cyanV  = yOnLineAtX(xObj,h, 0,0, xL2);      % cyan from (xObj,h) through (0,0)
    yAtL2_greenV = yI1;                                 % green exits L1 horizontal at yI1

    % Pink P2B
    try
        plotClipped(xI1,yI1, 0,h,          yLo,yHi,'m',':',1.2);   % dotted back to L1
        plotClipped(0,h, xL2,yAtL2_pinkV,  yLo,yHi,'m','-',1.6);   % solid L1→L2
        drawAfterL2(yAtL2_pinkV, 'm');
    catch ME; warning('drawRayDiagram:pinkP2B','%s',ME.message); 
    end

    % Cyan P2B
    try
        plotClipped(xI1,yI1, 0,0,          yLo,yHi,'c',':',1.2);
        plotClipped(0,0, xL2,yAtL2_cyanV,  yLo,yHi,'c','-',1.6);
        drawAfterL2(yAtL2_cyanV, 'c');
    catch ME; warning('drawRayDiagram:cyanP2B','%s',ME.message); 
    end

    % Green P2B: horizontal from (0,yI1)
    try
        if ~skipGreenP1 && isfinite(yAtL1_green) && abs(yAtL1_green) <= yHi*3
            plotClipped(xI1,yI1, 0,yI1,        yLo,yHi,[0 0.6 0],':',1.2);
            plotClipped(0,yI1, xL2,yAtL2_greenV, yLo,yHi,[0 0.6 0],'-',1.6);
            drawAfterL2(yAtL2_greenV, [0 0.6 0]);
        end
    catch ME; warning('drawRayDiagram:greenP2B','%s',ME.message); 
    end

end


% TITLE
if isVirtualFinal
    title(ax,'Ray Diagram (Virtual Final Image)');
elseif isVirtualObj2
    title(ax,'Ray Diagram (Virtual Object for Lens 2)');
elseif isVirtualInt
    title(ax,'Ray Diagram (Virtual Intermediate Image)');
else
    title(ax,'Ray Diagram (Principal Rays)');
end
xlabel(ax,'x (m)'); ylabel(ax,'y (m)');

if showParaxialWarning
    if u < 0.5
        warnTxt = sprintf('WARNING: Object very close (u=%.2f m) - Diagram approximate',u);
    else
        warnTxt = sprintf('WARNING: Large angles (%.1f deg) - Paraxial violated',angleDeg);
    end
    text(ax,mean([xMin xMax]),yHi*0.90,warnTxt, ...
        'HorizontalAlignment','center','FontSize',13,'FontWeight','bold', ...
        'Color',[0.8 0 0],'BackgroundColor',[1 1 0.8], ...
        'Clipping','on','EdgeColor',[0.8 0 0],'LineWidth',1.5,'Margin',3);
end

if isfield(out,'diagramWarning') && out.diagramWarning
    text(ax, mean([xMin xMax]), yHi*0.50, out.diagramWarnMsg, ...
        'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'FontSize',13,'Color',[0.5 0 0],'FontWeight','bold', ...
        'BackgroundColor',[1 0.95 0.8],'EdgeColor',[0.8 0.5 0], ...
        'Clipping','on','LineWidth',1.5,'Margin',8);
end

hold(ax,'off');
end