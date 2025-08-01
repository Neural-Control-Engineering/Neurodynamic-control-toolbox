function fig2b(data, tbounds, alignTo)
    if ~exist('alignTo', 'var')
        alignTo = 'stimulus';
    end
    pupil_animal = {[], [], [], [], [], [], []};
    pupil_session = pupil_animal;
    animals = fetchAnimals(data);
    sessions = unique(data.session_id);

    for a = 1:length(animals)
        atmp = filterTrials(data, 'animal', num2str(animals(a)));
        stim_strengths = unique(atmp.stimulus_strength);
        for i = 1:length(stim_strengths)
            stim = stim_strengths(i);
            otmp = filterTrials(atmp, 'stim_strength', stim);
            if ~isempty(otmp)
                [pupil, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
                if length(stim_strengths) == 7 || i == 1
                    if size(pupil,1) > 1
                        pupil_animal{i} = [pupil_animal{i}; nanmean(pupil(:,2:end-1))];
                    else
                        pupil_animal{i} = [pupil_animal{i}; pupil(2:end-1)];
                    end
                else
                    pupil_animal{end} = [pupil_animal{end}; nanmean(pupil(:,2:end-1))];
                end
            end
        end
    end

    for a = 1:length(sessions)
        atmp = filterTrials(data, 'session_id', num2str(sessions(a)));
        stim_strengths = unique(atmp.stimulus_strength);
        for i = 1:length(stim_strengths)
            stim = stim_strengths(i);
            otmp = filterTrials(atmp, 'stim_strength', stim);
            if ~isempty(otmp)
                [pupil, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
                if length(stim_strengths) == 7 || i == 1
                    if size(pupil,1) > 1
                        pupil_session{i} = [pupil_session{i}; nanmean(pupil(:,2:end-1))];
                    else
                        pupil_session{i} = [pupil_session{i}; pupil(2:end-1)];
                    end
                else
                    pupil_session{end} = [pupil_session{end}; nanmean(pupil(:,2:end-1))];
                end
            end
        end
    end

    stim_strenghts = unique(data.stimulus_strength);
    cols = distinguishable_colors(length(stim_strengths)+1);

    t = t(2:end-1);

    session_fig = figure();
    hold on
    for i = 1:length(stim_strengths)
        stim = stim_strengths(i);
        l = sprintf('%.1f PSI', stim*10);
        out = semshade(pupil_session{i}, 0.3, cols(i,:), cols(i,:), ...
                t, 1, l);
    end
    ylim([-0.3, 1.3])
    xlim(tbounds)
    leg = legend();
    leg.Title.String = 'Stimulus Strength';
    plot([0,0], [-0.3, 1.3], 'k:', 'HandleVisibility', 'off')
    ylabel('Pupil Area (z-score)', 'FontSize', 14)
    xlabel('Time (s)', 'FontSize', 14)
    leg = legend();
    leg.Title.String = 'Stimulus Strength';

    % animal_fig = figure();
    % hold on
    % for i = 1:length(stim_strengths)
    %     stim = stim_strengths(i);
    %     l = sprintf('%.1f PSI', stim*10);
    %     out = semshade(pupil_animal{i}, 0.3, cols(i,:), cols(i,:), ...
    %             t, 1, l);
    % end
    % ylim([-0.3, 1.3])
    % xlim(tbounds)
    % leg = legend();
    % leg.Title.String = 'Stimulus Strength';
    % plot([0,0], [-0.3, 1.3], 'k:', 'HandleVisibility', 'off')
    % ylabel('Pupil Area (z-score)', 'FontSize', 14)
    % xlabel('Time (s)', 'FontSize', 14)
    % leg = legend();
    % leg.Title.String = 'Stimulus Strength';
    % saveas(fig, 'Analysis/paper_figures/figure2/pupilByStimStrength.fig')
    % leg.Title.FontSize = 12;

    mat = zeros(length(pupil_session), 49);
    for i = 1:length(pupil_session)
        for j = 1:size(pupil_session{i},1)
            dilate = max(pupil_session{i}(j,6:end));
            baseline = mean(pupil_session{i}(j,1:5));
            mat(i,j) = dilate - baseline;
        end
    end

    p = anova1(mat')
end