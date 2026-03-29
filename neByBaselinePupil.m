function neByBaselinePupil(data, tbounds, alignTo, ver)
    ptiles = [20,40,60,80,100];
    low = prctile(data.pupil_base_before_stimulus, 0);
    stim_strengths = unique(data.stimulus_strength);
    cols = distinguishable_colors(length(ptiles));
    s1_rppa_hit = {};
    s1_rppa_miss = {};
    s1_rppa_fa = {};
    s1_rppa_cr = {};
    mpfc_rppa_hit = {};
    mpfc_rppa_miss = {};
    mpfc_rppa_fa = {};
    mpfc_rppa_cr = {};
    fas = {};
    s1_baseline = {};
    mpfc_baseline = {};
    fig = figure();
    tl = tiledlayout(2,4);
    for i = 1:8
        ax(i) = nexttile; hold on;
    end
    for i = 1:length(ptiles)
        ptile = ptiles(i);
        high = prctile(data.pupil_base_before_stimulus, ptile);
        x = data.pupil_base_before_stimulus >= low & data.pupil_base_before_stimulus <= high;
        low = high;
        tmp = data(x,:);
        sessions = unique(tmp.session_id);
        mpfc_rppa_hit{i} = [];
        s1_rppa_hit{i} = [];
        mpfc_rppa_miss{i} = [];
        s1_rppa_miss{i} = [];
        mpfc_rppa_cr{i} = [];
        s1_rppa_cr{i} = [];
        mpfc_rppa_fa{i} = [];
        s1_rppa_fa{i} = [];
        s1_baseline{i} = [];
        mpfc_baseline{i} = [];
        for s = 1:length(sessions)
            stmp = filterTrials(tmp, 'session_id', num2str(sessions(s)));
            [mpfc, s1, ~] = avg_photo_traces(stmp, [-0.5, 0], 'stimulus', ver);
            s1_baseline{i} = [s1_baseline{i}; nanmean(nanmean(s1,2))];
            mpfc_baseline{i} = [mpfc_baseline{i}; nanmean(nanmean(mpfc,2))];
            htmp = filterTrials(stmp, 'categorical_outcome', 'Hit');
            mtmp = filterTrials(stmp, 'categorical_outcome', 'Miss');
            ftmp = filterTrials(stmp, 'categorical_outcome', 'FA');
            ctmp = filterTrials(stmp, 'categorical_outcome', 'CR');
            [mpfc, s1, t] = avg_photo_traces(htmp, tbounds, alignTo, ver);
            if size(mpfc,1) > 1
                mpfc_rppa_hit{i} = [mpfc_rppa_hit{i}; nanmean(mpfc)];
                s1_rppa_hit{i} = [s1_rppa_hit{i}; nanmean(s1)];
            else
                mpfc_rppa_hit{i} = [mpfc_rppa_hit{i}; mpfc];
                s1_rppa_hit{i} = [s1_rppa_hit{i}; s1];
            end
            [mpfc, s1, t] = avg_photo_traces(mtmp, tbounds, alignTo, ver);
            if size(mpfc,1) > 1
                mpfc_rppa_miss{i} = [mpfc_rppa_miss{i}; nanmean(mpfc)];
                s1_rppa_miss{i} = [s1_rppa_miss{i}; nanmean(s1)];
            else
                mpfc_rppa_miss{i} = [mpfc_rppa_miss{i}; mpfc];
                s1_rppa_miss{i} = [s1_rppa_miss{i}; s1];
            end
            [mpfc, s1, t] = avg_photo_traces(ctmp, tbounds, alignTo, ver);
            if size(mpfc,1) > 1
                mpfc_rppa_cr{i} = [mpfc_rppa_cr{i}; nanmean(mpfc)];
                s1_rppa_cr{i} = [s1_rppa_cr{i}; nanmean(s1)];
            else
                mpfc_rppa_cr{i} = [mpfc_rppa_cr{i}; mpfc];
                s1_rppa_cr{i} = [s1_rppa_cr{i}; s1];
            end
            [mpfc, s1, t] = avg_photo_traces(ftmp, tbounds, alignTo, ver);
            if size(mpfc,1) > 1
                mpfc_rppa_fa{i} = [mpfc_rppa_fa{i}; nanmean(mpfc)];
                s1_rppa_fa{i} = [s1_rppa_fa{i}; nanmean(s1)];
            else
                mpfc_rppa_fa{i} = [mpfc_rppa_fa{i}; mpfc];
                s1_rppa_fa{i} = [s1_rppa_fa{i}; s1];
            end
        end
        l = sprintf('%ith quintile', i);
        axes(ax(1)); hold on;
        semshade(s1_rppa_hit{i}, 0.3, cols(i,:), cols(i,:), t, 1, sprintf('%s', l));
        title('Hit', 'FontSize', 16)
        ylabel('NE in S1 (z-score)', 'FontSize', 16)
        axes(ax(2)); hold on;
        semshade(s1_rppa_miss{i}, 0.3, cols(i,:), cols(i,:), t, 1, sprintf('%s', l));
        title('Miss', 'FontSize', 16)
        axes(ax(3)); hold on;
        semshade(s1_rppa_cr{i}, 0.3, cols(i,:), cols(i,:), t, 1, sprintf('%s', l));
        title('Correct Rejection', 'FontSize', 16)
        axes(ax(4)); hold on;
        semshade(s1_rppa_fa{i}, 0.3, cols(i,:), cols(i,:), t, 1, sprintf('%s', l));
        title('False Alarm', 'FontSize', 16)
        axes(ax(5)); hold on;
        semshade(mpfc_rppa_hit{i}, 0.3, cols(i,:), cols(i,:), t, 1, sprintf('%s', l));
        ylabel('NE in mPFC (z-score)', 'FontSize', 16)
        axes(ax(6)); hold on;
        semshade(mpfc_rppa_miss{i}, 0.3, cols(i,:), cols(i,:), t, 1, sprintf('%s', l));
        axes(ax(7)); hold on;
        semshade(mpfc_rppa_cr{i}, 0.3, cols(i,:), cols(i,:), t, 1, sprintf('%s', l));
        axes(ax(8)); hold on;
        semshade(mpfc_rppa_fa{i}, 0.3, cols(i,:), cols(i,:), t, 1, sprintf('%s', l));
    end
    for i = 1:8
        axes(ax(i)); xlim([-0.5,6])
    end
    unifyYLimits(fig)
    xlabel(tl, 'Time (s)', 'FontSize', 16)
    mpfc_hit = [];
    mpfc_miss = [];
    mpfc_fa = [];
    mpfc_cr = [];
    mpfc_quintile_hit = [];
    mpfc_quintile_miss = [];
    mpfc_quintile_fa = [];
    mpfc_quintile_cr = [];
    s1_hit = [];
    s1_miss = [];
    s1_fa = [];
    s1_cr = [];
    s1_quintile_hit = [];
    s1_quintile_miss = [];
    s1_quintile_fa = [];
    s1_quintile_cr = [];
    for i = 1:length(s1_rppa_hit)
        s1_hit = [s1_hit; s1_rppa_hit{i}];
        s1_miss = [s1_miss; s1_rppa_miss{i}];
        s1_fa = [s1_fa; s1_rppa_fa{i}];
        s1_cr = [s1_cr; s1_rppa_cr{i}];
        mpfc_hit = [mpfc_hit; mpfc_rppa_hit{i}];
        mpfc_miss = [mpfc_miss; mpfc_rppa_miss{i}];
        mpfc_fa = [mpfc_fa; mpfc_rppa_fa{i}];
        mpfc_cr = [mpfc_cr; mpfc_rppa_cr{i}];
        s1_quintile_hit = [s1_quintile_hit; zeros(size(s1_rppa_hit{i},1),1)+i-1];
        mpfc_quintile_hit = [mpfc_quintile_hit; zeros(size(mpfc_rppa_hit{i},1),1)+i-1];
        s1_quintile_miss = [s1_quintile_miss; zeros(size(s1_rppa_miss{i},1),1)+i-1];
        mpfc_quintile_miss = [mpfc_quintile_miss; zeros(size(mpfc_rppa_miss{i},1),1)+i-1];
        s1_quintile_cr = [s1_quintile_cr; zeros(size(s1_rppa_cr{i},1),1)+i-1];
        mpfc_quintile_cr = [mpfc_quintile_cr; zeros(size(mpfc_rppa_cr{i},1),1)+i-1];
        s1_quintile_fa = [s1_quintile_fa; zeros(size(s1_rppa_fa{i},1),1)+i-1];
        mpfc_quintile_fa = [mpfc_quintile_fa; zeros(size(mpfc_rppa_fa{i},1),1)+i-1];
    end
    s1_hit = s1_hit(:, t>0 & t<6);
    mpfc_hit = mpfc_hit(:, t>0 & t<6);
    time = t(t>0 & t<6);
    tbl = table(s1_quintile_hit, s1_hit(:,1), 'VariableNames', {'quintile', 't0'});
    for c = 2:size(s1_hit,2)
        tbl = [tbl, table(s1_hit(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ quintile',c-1), 'WithinDesign', time);
    fprintf('S1 Hit:\n')
    ranova(rm)
    tbl = table(mpfc_quintile_hit, mpfc_hit(:,1), 'VariableNames', {'quintile', 't0'});
    for c = 2:size(mpfc_hit,2)
        tbl = [tbl, table(mpfc_hit(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ quintile',c-1), 'WithinDesign', time);
    fprintf('mPFC Hit:\n')
    ranova(rm)

    s1_miss = s1_miss(:, t>0 & t<6);
    mpfc_miss = mpfc_miss(:, t>0 & t<6);
    time = t(t>0 & t<6);
    tbl = table(s1_quintile_miss, s1_miss(:,1), 'VariableNames', {'quintile', 't0'});
    for c = 2:size(s1_miss,2)
        tbl = [tbl, table(s1_miss(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ quintile',c-1), 'WithinDesign', time);
    fprintf('S1 Miss:\n')
    ranova(rm)
    tbl = table(mpfc_quintile_miss, mpfc_miss(:,1), 'VariableNames', {'quintile', 't0'});
    for c = 2:size(mpfc_miss,2)
        tbl = [tbl, table(mpfc_miss(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ quintile',c-1), 'WithinDesign', time);
    fprintf('mPFC Miss:\n')
    ranova(rm)

    s1_cr = s1_cr(:, t>0 & t<6);
    mpfc_cr = mpfc_cr(:, t>0 & t<6);
    time = t(t>0 & t<6);
    tbl = table(s1_quintile_cr, s1_cr(:,1), 'VariableNames', {'quintile', 't0'});
    for c = 2:size(s1_cr,2)
        tbl = [tbl, table(s1_cr(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ quintile',c-1), 'WithinDesign', time);
    fprintf('S1 CR:\n')
    ranova(rm)
    tbl = table(mpfc_quintile_cr, mpfc_cr(:,1), 'VariableNames', {'quintile', 't0'});
    for c = 2:size(mpfc_cr,2)
        tbl = [tbl, table(mpfc_cr(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ quintile',c-1), 'WithinDesign', time);
    fprintf('mPFC CR:\n')
    ranova(rm)

    s1_fa = s1_fa(:, t>0 & t<6);
    mpfc_fa = mpfc_fa(:, t>0 & t<6);
    time = t(t>0 & t<6);
    tbl = table(s1_quintile_fa, s1_fa(:,1), 'VariableNames', {'quintile', 't0'});
    for c = 2:size(s1_fa,2)
        tbl = [tbl, table(s1_fa(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ quintile',c-1), 'WithinDesign', time);
    fprintf('S1 FA:\n')
    ranova(rm)
    tbl = table(mpfc_quintile_fa, mpfc_fa(:,1), 'VariableNames', {'quintile', 't0'});
    for c = 2:size(mpfc_fa,2)
        tbl = [tbl, table(mpfc_fa(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ quintile',c-1), 'WithinDesign', time);
    fprintf('mPFC FA:\n')
    ranova(rm)

    bfig = figure();
    tl = tiledlayout(1,2);
    bax(1) = nexttile;
    hold on;
    for i = 1:length(s1_baseline)
        plot(zeros(size(s1_baseline{i},1),1)+i+(rand(size(s1_baseline{i},1),1)-0.5)*0.1, s1_baseline{i}, 'o', 'MarkerFaceColor', cols(i,:), 'MarkerEdgeColor', [1,1,1]);
    end
    errorbar(1:length(ptiles), cellfun(@nanmean,s1_baseline), cellfun(@ste, s1_baseline), 'k.', 'LineWidth', 2, 'CapSize', 15)
    title('S1', 'FontSize', 16)
    xticks(1:length(ptiles))
    bax(2) = nexttile;
    hold on;
    for i = 1:length(mpfc_baseline)
        plot(zeros(size(mpfc_baseline{i},1),1)+i+(rand(size(mpfc_baseline{i},1),1)-0.5)*0.1, mpfc_baseline{i}, 'o', 'MarkerFaceColor', cols(i,:), 'MarkerEdgeColor', [1,1,1]);
    end
    errorbar(1:length(ptiles), cellfun(@nanmean,mpfc_baseline), cellfun(@ste, mpfc_baseline), 'k.', 'LineWidth', 2, 'CapSize', 15)
    title('mPFC', 'FontSize', 16)
    xticks(1:length(ptiles))
    xlabel(tl, 'Baseline Pupil Area Quintile', 'FontSize', 16)
    unifyYLimits(bfig)
    ylabel(tl, 'Baseline NE (z-score)', 'FontSize', 16)
    
    mat = [];
    for i = 1:length(s1_baseline)
        mat = [mat, s1_baseline{i}];
    end
    fprintf('Basline S1 NE by baseline pupil area\n')
    [p,tbl,stats] = anova1(mat)
    mat = [];
    for i = 1:length(mpfc_baseline)
        mat = [mat, mpfc_baseline{i}];
    end
    fprintf('Basline mPFC NE by baseline pupil area\n')
    [p,tbl,stats] = anova1(mat)

    saveas(bfig, 'Figures/baselineNEbyBaselinePupil.fig')
    saveas(bfig, 'Figures/baselineNEbyBaselinePupil.fig')
    saveas(fig, 'Figures/nEbyBaselinePupil.fig')
    saveas(fig, 'Figures/nEbyBaselinePupil.fig')
    
end