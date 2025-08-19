function fig2a(data)
    session_id = data(end,:).session_id;
    tmp_data = data(strcmp(data.session_id, session_id),:);
    pupil = [];
    for i = 1:size(tmp_data,1)
        pupil = [pupil; tmp_data(i,:).pupil_area{1}];
    end
    trace_fig = figure();
    plot(pupil(:,1) ./ 60, pupil(:,2), 'k')
    xlabel('Time (min)', 'FontSize', 16)
    ylabel('Pupil Area (z-score)', 'FontSize', 16)

    pupil = [];
    for i = 1:size(data,1)
        pupil = [pupil; data(i,:).pupil_area{1}];
    end

    hist_fig = figure(); 
    histogram(pupil(:,2), 50, 'Normalization', 'pdf', 'Orientation', 'horizontal', 'FaceColor', [0.5,0.5,0.5])
    xlabel('Probability Density', 'FontSize', 16)
    ylabel('Pupil Area (z-score)', 'FontSize', 16)

    saveas(trace_fig, 'Figures/fig2a_example.fig')
    saveas(trace_fig, 'Figures/fig2a_example.svg')
    saveas(hist_fig, 'Figures/fig2a_histogram.fig')
    saveas(hist_fig, 'Figures/fig2a_histogram.svg')

end