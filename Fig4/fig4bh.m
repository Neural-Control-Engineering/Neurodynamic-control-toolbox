function fig4bh(data, tbounds, alignTo, ver)

    s1_ne_hit = {};
    s1_ne_miss = {};
    s1_ne_cr = {};
    s1_ne_fa = {};
    mpfc_ne_hit = {};
    mpfc_ne_miss = {};
    mpfc_ne_cr = {};
    mpfc_ne_fa = {};
    for i = 1:length(unique(data.stimulus_strength))
        s1_ne_hit{i} = [];
        s1_ne_miss{i} = [];
        s1_ne_cr{i} = [];
        s1_ne_fa{i} = [];
        mpfc_ne_hit{i} = [];
        mpfc_ne_miss{i} = [];
        mpfc_ne_cr{i} = [];
        mpfc_ne_fa{i} = [];
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
                [mpfc, s1, t] = avg_photo_traces(otmp, tbounds, alignTo, ver);
                if length(stim_strengths) == 2 && i == 2
                    if size(s1,1) > 1
                        s1_ne_hit{end} = [s1_ne_hit{end}; nanmean(s1)];
                        mpfc_ne_hit{end} = [mpfc_ne_hit{end}; nanmean(mpfc)];
                    else
                        s1_ne_hit{end} = [s1_ne_hit{end}; s1];
                        mpfc_ne_hit{end} = [mpfc_ne_hit{end}; mpfc];
                    end
                else
                    if size(s1,1) > 1
                        s1_ne_hit{i} = [s1_ne_hit{i}; nanmean(s1)];
                        mpfc_ne_hit{i} = [mpfc_ne_hit{i}; nanmean(mpfc)];
                    else
                        s1_ne_hit{i} = [s1_ne_hit{i}; s1];
                        mpfc_ne_hit{i} = [mpfc_ne_hit{i}; mpfc];
                    end
                end
            end
        end
        atmp = filterTrials(sidtmp, 'categorical_outcome', 'Miss');
        for i = 1:length(stim_strengths)
            stim = stim_strengths(i);
            otmp = filterTrials(atmp, 'stim_strength', stim);
            if ~isempty(otmp)
                [mpfc, s1, t] = avg_photo_traces(otmp, tbounds, alignTo, ver);
                if length(stim_strengths) == 2 && i == 2
                    if size(s1,1) > 1
                        s1_ne_miss{end} = [s1_ne_miss{end}; nanmean(s1)];
                        mpfc_ne_miss{end} = [mpfc_ne_miss{end}; nanmean(mpfc)];
                    else
                        s1_ne_miss{end} = [s1_ne_miss{end}; s1];
                        mpfc_ne_miss{end} = [mpfc_ne_miss{end}; mpfc];
                    end
                else
                    if size(s1,1) > 1
                        s1_ne_miss{i} = [s1_ne_miss{i}; nanmean(s1)];
                        mpfc_ne_miss{i} = [mpfc_ne_miss{i}; nanmean(mpfc)];
                    else
                        s1_ne_miss{i} = [s1_ne_miss{i}; s1];
                        mpfc_ne_miss{i} = [mpfc_ne_miss{i}; mpfc];
                    end
                end
            end
        end
        otmp = filterTrials(sidtmp, 'categorical_outcome', 'CR');
        if ~isempty(otmp)
            [mpfc, s1, t] = avg_photo_traces(otmp, tbounds, alignTo, ver);
            if size(s1,1) > 1
                s1_ne_cr{1} = [s1_ne_cr{1}; nanmean(s1)];
                mpfc_ne_cr{1} = [mpfc_ne_cr{1}; nanmean(mpfc)];
            else
                s1_ne_cr{1} = [s1_ne_cr{1}; s1];
                mpfc_ne_cr{1} = [mpfc_ne_cr{1}; mpfc];
            end
        end
        otmp = filterTrials(sidtmp, 'categorical_outcome', 'FA');
        if ~isempty(otmp)
            [mpfc, s1, t] = avg_photo_traces(otmp, tbounds, alignTo, ver);
            if size(s1,1) > 1
                s1_ne_fa{1} = [s1_ne_fa{1}; nanmean(s1)];
                mpfc_ne_fa{1} = [mpfc_ne_fa{1}; nanmean(mpfc)];
            else
                s1_ne_fa{1} = [s1_ne_fa{1}; s1];
                mpfc_ne_fa{1} = [mpfc_ne_fa{1}; mpfc];
            end
        end
    end

    stim_strengths = unique(data.stimulus_strength);
    cols = distinguishable_colors(length(stim_strengths)+1);
    
    s1_fig = figure();
    tl = tiledlayout(1,4);
    axs(1) = nexttile;
    hold on
    for i = 2:length(stim_strengths)
        stim = stim_strengths(i);
        l = sprintf('%.1f PSI', stim*10);
        out = semshade(s1_ne_hit{i}, 0.3, cols(i,:), cols(i,:), ...
                t, 10, l);
    end
    xlim(tbounds)
    title('Hit', 'FontSize', 16)
    legend()
    axs(2) = nexttile;
    hold on
    for i = 2:length(stim_strengths)
        stim = stim_strengths(i);
        l = sprintf('%.1f PSI', stim*10);
        out = semshade(s1_ne_miss{i}, 0.3, cols(i,:), cols(i,:), ...
                t, 10, l);
    end
    xlim(tbounds)
    title('Miss', 'FontSize', 16)
    axs(3) = nexttile;
    hold on
    stim = stim_strengths(1);
    l = sprintf('%.1f PSI', stim*10);
    out = semshade(s1_ne_cr{1}, 0.3, cols(1,:), cols(1,:), ...
            t, 10, l);
    title('Correct Rejection', 'FontSize', 16)
    xlim(tbounds)
    axs(4) = nexttile;
    hold on
    stim = stim_strengths(1);
    l = sprintf('%.1f PSI', stim*10);
    out = semshade(s1_ne_fa{1}, 0.3, cols(1,:), cols(1,:), ...
            t, 10, l);
    xlim(tbounds)
    title('False Alarm', 'FontSize', 16)
    xlabel(tl, 'Time (s)', 'FontSize', 16)
    ylabel(tl, 'NE in S1 (z-score)', 'FontSize', 16)
    unifyYLimits(s1_fig)
    leg = legend();
    leg.Title.String = 'Stimulus Strength';

    mpfc_fig = figure();
    tl = tiledlayout(1,4);
    axs(1) = nexttile;
    hold on
    for i = 2:length(stim_strengths)
        stim = stim_strengths(i);
        l = sprintf('%.1f PSI', stim*10);
        out = semshade(mpfc_ne_hit{i}, 0.3, cols(i,:), cols(i,:), ...
                t, 10, l);
    end
    xlim(tbounds)
    title('Hit', 'FontSize', 16)
    legend()
    axs(2) = nexttile;
    hold on
    for i = 2:length(stim_strengths)
        stim = stim_strengths(i);
        l = sprintf('%.1f PSI', stim*10);
        out = semshade(mpfc_ne_miss{i}, 0.3, cols(i,:), cols(i,:), ...
                t, 10, l);
    end
    xlim(tbounds)
    title('Miss', 'FontSize', 16)
    axs(3) = nexttile;
    hold on
    stim = stim_strengths(1);
    l = sprintf('%.1f PSI', stim*10);
    out = semshade(mpfc_ne_cr{1}, 0.3, cols(1,:), cols(1,:), ...
            t, 10, l);
    title('Correct Rejection', 'FontSize', 16)
    xlim(tbounds)
    axs(4) = nexttile;
    hold on
    stim = stim_strengths(1);
    l = sprintf('%.1f PSI', stim*10);
    out = semshade(mpfc_ne_fa{1}, 0.3, cols(1,:), cols(1,:), ...
            t, 10, l);
    xlim(tbounds)
    title('False Alarm', 'FontSize', 16)
    xlabel(tl, 'Time (s)', 'FontSize', 16)
    ylabel(tl, 'NE in mPFC (z-score)', 'FontSize', 16)
    unifyYLimits(mpfc_fig)
    leg = legend();
    leg.Title.String = 'Stimulus Strength';

    intensity = [];
    mat = [];
    for i = 2:length(s1_ne_hit)
        intensity = [intensity; zeros(size(s1_ne_hit{i},1),1)+i-stim_strengths(i)];
        mat = [mat; s1_ne_hit{i}];
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
    fprintf('hit s1_ne_ by stimulus strength:\n')
    ranova(rm)

    intensity = [];
    mat = [];
    for i = 2:length(s1_ne_miss)
        intensity = [intensity; zeros(size(s1_ne_miss{i},1),1)+i-stim_strengths(i)];
        mat = [mat; s1_ne_miss{i}];
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
    fprintf('miss s1_ne_ by stimulus strength:\n')
    ranova(rm)

    intensity = [];
    mat = [];
    for i = 2:length(mpfc_ne_hit)
        intensity = [intensity; zeros(size(mpfc_ne_hit{i},1),1)+i-stim_strengths(i)];
        mat = [mat; mpfc_ne_hit{i}];
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
    fprintf('hit mpfc_ne_ by stimulus strength:\n')
    ranova(rm)

    intensity = [];
    mat = [];
    for i = 2:length(mpfc_ne_miss)
        intensity = [intensity; zeros(size(mpfc_ne_miss{i},1),1)+i-stim_strengths(i)];
        mat = [mat; mpfc_ne_miss{i}];
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
    fprintf('miss mpfc_ne_ by stimulus strength:\n')
    ranova(rm)

    saveas(s1_fig, 'Figures/figb.fig')
    saveas(s1_fig, 'Figures/figb.svg')
    saveas(mpfc_fig, 'Figures/figh.fig')
    saveas(mpfc_fig, 'Figures/figh.svg')
end