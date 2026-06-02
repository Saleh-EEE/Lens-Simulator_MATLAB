function plotPerformance(axPerf, uNow, h, f1, f2, d, mode)

    cla(axPerf);
    hold(axPerf,'on');
    grid(axPerf,'on');

    title(axPerf,'|Magnification| vs Object Distance','FontSize',15);
    xlabel(axPerf,'Object distance u (m)','FontSize',13);
    ylabel(axPerf,'|Magnification|','FontSize',13);


    % ADAPTIVE SWEEP RANGE
    uMin = max(0.1, 0.2*uNow);
    uMax = max(uMin+1, 2.5*uNow);

    if uNow < 1
        uMin = 0.1;
        uMax = max(5, uNow*10);
    end

    if uNow > 100
        uMin = max(1, uNow*0.5);
        uMax = uNow*1.5;
    end

    % Force f1 singularity into range for converging lens
    if f1 > 0
        uMin = min(uMin, f1*0.3);
        uMax = max(uMax, f1*3.0);
    end

    % Ensure uMin is always positive
    uMin = max(uMin, 0.1);

    N = 400;
    uVals = linspace(uMin, uMax, N);
    mVals = nan(size(uVals));
    warnCount = 0;


    % SWEEP — direct computation bypassing lensCalcSafe thresholds
    for i = 1:numel(uVals)
        try
            u_i = uVals(i);
            denom1 = 1/f1 - 1/u_i;
            if abs(denom1) < 1e-12
                mVals(i) = nan;
                continue;
            end
            v_i = 1/denom1;
            if mode == 1
                mVals(i) = abs(-v_i/u_i);
            else
                u2_i = d - v_i;
                if abs(u2_i) < 1e-9
                    mVals(i) = nan; continue;
                end
                denom2 = 1/f2 - 1/u2_i;
                if abs(denom2) < 1e-12
                    mVals(i) = nan; continue;
                end
                v2_i = 1/denom2;
                mVals(i) = abs((-v_i/u_i) * (-v2_i/u2_i));
            end
        catch
            mVals(i) = nan;
            warnCount = warnCount + 1;
        end
    end


    % ALL INVALID
    validPoints = sum(~isnan(mVals));

    if validPoints == 0
        text(axPerf, mean([uMin uMax]), 0.5, ...
            {'No valid magnification data', '', ...
             'All points in range resulted in', ...
             'infinity or degenerate cases'}, ...
            'HorizontalAlignment','center', ...
            'FontSize',15,'Color','r','FontWeight','bold');
        ylim(axPerf,[0,1]);
        xlim(axPerf,[uMin uMax]);
        hold(axPerf,'off');
        return;
    end


    % PLOT CURVE
    plot(axPerf, uVals, mVals, 'b-', 'LineWidth', 1.8);


    % ADAPTIVE Y LIMITS
    ymax = max(mVals,[],'omitnan');
    if isempty(ymax) || isnan(ymax); ymax = 1; end

    if ymax > 100
        sortedVals = sort(mVals(~isnan(mVals)));
        if ~isempty(sortedVals)
            idx90  = ceil(0.9*length(sortedVals));
            ymax = sortedVals(idx90);
        end
    end

    ylim(axPerf,[0, max(1, 1.1*ymax)]);
    xlim(axPerf,[uMin uMax]);


    % REFERENCE LINE |m| = 1
    if ymax >= 0.9
        yline(axPerf, 1, ':', 'Color',[0.5 0.5 0.5], 'LineWidth',1.5);
        text(axPerf, uMin+0.02*(uMax-uMin), 1, ' |m|=1', ...
            'VerticalAlignment','bottom','FontSize',13, ...
            'Color',[0.5 0.5 0.5],'FontWeight','bold');
    end


    % VERTICAL LINE AT u = f1
    if f1 > 0 && f1 >= uMin && f1 <= uMax
        xline(axPerf, f1, ':', 'Color',[0.8 0.2 0.2], 'LineWidth',2);
        yl = ylim(axPerf);
        text(axPerf, f1, yl(2)*0.95, 'u = f_1', ...
            'Rotation',90,'VerticalAlignment','top', ...
            'HorizontalAlignment','right','FontSize',15, ...
            'Color',[0.8 0.2 0.2],'FontWeight','bold');
    end

    if mode == 2
        denom = d - f2;
        if abs(denom) > 1e-9 && abs(1/f1 - 1/denom) > 1e-9
            u_s2 = 1/(1/f1 - 1/denom);
            if u_s2 > 0 && u_s2 >= uMin && u_s2 <= uMax && abs(u_s2-f1) > 0.01
                xline(axPerf, u_s2, '--', 'Color',[0.8 0.4 0.0], 'LineWidth',2);
                yl = ylim(axPerf);
                text(axPerf, u_s2, yl(2)*0.80, 'u_2 = f_2  ', ...
                    'Rotation',90,'VerticalAlignment','top', ...
                    'HorizontalAlignment','right','FontSize',11, ...
                    'Color',[0.8 0.4 0.0],'FontWeight','bold');
            end
        end
    end


    % VERTICAL LINE AT CURRENT u
    if uNow >= uMin && uNow <= uMax
        xline(axPerf, uNow, ':', 'Color',[0.2 0.6 0.2], 'LineWidth',2);
        yl = ylim(axPerf);
        if f1 > 0 && abs(uNow - f1) < 0.05*(uMax-uMin)
            yPos_u = yl(2)*0.72;
        else
            yPos_u = yl(2)*0.95;
        end
        text(axPerf, uNow, yPos_u, 'Current u  ', ...
            'Rotation',90,'VerticalAlignment','top', ...
            'HorizontalAlignment','right','FontSize',15, ...
            'Color',[0.2 0.6 0.2],'FontWeight','bold');
    end


    % MARK CURRENT MAGNIFICATION POINT
    try
        outNow = lensCalcSafe(uNow, h, f1, f2, d, mode);

        if ~outNow.hasInfinity && isfinite(outNow.m)
            mNow = abs(outNow.m);
            yl   = ylim(axPerf);

            if mNow <= yl(2)
                plot(axPerf, uNow, mNow, 'ro', ...
                    'MarkerFaceColor','r','MarkerSize',10);

                if mNow < yl(2)*0.5
                    vAlign = 'bottom';
                else
                    vAlign = 'top';
                end

                text(axPerf, uNow, mNow, ...
                    sprintf('  (%.3g, %.3g)', uNow, mNow), ...
                    'FontWeight','bold','VerticalAlignment',vAlign, ...
                    'FontSize',13,'BackgroundColor','white', ...
                    'EdgeColor','black','Margin',2);
            else
                text(axPerf, uNow, yl(2)*0.5, ...
                    sprintf('Current: %.3g\n(off scale)', mNow), ...
                    'HorizontalAlignment','center','FontSize',12, ...
                    'Color','r','BackgroundColor',[1 1 0.9], ...
                    'EdgeColor','r');
            end
        end
    catch
        yl = ylim(axPerf);
        text(axPerf, uNow, yl(2)*0.8, ...
            {'Current point','undefined'}, ...
            'HorizontalAlignment','center','FontSize',12, ...
            'Color','r','BackgroundColor',[1 0.9 0.9]);
    end


    yl = ylim(axPerf);
    noteY = yl(2) * 0.70;
    noteX = uMin + 0.02*(uMax-uMin);

    % Note: u >> f1 — flat near-zero region
    if f1 > 0 && uNow > 100*f1
        text(axPerf, noteX, noteY, ...
            sprintf('Note: u >> f_1 (u=%.3g, f_1=%.3g)\nMagnification \\approx 0 in this region', uNow, f1), ...
            'FontSize',11,'Color',[0.4 0.4 0.4], ...
            'VerticalAlignment','top', ...
            'BackgroundColor',[0.95 0.95 0.95], ...
            'EdgeColor',[0.7 0.7 0.7]);

    % Note: diverging lens — no singularity, always |m| < 1
    elseif f1 < 0
        text(axPerf, noteX, noteY, ...
            sprintf('Diverging lens (f_1 = %.3g m)\nNo singularity — |m| < 1 for all u', f1), ...
            'FontSize',11,'Color',[0.4 0.4 0.4], ...
            'VerticalAlignment','top', ...
            'BackgroundColor',[0.95 0.95 0.95], ...
            'EdgeColor',[0.7 0.7 0.7]);

    % Note: curve is essentially flat — variation < 5% of mean
    elseif validPoints > 10
        validM = mVals(~isnan(mVals));
        mMean  = mean(validM);
        mRange = max(validM) - min(validM);
        if mMean > 1e-9 && mRange / mMean < 0.05
            text(axPerf, noteX, noteY, ...
                sprintf('Curve is nearly flat (variation < 5%%).\nTry u closer to f_1 = %.3g m to see singularity.', f1), ...
                'FontSize',11,'Color',[0.4 0.4 0.4], ...
                'VerticalAlignment','top', ...
                'BackgroundColor',[0.95 0.95 0.95], ...
                'EdgeColor',[0.7 0.7 0.7]);
        end
    end

    % Note: current u is outside sweep range
    if uNow < uMin || uNow > uMax
        text(axPerf, mean([uMin uMax]), yl(2)*0.85, ...
            sprintf('Current u = %.3g m is outside plotted range.', uNow), ...
            'HorizontalAlignment','center','FontSize',11, ...
            'Color',[0.5 0 0], ...
            'BackgroundColor',[1 0.95 0.8], ...
            'EdgeColor',[0.8 0.5 0]);
    end

    hold(axPerf,'off');
end