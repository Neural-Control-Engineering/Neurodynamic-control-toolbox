function pupilFluctuations(data)
    vals = [];
    for i = 1:size(data,1)
        vals = [vals; data.pupil_area{i,1}(:,2)];
    end
    vals = vals(vals > -6 & vals < 6);
    fig = figure(); 
    histogram(vals, 120, 'FaceColor', 'k', 'EdgeColor', 'k', 'Normalization', 'probability')
    % set(gca, 'view', [90, -90])
    ylabel('Fraction of Observations', 'FontSize', 16)
    xlabel('Pupil Area (z-score)', 'FontSize', 16)
end