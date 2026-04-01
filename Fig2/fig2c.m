function fig2c(data, tbounds, alignTo)

    pupil_ne_hit = {};
    pupil_ne_miss = {};
    pupil_ne_cr = {};
    pupil_ne_fa = {};
    for i = 1:length(unique(data.stimulus_strength))
        pupil_ne_hit{i} = [];
        pupil_ne_miss{i} = [];
        pupil_ne_cr{i} = [];
        pupil_ne_fa{i} = [];
    end
    
    sessions = unique(data.session_id);

    for a = 1:length(sessions)
        sidtmp = filterTrials(data, 'session_id', num2str(sessions(a)));
        stim_strengths = unique(sidtmp.stimulus_strength);
        atmp = filterTrials(sidtmp, 'categorical_outcome', 'Hit');
        for i = 1:length(stim_strengths)
            stim = stim_strengths(i);
            otmp = filterTrials(atmp, 'stim_strength', stim);
            if ~isempty(otmp)
                [s1, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
                if length(stim_strengths) == 2 && i == 2
                    if size(s1,1) > 1
                        pupil_ne_hit{end} = [pupil_ne_hit{end}; nanmean(s1)];
                    else
                        pupil_ne_hit{end} = [pupil_ne_hit{end}; s1];
                    end
                else
                    if size(s1,1) > 1
                        pupil_ne_hit{i} = [pupil_ne_hit{i}; nanmean(s1)];
                    else
                        pupil_ne_hit{i} = [pupil_ne_hit{i}; s1];
                    end
                end
            end
        end
        atmp = filterTrials(sidtmp, 'categorical_outcome', 'Miss');
        for i = 1:length(stim_strengths)
            stim = stim_strengths(i);
            otmp = filterTrials(atmp, 'stim_strength', stim);
            if ~isempty(otmp)
                [s1, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
                if length(stim_strengths) == 2 && i == 2
                    if size(s1,1) > 1
                        pupil_ne_miss{end} = [pupil_ne_miss{end}; nanmean(s1)];
                    else
                        pupil_ne_miss{end} = [pupil_ne_miss{end}; s1];
                    end
                else
                    if size(s1,1) > 1
                        pupil_ne_miss{i} = [pupil_ne_miss{i}; nanmean(s1)];
                    else
                        pupil_ne_miss{i} = [pupil_ne_miss{i}; s1];
                    end
                end
            end
        end
        otmp = filterTrials(sidtmp, 'categorical_outcome', 'CR');
        if ~isempty(otmp)
            [s1, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
            if size(s1,1) > 1
                pupil_ne_cr{1} = [pupil_ne_cr{1}; nanmean(s1)];
            else
                pupil_ne_cr{1} = [pupil_ne_cr{1}; s1];
            end
        end
        otmp = filterTrials(sidtmp, 'categorical_outcome', 'FA');
        if ~isempty(otmp)
            [s1, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
            if size(s1,1) > 1
                pupil_ne_fa{1} = [pupil_ne_fa{1}; nanmean(s1)];
            else
                pupil_ne_fa{1} = [pupil_ne_fa{1}; s1];
            end
        end
    end

    stim_strengths = unique(data.stimulus_strength);
    cols = distinguishable_colors(length(stim_strengths)+1);
    
    pupil_fig = figure();
    tl = tiledlayout(1,4);
    axs(1) = nexttile;
    hold on
    for i = 2:length(stim_strengths)
        stim = stim_strengths(i);
        l = sprintf('%.1f PSI', stim*10);
        out = semshade(pupil_ne_hit{i}, 0.3, cols(i,:), cols(i,:), ...
                t, 5, l);
    end
    xlim(tbounds)
    title('Hit', 'FontSize', 16)
    legend()
    axs(2) = nexttile;
    hold on
    for i = 2:length(stim_strengths)
        stim = stim_strengths(i);
        l = sprintf('%.1f PSI', stim*10);
        out = semshade(pupil_ne_miss{i}, 0.3, cols(i,:), cols(i,:), ...
                t, 5, l);
    end
    xlim(tbounds)
    title('Miss', 'FontSize', 16)
    axs(3) = nexttile;
    hold on
    stim = stim_strengths(1);
    l = sprintf('%.1f PSI', stim*10);
    out = semshade(pupil_ne_cr{1}, 0.3, cols(1,:), cols(1,:), ...
            t, 5, l);
    title('Correct Rejection', 'FontSize', 16)
    xlim(tbounds)
    axs(4) = nexttile;
    hold on
    stim = stim_strengths(1);
    l = sprintf('%.1f PSI', stim*10);
    out = semshade(pupil_ne_fa{1}, 0.3, cols(1,:), cols(1,:), ...
            t, 5, l);
    xlim(tbounds)
    title('False Alarm', 'FontSize', 16)
    xlabel(tl, 'Time (s)', 'FontSize', 16)
    ylabel(tl, 'Pupil Area (z-score)', 'FontSize', 16)
    unifyYLimits(pupil_fig)
    leg = legend();
    leg.Title.String = 'Stimulus Strength';

    intensity = [];
    mat = [];
    for i = 2:length(pupil_ne_hit)
        intensity = [intensity; zeros(size(pupil_ne_hit{i},1),1)+stim_strengths(i)];
        mat = [mat; pupil_ne_hit{i}];
    end
    % for r = 1:size(mat,1)
    %     mat(r,:) = smooth(mat(r,:),5);
    % end
    mat = mat(:, t>0 & t<=5);
    time =t(:, t>0 & t<=5);
    tbl = table(intensity, mat(:,1), 'VariableNames', {'intensity', 't0'});
    for c = 2:size(mat,2)
        tbl = [tbl, table(mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ intensity',c-1), 'WithinDesign', time);
    fprintf('hit pupil_ne_ by stimulus strength:\n')
    ranova(rm)

    intensity = [];
    mat = [];
    for i = 2:length(pupil_ne_miss)
        intensity = [intensity; zeros(size(pupil_ne_miss{i},1),1)+stim_strengths(i)];
        mat = [mat; pupil_ne_miss{i}];
    end
    % for r = 1:size(mat,1)
    %     mat(r,:) = smooth(mat(r,:),5);
    % end
    mat = mat(:, t>0 & t<=5);
    time =t(:, t>0 & t<=5);
    tbl = table(intensity, mat(:,1), 'VariableNames', {'intensity', 't0'});
    for c = 2:size(mat,2)
        tbl = [tbl, table(mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ intensity',c-1), 'WithinDesign', time);
    fprintf('miss pupil_ne_ by stimulus strength:\n')
    ranova(rm)

    keyboard 
    saveas(pupil_fig, 'Figures/figb.fig')
    saveas(pupil_fig, 'Figures/figb.svg')
end