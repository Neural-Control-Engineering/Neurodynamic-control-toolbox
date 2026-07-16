function fig5b(data, tbounds, alignTo, ver)
    ptiles = [20,40,60,80,100];
    low = prctile(data.pupil_base_before_stimulus, 0);
    cols = distinguishable_colors(length(ptiles));
    s1_baseline = {};
    pfc_baseline = {};
    sesh = {};
    for i = 1:length(ptiles)
        ptile = ptiles(i);
        high = prctile(data.pupil_base_before_stimulus, ptile);
        x = data.pupil_base_before_stimulus >= low & data.pupil_base_before_stimulus <= high;
        low = high;
        tmp = data(x,:);
        [pfc, s1, ~] = avg_photo_traces(tmp, [-0.5, 0], 'stimulus', ver);
        s1_baseline{i} = nanmean(s1,2);
        pfc_baseline{i} = nanmean(pfc,2);
        sesh{i} = tmp.session_id;
    end

    session = vertcat(sesh{1}, sesh{2}, sesh{3}, sesh{4}, sesh{5});
    s1 = vertcat(s1_baseline{1}, s1_baseline{2}, s1_baseline{3}, s1_baseline{4}, s1_baseline{5});
    pfc = vertcat(pfc_baseline{1}, pfc_baseline{2}, pfc_baseline{3}, pfc_baseline{4}, pfc_baseline{5});
    ptiles = vertcat(zeros(size(pfc_baseline{1}))+1, zeros(size(pfc_baseline{2}))+2, zeros(size(pfc_baseline{3}))+3, zeros(size(pfc_baseline{4}))+3, zeros(size(pfc_baseline{5}))+5);
    subject = {};
    for i = 1:length(session)
        subject{i} = session{i}(1:3);
    end    

    T = table(s1, ptiles, session, subject',  'VariableNames', {'Baseline', 'Ptile', 'Session', 'Subject'});

    lmeTbl = T(:, {'Baseline', 'Ptile', 'Session', 'Subject'});

    % Make sure response is numeric
    lmeTbl.Baseline = double(lmeTbl.Baseline);

    % Make predictors categorical
    lmeTbl.Ptile = categorical(lmeTbl.Ptile);
    lmeTbl.Session  = categorical(lmeTbl.Session);
    lmeTbl.Subject  = categorical(lmeTbl.Subject);
    % lmeTbl.Outcome  = categorical(lmeTbl.Outcome);

    % Remove rows with missing values in any model variable
    badRows = isnan(lmeTbl.Baseline) | ...
            isundefined(lmeTbl.Ptile) | ...
            isundefined(lmeTbl.Subject) | ...
            isundefined(lmeTbl.Session);

    lmeTbl(badRows,:) = [];

    % Optional but useful: remove unused category levels
    lmeTbl.Session  = removecats(lmeTbl.Session);
    lmeTbl.Subject  = removecats(lmeTbl.Subject);
    lmeTbl.Ptile  = removecats(lmeTbl.Ptile);

    fprintf('Baseline S1 NE by baseline pupil LME\n')
    lme = fitlme(lmeTbl, ...
        'Baseline ~ Ptile + (1|Session) + (1|Subject)');
    anova(lme)

    T = table(pfc, ptiles, session, subject',  'VariableNames', {'Baseline', 'Ptile', 'Session', 'Subject'});

    lmeTbl = T(:, {'Baseline', 'Ptile', 'Session', 'Subject'});

    % Make sure response is numeric
    lmeTbl.Baseline = double(lmeTbl.Baseline);

    % Make predictors categorical
    lmeTbl.Ptile = categorical(lmeTbl.Ptile);
    lmeTbl.Session  = categorical(lmeTbl.Session);
    lmeTbl.Subject  = categorical(lmeTbl.Subject);
    % lmeTbl.Outcome  = categorical(lmeTbl.Outcome);

    % Remove rows with missing values in any model variable
    badRows = isnan(lmeTbl.Baseline) | ...
            isundefined(lmeTbl.Ptile) | ...
            isundefined(lmeTbl.Subject) | ...
            isundefined(lmeTbl.Session);

    lmeTbl(badRows,:) = [];

    % Optional but useful: remove unused category levels
    lmeTbl.Session  = removecats(lmeTbl.Session);
    lmeTbl.Subject  = removecats(lmeTbl.Subject);
    lmeTbl.Ptile  = removecats(lmeTbl.Ptile);

    fprintf('Baseline PFC NE by baseline pupil LME\n')
    lme = fitlme(lmeTbl, ...
        'Baseline ~ Ptile + (1|Session) + (1|Subject)');
    anova(lme)

    fig = figure('Position', [1 1 477 658]);
    tl = tiledlayout(2,1);
    axs(1) = nexttile; hold on;
    for i = 1:length(s1_baseline)
        bar(i, nanmean(s1_baseline{i}), 'FaceColor', cols(i,:))
    end
    errorbar(1:length(s1_baseline), cellfun(@nanmean, s1_baseline), cellfun(@ste, s1_baseline), 'k.', 'LineWidth', 2, 'CapSize', 15)
    xticks(1:5)
    title('All Trials', 'FontSize', 16)
    ylabel('Baseline NE in S1 (z-score)', 'FontSize', 16)

    axs(2) = nexttile; hold on;
    for i = 1:length(pfc_baseline)
        bar(i, nanmean(pfc_baseline{i}), 'FaceColor', cols(i,:))
    end
    errorbar(1:length(pfc_baseline), cellfun(@nanmean, pfc_baseline), cellfun(@ste, pfc_baseline), 'k.', 'LineWidth', 2, 'CapSize', 15)
    xticks(1:5)
    ylabel('Baseline NE in PFC (z-score)', 'FontSize', 16)
    xlabel(tl, 'Baseline Pupil Size Quintile', 'FontSize', 16)
    unifyYLimits(axs)

    saveas(fig, 'Figures/fig5b.fig')
    saveas(fig, 'Figures/fig5b.svg')
    
end