function licksByStimStrength(data, tbounds, alignTo, ver)

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
        atmp = filterTrials(sidtmp, 'categorical_outcome', 'Hit');
        for i = 1:length(stim_strengths)
            stim = stim_strengths(i);
            otmp = filterTrials(atmp, 'stim_strength', stim);
            if ~isempty(otmp)
                keyboard
                [mpfc, s1, t] = avg_photo_traces(otmp, tbounds, alignTo, ver);
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
                [mpfc, s1, t] = avg_photo_traces(otmp, tbounds, alignTo, ver);
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
    tl = tiledlayout(2,2);
    axs(1) = nexttile;
    hold on
    for i = 2:length(stim_strengths)
        stim = stim_strengths(i);
        l = sprintf('%.1f PSI', stim*10);
        out = semshade(s1_ne_hit{i}, 0.3, cols(i,:), cols(i,:), ...
                t, 1, l);
    end
    xlim(tbounds)
    ylabel('NE in S1 (z-score')
    title('Hit')
    axs(2) = nexttile;
    hold on
    for i = 2:length(stim_strengths)
        stim = stim_strengths(i);
        l = sprintf('%.1f PSI', stim*10);
        out = semshade(s1_ne_miss{i}, 0.3, cols(i,:), cols(i,:), ...
                t, 1, l);
    end
    xlim(tbounds)
    title('Miss')
    axs(3) = nexttile;
    hold on
    for i = 2:length(stim_strengths)
        stim = stim_strengths(i);
        l = sprintf('%.1f PSI', stim*10);
        out = semshade(mpfc_ne_hit{i}, 0.3, cols(i,:), cols(i,:), ...
                t, 1, l);
    end
    xlim(tbounds)
    ylabel('NE in mPFC (z-score')
    axs(4) = nexttile;
    hold on
    for i = 2:length(stim_strengths)
        stim = stim_strengths(i);
        l = sprintf('%.1f PSI', stim*10);
        out = semshade(mpfc_ne_miss{i}, 0.3, cols(i,:), cols(i,:), ...
                t, 1, l);
    end
    xlim(tbounds)
    xlabel(tl, 'Time (s)', 'FontSize', 16)
    unifyYLimits(session_fig)
    leg = legend();
    leg.Title.String = 'Stimulus Strength';
    keyboard 
    % saveas(session_fig, 'Figures/fig4a.fig')
    % saveas(session_fig, 'Figures/fig4a.svg')
end