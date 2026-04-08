function licksByStimStrength(data)

    licks_hit = {};
    licks_miss = {};
    licks_cr = {};
    licks_fa = {};
    for i = 1:length(unique(data.stimulus_strength))
        licks_hit{i} = [];
        licks_miss{i} = [];
        licks_cr{i} = [];
        licks_fa{i} = [];
    end
    
    sessions = unique(data.session_id);

    for a = 1:length(sessions)
        sidtmp = filterTrials(data, 'session_id', num2str(sessions(a)));
        stim_strengths = unique(sidtmp.stimulus_strength);
        bins = -0.5:0.1:6.0;
        atmp = filterTrials(sidtmp, 'categorical_outcome', 'Hit');
        for i = 1:length(stim_strengths)
            stim = stim_strengths(i);
            otmp = filterTrials(atmp, 'stim_strength', stim);
            if ~isempty(otmp)
                s1 = [];
                for trial = 1:size(otmp,1)
                    temp_licks = otmp.lick_times{trial,1}-otmp.stimulus_time(trial);
                    if ~isempty(temp_licks)
                        lick_dif = diff(temp_licks);
                        licks = temp_licks(find(lick_dif>0.05)+1)+0.2;
                    else
                        licks = [];
                    end
                    s1 = [s1; histcounts(licks, bins)];
                end
                if length(stim_strengths) == 2 && i == 2
                    if size(s1,1) > 1
                        licks_hit{end} = [licks_hit{end}; nanmean(s1)];
                    else
                        licks_hit{end} = [licks_hit{end}; s1];
                    end
                else
                    if size(s1,1) > 1
                        licks_hit{i} = [licks_hit{i}; nanmean(s1)];
                    else
                        licks_hit{i} = [licks_hit{i}; s1];
                    end
                end
            end
        end
        atmp = filterTrials(sidtmp, 'categorical_outcome', 'Miss');
        for i = 1:length(stim_strengths)
            stim = stim_strengths(i);
            otmp = filterTrials(atmp, 'stim_strength', stim);
            if ~isempty(otmp)
                s1 = [];
                for trial = 1:size(otmp,1)
                    temp_licks = otmp.lick_times{trial,1}-otmp.stimulus_time(trial);
                    if ~isempty(temp_licks)
                        lick_dif = diff(temp_licks);
                        licks = temp_licks(find(lick_dif>0.05)+1)+0.2;
                    else
                        licks = [];
                    end 
                    s1 = [s1; histcounts(licks, bins)];
                end
                if length(stim_strengths) == 2 && i == 2
                    if size(s1,1) > 1
                        licks_miss{end} = [licks_miss{end}; nanmean(s1)];
                    else
                        licks_miss{end} = [licks_miss{end}; s1];
                    end
                else
                    if size(s1,1) > 1
                        licks_miss{i} = [licks_miss{i}; nanmean(s1)];
                    else
                        licks_miss{i} = [licks_miss{i}; s1];
                    end
                end
            end
        end
        otmp = filterTrials(sidtmp, 'categorical_outcome', 'CR');
        for trial = 1:size(otmp,1)
            temp_licks = otmp.lick_times{trial,1}-otmp.stimulus_time(trial);
            if ~isempty(temp_licks)
                lick_dif = diff(temp_licks);
                licks = temp_licks(find(lick_dif>0.05)+1)+0.2;
            else
                licks = [];
            end 
            s1 = [s1; histcounts(licks, bins)];
        end
        if size(s1,1) > 1
            licks_cr{1} = [licks_cr{1}; nanmean(s1)];
        else
            licks_cr{1} = [licks_cr{1}; s1];
        end
        otmp = filterTrials(sidtmp, 'categorical_outcome', 'FA');
        for trial = 1:size(otmp,1)
            temp_licks = otmp.lick_times{trial,1}-otmp.stimulus_time(trial);
            if ~isempty(temp_licks)
                lick_dif = diff(temp_licks);
                licks = temp_licks(find(lick_dif>0.05)+1)+0.2;
            else
                licks = [];
            end 
            s1 = [s1; histcounts(licks, bins)];
        end
        if size(s1,1) > 1
            licks_fa{1} = [licks_fa{1}; nanmean(s1)];
        else
            licks_fa{1} = [licks_fa{1}; s1];
        end
    end

    stim_strengths = unique(data.stimulus_strength);
    cols = distinguishable_colors(length(stim_strengths)+1);
    
    session_fig = figure();
    tl = tiledlayout(1,4);
    t = bins(2:end);
    axs(1) = nexttile;
    hold on
    for i = 2:length(stim_strengths)
        stim = stim_strengths(i);
        l = sprintf('%.1f PSI', stim*10);
        out = semshade(licks_hit{i} ./ (bins(2)-bins(1)), 0.3, cols(i,:), cols(i,:), ...
                t, 1, l);
    end
    xlim([bins(1),bins(end)])
    ylabel('Lick Frequency (Hz)', 'FontSize', 16)
    title('Hit', 'FontSize', 16)
    leg = legend();
    leg.Title.String = 'Stimulus Strength';
    axs(2) = nexttile;
    hold on
    for i = 2:length(stim_strengths)
        stim = stim_strengths(i);
        l = sprintf('%.1f PSI', stim*10);
        out = semshade(licks_miss{i} ./ (bins(2)-bins(1)), 0.3, cols(i,:), cols(i,:), ...
                t, 1, l);
    end
    xlim([bins(1),bins(end)])
    title('Miss', 'FontSize', 16)
    axs(3) = nexttile;
    hold on
        stim = stim_strengths(1);
        l = sprintf('%.1f PSI', stim*10);
        out = semshade(licks_cr{1} ./ (bins(2)-bins(1)), 0.3, cols(1,:), cols(1,:), ...
                t, 1, l);
    xlim([bins(1),bins(end)])
    ylabel('Lick Frequency (Hz)', 'FontSize', 16)
    title('Correct Rejection', 'FontSize', 16)
    axs(4) = nexttile;
    hold on
    stim = stim_strengths(1);
    l = sprintf('%.1f PSI', stim*10);
    out = semshade(licks_fa{1} ./ (bins(2)-bins(1)), 0.3, cols(1,:), cols(1,:), ...
            t, 1, l);
    xlim([bins(1),bins(end)])
    title('False Alarm', 'FontSize', 16)
    xlabel(tl, 'Time (s)', 'FontSize', 16)
    unifyYLimits(session_fig)
    leg = legend();
    leg.Title.String = 'Stimulus Strength';

    intensity = [];
    mat = [];
    for i = 2:length(licks_hit)
        intensity = [intensity; zeros(size(licks_hit{i},1),1)+i-stim_strengths(i)];
        mat = [mat; licks_hit{i}];
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
    fprintf('hit licks by stimulus strength:\n')
    ranova(rm)

    intensity = [];
    mat = [];
    for i = 2:length(licks_miss)
        intensity = [intensity; zeros(size(licks_miss{i},1),1)+i-stim_strengths(i)];
        mat = [mat; licks_miss{i}];
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
    fprintf('miss licks by stimulus strength:\n')
    ranova(rm)

    saveas(session_fig, 'Figures/fig1d_addition.fig')
    saveas(session_fig, 'Figures/fig1d_addition.svg')

end