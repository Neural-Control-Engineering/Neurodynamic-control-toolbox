function licksByBaselinePupil(data)
    ptiles = [20,40,60,80,100];
    bins = -0.5:0.1:6.0;
    low = prctile(data.pupil_base_before_stimulus, 0);
    stim_strengths = unique(data.stimulus_strength);
    cols = distinguishable_colors(length(ptiles));
    licks_hit = {};
    licks_miss = {};
    fig = figure();
    tl = tiledlayout(1,2);
    for i = 1:2
        ax(i) = nexttile; hold on;
    end
    for i = 1:length(ptiles)
        ptile = ptiles(i);
        high = prctile(data.pupil_base_before_stimulus, ptile);
        x = data.pupil_base_before_stimulus >= low & data.pupil_base_before_stimulus <= high;
        low = high;
        tmp = data(x,:);
        sessions = unique(tmp.session_id);
        licks_hit{i} = [];
        licks_miss{i} = [];
        for s = 1:length(sessions)
            stmp = filterTrials(tmp, 'session_id', num2str(sessions(s)));
            htmp = filterTrials(stmp, 'categorical_outcome', 'Hit');
            mtmp = filterTrials(stmp, 'categorical_outcome', 'Miss');
            s1 = [];
            for trial = 1:size(htmp,1)
                temp_licks = htmp.lick_times{trial,1}-htmp.stimulus_time(trial);
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
            s1 = [];
            for trial = 1:size(mtmp,1)
                temp_licks = mtmp.lick_times{trial,1}-mtmp.stimulus_time(trial);
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
        l = sprintf('%ith quintile', i);
        axes(ax(1)); hold on;
        t = bins(2:end);
        out = semshade(licks_hit{i} ./ (bins(2)-bins(1)), 0.3, cols(i,:), cols(i,:), ...
                t, 1, l);
        title('Hit', 'FontSize', 16)
        axes(ax(2)); hold on;
        out = semshade(licks_miss{i} ./ (bins(2)-bins(1)), 0.3, cols(i,:), cols(i,:), ...
                t, 1, l);
        title('Miss', 'FontSize', 16)
    end
    unifyYLimits(fig)
    lims = ylim;
    for i = 1:2
        axes(ax(i)); xlim([-0.5,6]); ylim([0,lims(2)]);
    end
    xlabel(tl, 'Time (s)', 'FontSize', 16)
    ylabel(tl, 'Lick Frequency (Hz)', 'FontSize', 16)
    saveas(fig, 'Figures/licksByBaseline.fig')
    saveas(fig, 'Figures/licksByBaseline.svg')

    lk_hit = [];
    lk_miss = [];
    licks_quintile_hit = [];
    licks_quintile_miss = [];
    for i = 1:length(licks_hit)
        lk_hit = [lk_hit; licks_hit{i}];
        lk_miss = [lk_miss; licks_miss{i}];
        licks_quintile_hit = [licks_quintile_hit; zeros(size(licks_hit{i},1),1)+i-1];
        licks_quintile_miss = [licks_quintile_miss; zeros(size(licks_miss{i},1),1)+i-1];
    end
    lk_hit = lk_hit(:, t>0 & t<6);
    time = t(t>0 & t<6);
    tbl = table(licks_quintile_hit, lk_hit(:,1), 'VariableNames', {'quintile', 't0'});
    for c = 2:size(lk_hit,2)
        tbl = [tbl, table(lk_hit(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ quintile',c-1), 'WithinDesign', time);
    fprintf('Licks Hit:\n')
    ranova(rm)

    lk_miss = lk_miss(:, t>0 & t<6);
    time = t(t>0 & t<6);
    tbl = table(licks_quintile_miss, lk_miss(:,1), 'VariableNames', {'quintile', 't0'});
    for c = 2:size(lk_miss,2)
        tbl = [tbl, table(lk_miss(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ quintile',c-1), 'WithinDesign', time);
    fprintf('Licks Miss:\n')
    ranova(rm)

end