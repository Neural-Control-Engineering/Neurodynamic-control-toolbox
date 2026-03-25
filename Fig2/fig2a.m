function fig2a(data)
    tmp = data(strcmp(data.session_id, data(end,:).session_id),:);
    pupil = [];
    time = [];
    for i = 1:size(tmp,1)
        pupil = [pupil; tmp(i,:).pupil_area{1}(:,2)];
        time = [time; tmp(i,:).pupil_area{1}(:,1)];
    end
    trace_fig = figure(); 
    plot((time(time>500 & time<1500)-500) ./ 60, smooth(pupil(time>500 & time<1500),20), 'k');
    xlabel('Time (min)', 'FontSize', 16)
    ylabel('Pupil Area (z-score)', 'FontSize', 16)
    xlim([0,16])

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