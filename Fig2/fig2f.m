function [dilations_animal, dilations_session] = fig2f(data, tbounds, alignTo)
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    dilations = {[],[],[],[]};
    sesh = {{},{},{},{}};
    result = {};
    count = 1;

    for o = 1:length(outcomes)
        outcome = outcomes{o};
        otmp = filterTrials(data, 'categorical_outcome', outcome);
        if ~isempty(otmp)
            [pupil, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
            b = nanmean(pupil(:,(t > -0.5 & t < 0)),2);
            e = max(pupil(:,(t > 0 & t < 6)), [],2);
            dilations{o} = e - b;
        end
        sesh{o} = otmp.session_id;
    end
    all_dilations = [dilations{1}; dilations{2}; dilations{3}; dilations{4}];
    session = vertcat(sesh{1}, sesh{2}, sesh{3}, sesh{4});
    subject = {};
    for i = 1:length(session)
        subject{i} = session{i}(1:3);
    end
    subject = subject';
    response = [ones(size(dilations{1})); zeros(size(dilations{2})); zeros(size(dilations{3})); ones(size(dilations{4}))];
    outcomes = [zeros(size(dilations{1})); zeros(size(dilations{2}))+1; zeros(size(dilations{3}))+2; zeros(size(dilations{4}))+3];

    T = table(all_dilations, response, outcomes, session, subject,  'VariableNames', {'Dilation', 'Response', 'Outcome', 'Session', 'Subject'});

    lmeTbl = T(:, {'Dilation','Response', 'Outcome', 'Session', 'Subject'});

    % Make sure response is numeric
    lmeTbl.Dilation = double(lmeTbl.Dilation);

    % Make predictors categorical
    lmeTbl.Response = categorical(lmeTbl.Response);
    lmeTbl.Session  = categorical(lmeTbl.Session);
    lmeTbl.Subject  = categorical(lmeTbl.Subject);
    lmeTbl.Outcome  = categorical(lmeTbl.Outcome);

    % Remove rows with missing values in any model variable
    badRows = isnan(lmeTbl.Dilation) | ...
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

    fprintf('Dilation by response LME\n')
    lme = fitlme(lmeTbl, ...
        'Dilation ~ Response + (1|Session) + (1|Subject)');
    anova(lme)

    fprintf('Dilation by outcome LME\n')
    lmeo = fitlme(lmeTbl, ...
        'Dilation ~ Outcome + (1|Session) + (1|Subject)');
    anova(lmeo)
    % compare(lme, lmeo)
    
    fig = figure();
    hold on; 
    % for i = 1:length(dilations)
    %     plot((rand(size(dilations{i}))-0.5)*0.1+i, dilations{i}, 'o', 'MarkerFaceColor', [0.5,0.5,0.5], 'MarkerEdgeColor', 'w', 'MarkerSize', 2)
    % end
    bar(1:4, cellfun(@nanmean, dilations), 'FaceColor', [0.5,0.5,0.5], 'EdgeColor', 'k')
    errorbar(1:4, cellfun(@nanmean, dilations), cellfun(@ste, dilations), 'k.', 'LineWidth', 2, 'CapSize', 25)
    xticks(1:4)
    xticklabels({'Hit', 'Miss', 'Correct Rejection', 'False Alarm'})
    xtickangle(45)

    saveas(fig, 'Figures/fig2f.fig')
    saveas(fig, 'Figures/fig2f.svg')
end