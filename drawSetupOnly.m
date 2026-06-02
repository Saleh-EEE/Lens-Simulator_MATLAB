function drawSetupOnly(ax, u, h, f1, f2, d, mode, customTitle, out)

if nargin < 8 || isempty(customTitle)
    customTitle = 'Setup';
end
hasDiagWarn = nargin >= 9 && isstruct(out) && ...
    isfield(out,'diagramWarning') && out.diagramWarning;


% CASE 1: u2=0 — blank diagram
if mode==2 && contains(lower(customTitle),'u2')
    cla(ax);
    hold(ax,'on');
    xlim(ax,[0 1]); ylim(ax,[0 1]);
    text(ax, 0.5, 0.60, 'Ray Diagram Unavailable', ...
        'Units','normalized','HorizontalAlignment','center', ...
        'FontSize',15,'FontWeight','bold','Color','r');
    text(ax, 0.5, 0.42, ...
        {'Intermediate image falls exactly on Lens 2', ...
         'u_2 = 0: thin-lens equation undefined', ...
         'Adjust u, f_1, f_2, or d slightly'}, ...
        'Units','normalized','HorizontalAlignment','center', ...
        'FontSize',13,'Color',[0.5 0 0]);
    title(ax,'Ray Diagram (Degenerate: u_2 = 0)');
    xlabel(ax,'x (m)'); ylabel(ax,'y (m)');
    hold(ax,'off');
    return;
end


% AXIS LIMITS
xObj = -u;
xMin = min([xObj - 0.5*max(1,abs(u)), -10]);
xMax = max([10, 1.2*max(1,abs(u))]);
if mode==2
    xMax = max(xMax, d + 1.5*max(1,abs(d)) + 5);
end


% COMPUTE ySpan — pre-calculate ray heights for correct scaling
ySpan = max(2, abs(h));

% CASE 1: u = f1 — image at infinity for lens 1
if contains(lower(customTitle),'lens 1')
    slope_exit  = -h / f1;
    yAtFar_pink = h + slope_exit * xMax;
    yAtFar_cyan = slope_exit * xMax;
    ySpan = max(ySpan, max(abs([yAtFar_pink, yAtFar_cyan])) * 1.2);
end

% CASE 2: u2 = f2 — image at infinity for lens 2
% Pre-compute all ray heights for correct ySpan
yAtL2_pink = 0; yAtL2_cyan = 0; yAtL2_green = 0;%#ok<NASGU>
yAtFar_pink2 = 0; yAtFar_cyan2 = 0; yAtFar_green2 = 0;%#ok<NASGU>
v1_loc = NaN; h1_loc = NaN; exitSlope = 0;

if mode==2 && contains(lower(customTitle),'lens 2')
    xL2    = d;
    xFar   = xMax;

    % Intermediate image from lens 1
    v1_loc = 1/(1/f1 - 1/u);
    m1_loc = -v1_loc / u;
    h1_loc = m1_loc * h;

    % Exit slope from L2: all parallel with slope = -h1/f2
    exitSlope = -h1_loc / f2;

    % Ray 1 (PINK): horizontal incident on L1, refracts through (f1,0)
    slopeAfterL1_pink = -h / f1;
    yAtL2_pink        = h + slopeAfterL1_pink * xL2;
    yAtFar_pink2      = yAtL2_pink + exitSlope * (xFar - xL2);

    % Ray 2 (CYAN): through center of L1, undeviated
    slopeCyan  = h / (0 - xObj);      % = h/u
    yAtL2_cyan = slopeCyan * xL2;
    yAtFar_cyan2 = yAtL2_cyan + exitSlope * (xFar - xL2);

    % Ray 3 (GREEN): aimed at front focal point of L1 (-f1), exits parallel
    xFront        = -f1;
    slopeToFront  = (0 - h) / (xFront - xObj);   % slope from object to -f1
    yAtL1_green   = h + slopeToFront * (0 - xObj);  % height at L1
    yAtL2_green   = yAtL1_green;   % exits L1 horizontal
    yAtFar_green2 = yAtL2_green + exitSlope * (xFar - xL2);

    allY = [h, h1_loc, yAtL2_pink, yAtFar_pink2, ...
            yAtL2_cyan, yAtFar_cyan2, ...
            yAtL1_green, yAtFar_green2];
    ySpan = max(ySpan, max(abs(allY(isfinite(allY)))) * 1.2);
end

tickSz = 0.05 * ySpan;


% DRAW EVERYTHING ONCE
cla(ax);
hold(ax,'on');
grid(ax,'on');

% Optical axis
plot(ax,[xMin xMax],[0 0],'k-','LineWidth',1);

% Object arrow
drawArrow(ax, xObj, 0, xObj, h, 'k');
text(ax, xObj, h, 'Object', ...
    'VerticalAlignment','bottom','HorizontalAlignment','center', ...
    'FontSize',13,'Clipping','on','BackgroundColor',[1 1 1]);

% Lens 1
plot(ax,[0 0],[-ySpan ySpan],'b-','LineWidth',2);
text(ax, 0, ySpan, 'Lens 1', 'Color','b','FontSize',13, ...
    'VerticalAlignment','bottom','HorizontalAlignment','left','Clipping','on');
plot(ax,[ f1  f1],[-tickSz tickSz],'b-','LineWidth',2);
plot(ax,[-f1 -f1],[-tickSz tickSz],'b-','LineWidth',2);
if f1 ~= 0
    if f1 >= xMin && f1 <= xMax
        text(ax, f1, -tickSz*3, 'f_1', ...
            'HorizontalAlignment','center','VerticalAlignment','top', ...
            'FontSize',15,'Color','b','FontWeight','bold','Clipping','on', ...
            'BackgroundColor',[1 1 1]);
    end
    if -f1 >= xMin && -f1 <= xMax
        text(ax, -f1, -tickSz*3, 'f_1', ...
            'HorizontalAlignment','center','VerticalAlignment','top', ...
            'FontSize',15,'Color','b','FontWeight','bold','Clipping','on', ...
            'BackgroundColor',[1 1 1]);
    end
end

% Lens 2
if mode==2
    plot(ax,[d d],[-ySpan ySpan],'r-','LineWidth',2);
    text(ax, d, ySpan, 'Lens 2', 'Color','r','FontSize',13, ...
        'VerticalAlignment','bottom','HorizontalAlignment','left','Clipping','on');
    plot(ax,[d+f2 d+f2],[-tickSz tickSz],'r-','LineWidth',2);
    plot(ax,[d-f2 d-f2],[-tickSz tickSz],'r-','LineWidth',2);
    if f2 ~= 0
        if d+f2 >= xMin && d+f2 <= xMax
            text(ax, d+f2, -tickSz*3, 'f_2', ...
                'HorizontalAlignment','center','VerticalAlignment','top', ...
                'FontSize',15,'Color','r','FontWeight','bold','Clipping','on', ...
                'BackgroundColor',[1 1 1]);
        end
        if d-f2 >= xMin && d-f2 <= xMax
            text(ax, d-f2, -tickSz*3, 'f_2', ...
                'HorizontalAlignment','center','VerticalAlignment','top', ...
                'FontSize',15,'Color','r','FontWeight','bold','Clipping','on', ...
                'BackgroundColor',[1 1 1]);
        end
    end
end


% CASE 1: Lens 1 infinity — 2 parallel exit rays
if contains(lower(customTitle),'lens 1')
    slope_exit  = -h / f1;
    xFar = xMax;
    yAtFar_pink = h + slope_exit * xFar;
    yAtFar_cyan = slope_exit * xFar;

    plot(ax,[xObj 0],[h h],'m-','LineWidth',1.6);
    plot(ax,[0 xFar],[h yAtFar_pink],'m--','LineWidth',1.6);
    plot(ax,[xObj 0],[h 0],'c-','LineWidth',1.6);
    plot(ax,[0 xFar],[0 yAtFar_cyan],'c--','LineWidth',1.6);

    text(ax, xMin + 0.6*(xMax-xMin), ySpan*0.75, ...
        sprintf('All exit rays parallel\n(slope = -h/f_1 = %.3g)', slope_exit), ...
        'HorizontalAlignment','center','FontSize',11, ...
        'Color',[0.3 0.3 0.3],'BackgroundColor',[1 1 1], ...
        'EdgeColor',[0.8 0.8 0.8],'Clipping','on');
end


% CASE 2: Lens 2 infinity — correct 3-ray diagram
if mode==2 && contains(lower(customTitle),'lens 2')
    xL2  = d;
    xI1  = v1_loc;
    xFar = xMax;

    % --- Phase 1: Object → L1 → Image 1 ---

    % Ray 1 (PINK): horizontal to L1, refracts through (f1,0) to Image 1
    slopeAfterL1_pink = -h / f1;%#ok<NASGU>
    plot(ax,[xObj 0],[h h],'m-','LineWidth',1.6);
    plot(ax,[0 xI1],[h h1_loc],'m-','LineWidth',1.6);

    % Ray 2 (CYAN): through center of L1 undeviated to Image 1
    plot(ax,[xObj 0],[h 0],'c-','LineWidth',1.6);
    plot(ax,[0 xI1],[0 h1_loc],'c-','LineWidth',1.6);

    % Ray 3 (GREEN): aimed at front focal (-f1), exits L1 horizontal
    xFront       = -f1;
    slopeToFront = (0 - h) / (xFront - xObj);
    yAtL1_green  = h + slopeToFront * (0 - xObj);
    plot(ax,[xObj 0],[h yAtL1_green],'-','Color',[0 0.6 0],'LineWidth',1.6);
    plot(ax,[0 xI1],[yAtL1_green h1_loc],'-','Color',[0 0.6 0],'LineWidth',1.6);

    % Intermediate image arrow
    drawArrow(ax, xI1, 0, xI1, h1_loc, [0 0.6 0]);
    yOff = 0.10 * ySpan;
    if h1_loc < 0
        text(ax, xI1, h1_loc - yOff, 'Image 1', ...
            'HorizontalAlignment','center','VerticalAlignment','top', ...
            'FontSize',12,'Color',[0 0.5 0],'BackgroundColor',[1 1 1],'Clipping','on');
    else
        text(ax, xI1, h1_loc + yOff, 'Image 1', ...
            'HorizontalAlignment','center','VerticalAlignment','bottom', ...
            'FontSize',12,'Color',[0 0.5 0],'BackgroundColor',[1 1 1],'Clipping','on');
    end

    % --- Phase 2: Image 1 → L2 → parallel exit rays ---
    % All exit rays have slope = -h1/f2

    % Ray 1 (PINK): Image 1 → L2 → exits parallel
    plot(ax,[xI1 xL2],[h1_loc h1_loc],'m-','LineWidth',1.6);
    plot(ax,[xL2 xFar],[h1_loc h1_loc + exitSlope*(xFar-xL2)],'m--','LineWidth',1.6);

    % Ray 2 (CYAN): Image 1 → L2 → exits parallel
    plot(ax,[xI1 xL2],[h1_loc 0],'c-','LineWidth',1.6);
    yFar_cyan = yOnLineAtX(xI1,h1_loc, xL2,0, xFar);
    plot(ax,[xL2 xFar],[0 yFar_cyan],'c--','LineWidth',1.6);

    % Label showing parallel exit
    text(ax, xL2 + 0.3*(xFar-xL2), ySpan*0.75, ...
        sprintf('All exit rays parallel\n(slope = -h_1/f_2 = %.3g)', exitSlope), ...
        'HorizontalAlignment','center','FontSize',11, ...
        'Color',[0.3 0.3 0.3],'BackgroundColor',[1 1 1], ...
        'EdgeColor',[0.8 0.8 0.8],'Clipping','on');
end


title(ax, customTitle);
xlabel(ax,'x (m)');
ylabel(ax,'y (m)');
xlim(ax,[xMin xMax]);
ylim(ax,[-1.2*ySpan 1.2*ySpan]);

if hasDiagWarn
    text(ax, mean([xMin xMax]), ySpan*0.50, out.diagramWarnMsg, ...
        'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'FontSize',13,'Color',[0.5 0 0],'FontWeight','bold', ...
        'BackgroundColor',[1 0.95 0.8],'EdgeColor',[0.8 0.5 0], ...
        'Clipping','on','LineWidth',1.5,'Margin',8);
end

hold(ax,'off');

end
% =========================
% Helper function 
% =========================
function yt = yOnLineAtX(x1,y1,x2,y2,xt)
    if abs(x2-x1) < 1e-12
        yt = y2;
    else
        t = (xt-x1)/(x2-x1);
        yt = y1 + t*(y2-y1);
    end
end