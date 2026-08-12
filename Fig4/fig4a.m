function fig4a(data, tbounds, alignTo, ver)

    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    baselines = {[],[],[],[]};
    sesh = {{},{},{},{}};

    for o = 1:length(outcomes)
        outcome = outcomes{o};
        otmp = filterTrials(data, 'categorical_outcome', outcome);
        if ~isempty(otmp)
            [~, s1, t] = avg_photo_traces(otmp, [tbounds(1), tbounds(2)], alignTo, ver);
            baselines{o} = nanmean(s1(:,(t > -0.5 & t < 0)),2);
        end
        sesh{o} = otmp.session_id;
    end
    
    all_baselines = [baselines{1}; baselines{2}; baselines{3}; baselines{4}];
    session = vertcat(sesh{1}, sesh{2}, sesh{3}, sesh{4});
    subject = {};
    for i = 1:length(session)
        subject{i} = session{i}(1:3);
    end
    subject = subject';
    response = [ones(size(baselines{1})); zeros(size(baselines{2})); zeros(size(baselines{3})); ones(size(baselines{4}))];
    outcomes = [zeros(size(baselines{1})); zeros(size(baselines{2}))+1; zeros(size(baselines{3}))+2; zeros(size(baselines{4}))+3];

    T = table(all_baselines, response, outcomes, session, subject,  'VariableNames', {'Baseline', 'Response', 'Outcome', 'Session', 'Subject'});

    lmeTbl = T(:, {'Baseline','Response', 'Outcome', 'Session', 'Subject'});

    % Make sure response is numeric
    lmeTbl.Baseline = double(lmeTbl.Baseline);

    % Make predictors categorical
    lmeTbl.Response = categorical(lmeTbl.Response);
    lmeTbl.Session  = categorical(lmeTbl.Session);
    lmeTbl.Subject  = categorical(lmeTbl.Subject);
    lmeTbl.Outcome  = categorical(lmeTbl.Outcome);

    % Remove rows with missing values in any model variable
    badRows = isnan(lmeTbl.Baseline) | ...
            isundefined(lmeTbl.Response) | ...
            isundefined(lmeTbl.Outcome) | ...
            isundefined(lmeTbl.Subject) | ...
            isundefined(lmeTbl.Session);

    lmeTbl(badRows,:) = [];

    % Optional but useful: remove unused category levels
    lmeTbl.Response = removecats(lmeTbl.Response);
    lmeTbl.Session  = removecats(lmeTbl.Session);
    lmeTbl.Subject  = removecats(lmeTbl.Subject);
    lmeTbl.Outcome  = removecats(lmeTbl.Outcome);

    fprintf('Baseline by response LME\n')
    lme = fitlme(lmeTbl, ...
        'Baseline ~ Response + (1|Session) + (1|Subject)');
    anova(lme)

    fprintf('Baseline by outcome LME\n')
    lmeo = fitlme(lmeTbl, ...
        'Baseline ~ Outcome + (1|Session) + (1|Subject)');
    anova(lmeo)

    % compare(lme, lmeo)

    fig = figure();
    hold on; 
    % for i = 1:length(baselines)
    %     plot((rand(size(baselines{i}))-0.5)*0.1+i, baselines{i}, 'o', 'MarkerFaceColor', [0.5,0.5,0.5], 'MarkerEdgeColor', 'w', 'MarkerSize', 2)
    % end
    bar(1:4, cellfun(@nanmean, baselines), 'FaceColor', [0.5,0.5,0.5], 'EdgeColor', 'k')
    errorbar(1:4, cellfun(@nanmean, baselines), cellfun(@ste, baselines), 'k.', 'LineWidth', 2, 'CapSize', 25)
    bar(6:7, [nanmean(vertcat(baselines{1}, baselines{4})), nanmean(vertcat(baselines{2}, baselines{3}))], 'FaceColor', [0.5,0.5,0.5], 'EdgeColor', 'k')
    errorbar(6:7, [nanmean(vertcat(baselines{1}, baselines{4})), nanmean(vertcat(baselines{2}, baselines{3}))], [ste(vertcat(baselines{1}, baselines{4})), ste(vertcat(baselines{2}, baselines{3}))], 'k.', 'LineWidth', 2, 'CapSize', 25)
    xticks([1:4, 6:7])
    xticklabels({'Hit', 'Miss', 'Correct Rejection', 'False Alarm', 'Responded', 'Withheld'})
    xtickangle(45)
    lims = ylim;
    plot([5,5], lims, 'k--')
    ylim(lims)
    ylabel('Baseline NE in S1 (z-score)', 'FontSize', 16)
    xlabel('Trial Outcome', 'FontSize', 16)

    saveas(fig, 'Figures/fig4a.fig')
    saveas(fig, 'Figures/fig4a.svg')

end