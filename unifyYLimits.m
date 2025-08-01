function unifyYLimits(input)
    % UNIFYYLIMITS Set the same y-limits for all axes in a figure or a set of axes.
    %
    % Input:
    %   input - Handle to a figure or a matrix of axes handles.

    % Determine if input is a figure or a matrix of axes
    if isgraphics(input, 'figure')
        % If it's a figure, find all axes within the figure
        axHandles = findall(input, 'type', 'axes');
    elseif all(isgraphics(input, 'axes'))
        % If it's a matrix of axes handles, use them directly
        axHandles = input;
    else
        error('Input must be a figure handle or a matrix of axes handles.');
    end
    
    % Initialize variables to store global min and max y-limits
    yMin = inf;
    yMax = -inf;
    
    % Loop through each axis to find the overall min and max y-limits
    for i = 1:length(axHandles)
        yLimits = get(axHandles(i), 'YLim');
        yMin = min(yMin, yLimits(1));
        yMax = max(yMax, yLimits(2));
    end
    
    % Set the unified y-limits for all axes
    for i = 1:length(axHandles)
        set(axHandles(i), 'YLim', [yMin yMax]);
    end
end
