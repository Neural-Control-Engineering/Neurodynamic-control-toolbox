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
        tl = tiledlayout(2,4)
        ax(1) = nexttile; hold on;
        semshade(s1_rppa_hit{i}, 0.3, cols(i,:), cols(i,:), t, 1, sprintf('%s', l));
        title('Hit')
        ylabel('NE in S1 (z-score)')
        ax(2) = nexttile; hold on;
        semshade(s1_rppa_miss{i}, 0.3, cols(i,:), cols(i,:), t, 1, sprintf('%s', l));
        title('Miss')
        ax(3) = nexttile; hold on;
        semshade(s1_rppa_cr{i}, 0.3, cols(i,:), cols(i,:), t, 1, sprintf('%s', l));
        title('Correct Rejection')
        ax(4) = nexttile; hold on;
        semshade(s1_rppa_fa{i}, 0.3, cols(i,:), cols(i,:), t, 1, sprintf('%s', l));
        ax(5) = nexttile; hold on;
        semshade(mpfc_rppa_hit{i}, 0.3, cols(i,:), cols(i,:), t, 1, sprintf('%s', l));
        ylabel('NE in S1 (z-score)')
        ax(6) = nexttile; hold on;
        semshade(mpfc_rppa_miss{i}, 0.3, cols(i,:), cols(i,:), t, 1, sprintf('%s', l));
        subplot(2,4,7); hold on;
        semshade(mpfc_rppa_cr{i}, 0.3, cols(i,:), cols(i,:), t, 1, sprintf('%s', l));
        subplot(2,4,8); hold on;
        semshade(mpfc_rppa_fa{i}, 0.3, cols(i,:), cols(i,:), t, 1, sprintf('%s', l));
    end
    for i = 1:8
        subplot(2,4,i); xlim([-0.5,6])
    end
    unifyYLimits(fig)
    mpfc_hit = [];
    mpfc_miss = [];
    mpfc_fa = [];
    mpfc_cr = [];
    mpfc_quintile = [];
    s1_hit = [];
    s1_miss = [];
    s1_fa = [];
    s1_cr = [];
    s1_quintile = [];
    for i = 1:length(s1_rppa_hit)
        s1_hit = [s1_hit; s1_rppa_hit{i}];
        s1_miss = [s1_miss; s1_rppa_miss{i}];
        s1_fa = [s1_fa; s1_rppa_fa{i}];
        s1_cr = [s1_cr; s1_rppa_cr{i}];
        mpfc_hit = [mpfc_hit; mpfc_rppa_hit{i}];
        mpfc_miss = [mpfc_miss; mpfc_rppa_miss{i}];
        mpfc_fa = [mpfc_fa; mpfc_rppa_fa{i}];
        mpfc_cr = [mpfc_cr; mpfc_rppa_cr{i}];
        s1_quintile = [s1_quintile; zeros(size(s1_rppa_hit{i},1),1)+i-1];
        mpfc_quintile = [mpfc_quintile; zeros(size(mpfc_rppa_hit{i},1),1)+i-1];
    end
    s1_hit = s1_hit(:, t>0 & t<6);
    mpfc_hit = mpfc_hit(:, t>0 & t<6);
    time = t(t>0 & t<6);
    tbl = table(s1_quintile, s1_hit(:,1), 'VariableNames', {'quintile', 't0'});
    for c = 2:size(s1_hit,2)
        tbl = [tbl, table(s1_hit(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ quintile',c-1), 'WithinDesign', time);
    ranova(rm)
    tbl = table(mpfc_quintile, mpfc_hit(:,1), 'VariableNames', {'quintile', 't0'});
    for c = 2:size(mpfc_hit,2)
        tbl = [tbl, table(mpfc_hit(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ quintile',c-1), 'WithinDesign', time);
    ranova(rm)
    figure();
    subplot(1,2,1)
    hold on;
    for i = 1:length(s1_baseline)
        plot(zeros(size(s1_baseline{i},1),1)+i+(rand(size(s1_baseline{i},1),1)-0.5)*0.1, s1_baseline{i}, 'o', 'MarkerFaceColor', cols(i,:), 'MarkerEdgeColor', [1,1,1]);
    end
    errorbar(1:length(s1_baseline), cellfun(@nanmean,s1_baseline), cellfun(@ste, s1_baseline), 'k.', 'LineWidth', 2, 'CapSize', 15)
    subplot(1,2,2)
    hold on;
    for i = 1:length(mpfc_baseline)
        plot(zeros(size(mpfc_baseline{i},1),1)+i+(rand(size(mpfc_baseline{i},1),1)-0.5)*0.1, mpfc_baseline{i}, 'o', 'MarkerFaceColor', cols(i,:), 'MarkerEdgeColor', [1,1,1]);
    end
    errorbar(1:length(mpfc_baseline), cellfun(@nanmean,mpfc_baseline), cellfun(@ste, mpfc_baseline), 'k.', 'LineWidth', 2, 'CapSize', 15)
    mat = [];
    for i = 1:length(s1_baseline)
        mat = [mat, s1_baseline{i}];
    end
    [p,tbl,stats] = anova1(mat)
    mat = [];
    for i = 1:length(mpfc_baseline)
        mat = [mat, mpfc_baseline{i}];
    end
    [p,tbl,stats] = anova1(mat)
end