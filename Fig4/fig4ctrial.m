function fig4ctrial(data, tbounds, alignTo, ver)

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
    outcomes = [ones(size(baselines{1})); zeros(size(baselines{2})); ones(size(baselines{3})); zeros(size(baselines{4}))];

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

end