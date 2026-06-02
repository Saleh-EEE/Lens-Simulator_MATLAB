function drawArrow(ax, x1, y1, x2, y2, colorVal)
    

    % Draw main stem
    plot(ax, [x1 x2], [y1 y2], '-', 'Color', colorVal, 'LineWidth', 2);

    % Calculate arrow dimensions
    h_arrow = abs(y2 - y1);

    % Don't draw head for zero-height arrows
    if h_arrow < 1e-6
        return; 
    end

    % Get axis limits with safety check
    try
        xl = xlim(ax);
        yl = ylim(ax);

        if any(~isfinite(xl)) || any(~isfinite(yl)) || ...
                xl(1) >= xl(2) || yl(1) >= yl(2)
            ah_y = h_arrow * 0.08;
            ah_x = ah_y * 0.5;
        else
            xRange = xl(2) - xl(1);
            yRange = yl(2) - yl(1);

            % Base: percentage of arrow height
            ah_y_from_arrow = 0.12 * h_arrow;

            % Cap by axis
            ah_y_max = 0.08 * yRange;
            ah_y     = min(ah_y_from_arrow, ah_y_max);

            % x: maintain aspect ratio
            aspect_ratio = xRange / yRange;
            ah_x = ah_y * aspect_ratio;
            ah_x = min(ah_x, 0.08 * xRange);

            % Head not wider than 3x its scaled height
            if ah_x > 3 * ah_y * aspect_ratio
                ah_x = 3 * ah_y * aspect_ratio;
            end

            % Minimum visible size always tied to axis ranges
            min_y = 0.015 * yRange;
            min_x = 0.010 * xRange;

            ah_y = max(ah_y, min_y);
            ah_x = max(ah_x, min_x);
        end
    catch
        ah_y = h_arrow * 0.08;
        ah_x = ah_y * 0.5;
    end

    % Direction
    s = sign(y2 - y1);
    if s == 0; s = 1; end

    % Draw arrow head
    plot(ax, [x2-ah_x, x2, x2+ah_x], [y2-s*ah_y, y2, y2-s*ah_y], ...
        '-', 'Color', colorVal, 'LineWidth', 2);
end