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
    end

    stim_strengths = unique(data.stimulus_strength);
    cols = distinguishable_colors(length(stim_strengths)+1);
    
    session_fig = figure();
    tl = tiledlayout(1,2);
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
    xlabel(tl, 'Time (s)', 'FontSize', 16)
    unifyYLimits(session_fig)
    leg = legend();
    leg.Title.String = 'Stimulus Strength';
    keyboard 
    % saveas(session_fig, 'Figures/fig4a.fig')
    % saveas(session_fig, 'Figures/fig4a.svg')
end