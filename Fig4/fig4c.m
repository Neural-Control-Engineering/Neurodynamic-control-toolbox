function [baselines_animal, baselines_session] = fig4c(data, tbounds, alignTo, ver)
    outcomes = {'Hit', 'Miss', 'CR', 'FA', {'Hit', 'FA'}, {'Miss', 'CR'}};

    animals = fetchAnimals(data);
    sessions = unique(data.session_id);
    animal = {[], [], [], [], [], []};
    session = {[], [], [], [], [], []};
    session_sesh = session;

    if ~exist('alignTo', 'var')
        alignTo = 'stimulus';
    end

    for a = 1:length(animals)
        atmp = filterTrials(data, 'animal', num2str(animals(a)));
        for o = 1:length(outcomes)
            outcome = outcomes{o};
            otmp = filterTrials(atmp, 'categorical_outcome', outcome);
            if ~isempty(otmp)
                [~, s1, t] = avg_photo_traces(otmp, [tbounds(1), tbounds(2)], alignTo, ver);
                if size(s1,1) > 1
                    animal{o} = [animal{o}; nanmean(s1)];
                else
                    animal{o} = [animal{o}; s1];
                end
            end
        end
    end

    for s = 1:length(sessions)
        stmp = filterTrials(data, 'session_id', num2str(sessions(s)));
        for o = 1:length(outcomes)
            outcome = outcomes{o};
            otmp = filterTrials(stmp, 'categorical_outcome', outcome);
            if ~isempty(otmp)
                [~, s1, t] = avg_photo_traces(otmp, [tbounds(1), tbounds(2)], alignTo, ver);
                if size(s1,1) > 1
                    session{o} = [session{o}; nanmean(s1)];
                else
                    session{o} = [session{o}; s1];
                end
            else
                session{o} = [session{o}; nan(1,size(session{o},2))];
            end
            session_sesh{o} = [session_sesh{o}; sessions{s}];
        end
    end

    baselines_animal = {[], [], [], [], [], []};
    baselines_session = {[], [], [], [], [], []};
    for o = 1:length(outcomes)
        baselines_animal{o} =  nanmean(animal{o}(:,(t > -0.5 & t < 0)),2);
        baselines_session{o} =  nanmean(session{o}(:,(t > -0.5 & t < 0)),2);
    end

    x = [1:4, 6:7];
    labels = {'Hit', 'Miss', 'CR', 'FA', 'Action', 'Withhold'};

    for i = 1:length(baselines_session) 
        avg(i) = mean(baselines_session{i});
        err(i) = std(baselines_session{i}) / sqrt(length(baselines_session{i}));
    end
    
    fig_sesh = figure();
    hold on 
    for i = 1:length(x)
        plot(zeros(1,length(baselines_session{i}))+x(i)+(rand([1,length(baselines_session{i})])-0.5)*-0.3, ...
            baselines_session{i}, 'o', 'MarkerFaceColor', [0.5,0.5,0.5], 'MarkerEdgeColor', [1,1,1], 'MarkerSize', 5)
    end
    errorbar(x, cellfun(@nanmean, baselines_session), cellfun(@ste, baselines_session), 'k.', 'CapSize', 15, 'LineWidth', 2)
    lims = ylim;
    plot([5,5], lims, 'k--')
    yticks([lims(1), 0, lims(2)])
    xticks(x)
    xticklabels(labels)
    xtickangle(45)
    ylabel('Baseline NE_{S1} (z-score)')

    % mat = [baselines_session{1}, baselines_session{2}, baselines_session{3}, baselines_session{4}];
    % [p, ~, stats] = anova1(mat);
    % fprintf('S1 NE baseline:\n')
    % fprintf(sprintf('Outcome anova: p = %d\n', p))
    % fprintf(sprintf('Responded vs. Withheld, Wilcoxon signed-rank: p = %d\n', signrank(baselines_session{5}, baselines_session{6})))
    % mc = multcompare(stats)

    sesh = cellstr(vertcat(session_sesh{1}, session_sesh{2}, session_sesh{3}, session_sesh{4}));
    subj = {};
    for i = 1:length(sesh)
        subj{i} = sesh{i}(1:3);
    end
    tbl = table([baselines_session{1}; baselines_session{2}; baselines_session{3}; baselines_session{4}], ...
        [ones(size(baselines_session{1})); zeros(size(baselines_session{2})); zeros(size(baselines_session{3})); ones(size(baselines_session{4}))], ...
        [ones(size(baselines_session{1})); zeros(size(baselines_session{2})); ones(size(baselines_session{3})); zeros(size(baselines_session{4}))], ...
        sesh, subj', 'VariableNames', {'baseline', 'response', 'outcome', 'session', 'subject'});
    tbl.response = categorical(tbl.response);
    tbl.session = categorical(tbl.session);
    tbl.subject = categorical(tbl.subject);
    badRows = isnan(tbl.baseline) | ...
        isundefined(tbl.response) | ...
        isundefined(tbl.subject) | ...
        isundefined(tbl.session);
    tbl(badRows,:) = [];
    lme = fitlme(tbl, ...
        'baseline ~ response*outcome + (1|session) + (1|subject)');
    fprintf('LME Baseline S1 NE, Response, Outcome\n')
    anova(lme)

    keyboard 
    saveas(fig_sesh, 'Figures/fig4c.fig')
    saveas(fig_sesh, 'Figures/fig4c.svg')
    % fprintf(sprintf('Correct vs. Incorrect, Wilcoxon signed-rank: p = %d\n', signrank(baselines_session{7}, baselines_session{8})))

    % for i = 1:length(baselines_animal) 
    %     avg(i) = mean(baselines_animal{i});
    %     err(i) = std(baselines_animal{i}) / sqrt(length(baselines_animal{i}));
    % end
    
    % figure()
    % hold on
    % errorbar(x, avg, err, 'k.');
    % bar(x, avg, 'k')
    % xticks(x)
    % xticklabels(labels)
    % xtickangle(45)
    % ylabel('Baseline NE_{S1} (z-score)')

end