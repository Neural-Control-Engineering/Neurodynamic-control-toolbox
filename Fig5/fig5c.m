function fig5c(data, tbounds, alignTo, ver)
    ptiles = [20,40,60,80,100];
    [pupil, t] = avg_pupil_traces(data, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
    pupil = pupil(:,2:end-1);
    t = t(2:end-1);
    b =  nanmean(pupil(:,(t > -0.5 & t < 0)),2);
    e = max(pupil(:,(t > 0 & t < 6)),[],2);
    dilations = e - b;
    low = prctile(dilations, 0);
    cols = distinguishable_colors(length(ptiles));
    s1_baseline = {};
    pfc_baseline = {};
    sesh = {};
    for i = 1:length(ptiles)
        ptile = ptiles(i);
        high = prctile(dilations, ptile);
        x = dilations >= low & dilations <= high;
        low = high;
        tmp = data(x,:);
        [pfc, s1, t] = avg_photo_traces(tmp, [tbounds(1), tbounds(2)], alignTo, ver);
        pfc = pfc(:,2:end-1);
        t = t(2:end-1);
        b =  nanmean(pfc(:,(t > -0.5 & t < 0)),2);
        e = max(pfc(:,(t > 0 & t < 2)),[],2);
        d = e - b;
        pfc_baseline{i} = d;
        pfc = pfc(:,2:end-1);
        t = t(2:end-1);
        b =  nanmean(pfc(:,(t > -0.5 & t < 0)),2);
        e = max(pfc(:,(t > 0 & t < 2)),[],2);
        d = e - b;
        s1_baseline{i} = nanmean(s1,2);
        sesh{i} = tmp.session_id;
    end

    session = vertcat(sesh{1}, sesh{2}, sesh{3}, sesh{4}, sesh{5});
    s1 = vertcat(s1_baseline{1}, s1_baseline{2}, s1_baseline{3}, s1_baseline{4}, s1_baseline{5});
    pfc = vertcat(pfc_baseline{1}, pfc_baseline{2}, pfc_baseline{3}, pfc_baseline{4}, pfc_baseline{5});
    ptiles = vertcat(zeros(size(pfc_baseline{1}))+1, zeros(size(pfc_baseline{2}))+2, zeros(size(pfc_baseline{3}))+3, zeros(size(pfc_baseline{4}))+4, zeros(size(pfc_baseline{5}))+5);
    subject = {};
    for i = 1:length(session)
        subject{i} = session{i}(1:3);
    end    

    T = table(s1, ptiles, ptiles.^2, session, subject',  'VariableNames', {'Baseline', 'Ptile', 'Ptile2', 'Session', 'Subject'});

    lmeTbl = T(:, {'Baseline', 'Ptile', 'Ptile2', 'Session', 'Subject'});

    % Make sure response is numeric
    lmeTbl.Baseline = double(lmeTbl.Baseline);

    % Make predictors categorical
    lmeTbl.Ptile = double(lmeTbl.Ptile);
    lmeTbl.Ptile2 = double(lmeTbl.Ptile2);
    lmeTbl.Session  = categorical(lmeTbl.Session);
    lmeTbl.Subject  = categorical(lmeTbl.Subject);
    % lmeTbl.Outcome  = categorical(lmeTbl.Outcome);

    % Remove rows with missing values in any model variable
    badRows = isnan(lmeTbl.Baseline) | ...
            isnan(lmeTbl.Ptile) | ...
            isnan(lmeTbl.Ptile) | ...
            isnan(lmeTbl.Ptile2) | ...
            isundefined(lmeTbl.Subject) | ...
            isundefined(lmeTbl.Session);

    lmeTbl(badRows,:) = [];

    % Optional but useful: remove unused category levels
    lmeTbl.Session  = removecats(lmeTbl.Session);
    lmeTbl.Subject  = removecats(lmeTbl.Subject);
    % lmeTbl.Ptile  = removecats(lmeTbl.Ptile);

    fprintf('Baseline S1 NE by baseline pupil LME\n')
    lme = fitlme(lmeTbl, ...
        'Baseline ~ Ptile + (1|Session) + (1|Subject)');
    anova(lme)

    T = table(pfc, ptiles, ptiles.^2, session, subject',  'VariableNames', {'Baseline', 'Ptile', 'Ptile2', 'Session', 'Subject'});

    lmeTbl = T(:, {'Baseline', 'Ptile', 'Ptile2', 'Session', 'Subject'});

    % Make sure response is numeric
    lmeTbl.Baseline = double(lmeTbl.Baseline);

    % Make predictors categorical
    lmeTbl.Ptile = double(lmeTbl.Ptile);
    lmeTbl.Ptile2 = double(lmeTbl.Ptile2);
    lmeTbl.Session  = categorical(lmeTbl.Session);
    lmeTbl.Subject  = categorical(lmeTbl.Subject);
    % lmeTbl.Outcome  = categorical(lmeTbl.Outcome);

    % Remove rows with missing values in any model variable
    badRows = isnan(lmeTbl.Baseline) | ...
            isnan(lmeTbl.Ptile) | ...
            isnan(lmeTbl.Ptile2) | ...
            isundefined(lmeTbl.Subject) | ...
            isundefined(lmeTbl.Session);

    lmeTbl(badRows,:) = [];

    % Optional but useful: remove unused category levels
    lmeTbl.Session  = removecats(lmeTbl.Session);
    lmeTbl.Subject  = removecats(lmeTbl.Subject);
    % lmeTbl.Ptile  = removecats(lmeTbl.Ptile);

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
    ylabel('\Delta NE in S1 (z-score)', 'FontSize', 16, 'Interpreter', 'tex')

    axs(2) = nexttile; hold on;
    for i = 1:length(pfc_baseline)
        bar(i, nanmean(pfc_baseline{i}), 'FaceColor', cols(i,:))
    end
    errorbar(1:length(pfc_baseline), cellfun(@nanmean, pfc_baseline), cellfun(@ste, pfc_baseline), 'k.', 'LineWidth', 2, 'CapSize', 15)
    xticks(1:5)
    ylabel('\Delta NE in PFC (z-score)', 'FontSize', 16, 'Interpreter', 'tex')
    xlabel(tl, 'Pupil Dilation Quintile', 'FontSize', 16)
    unifyYLimits(axs)

    saveas(fig, 'Figures/fig5c.fig')
    saveas(fig, 'Figures/fig5c.svg')

end