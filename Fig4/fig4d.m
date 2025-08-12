function [dilations_animal, dilations_session] = fig4d(data, tbounds, alignTo, ver)
    outcomes = {'Hit', 'Miss', 'CR', 'FA', {'Hit', 'FA'}, {'Miss', 'CR'}};

    animals = fetchAnimals(data);
    sessions = unique(data.session_id);
    animal = {[], [], [], [], [], []};
    session = {[], [], [], [], [], []};

    if ~exist('alignTo', 'var')
        alignTo = 'stimulus';
    end

    for a = 1:length(animals)
        atmp = filterTrials(data, 'animal', num2str(animals(a)));
        for o = 1:length(outcomes)
            outcome = outcomes{o};
            otmp = filterTrials(atmp, 'categorical_outcome', outcome);
            if ~isempty(otmp)
                [~, s1, t] = avg_photo_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo, ver);
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
                [~, s1, t] = avg_photo_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo, ver);
                if size(s1,1) > 1
                    session{o} = [session{o}; nanmean(s1)];
                else
                    session{o} = [session{o}; s1];
                end
            else
                session{o} = [session{o}; nan(1,size(session{o},2))];
            end
        end
    end

    dilations_animal = {[], [], [], []};
    dilations_session = {[], [], [], []};
    for o = 1:length(outcomes)
        baselines_animal =  nanmean(animal{o}(:,(t > -0.5 & t < 0)),2);
        evoked_animal = nanmean(animal{o}(:,(t > 0 & t < 6)),2);
        baselines_session =  nanmean(session{o}(:,(t > -0.5 & t < 0)),2);
        evoked_session = nanmean(session{o}(:,(t > 0 & t < 6)),2);
        dilations_animal{o} = evoked_animal - baselines_animal;
        dilations_session{o} = evoked_session - baselines_session;
    end

    x = [1:4, 6:7];
    labels = {'Hit', 'Miss', 'CR', 'FA', 'Action', 'Withhold'};

    for i = 1:length(dilations_session) 
        avg(i) = mean(dilations_session{i});
        err(i) = std(dilations_session{i}) / sqrt(length(dilations_session{i}));
    end
    
    fig_sesh = figure();
    hold on 
    for i = 1:length(x)
        plot(zeros(1,length(dilations_session{i}))+x(i)+(rand([1,length(dilations_session{i})])-0.5)*-0.3, ...
            dilations_session{i}, 'o', 'MarkerFaceColor', [0.5,0.5,0.5], 'MarkerEdgeColor', [1,1,1], 'MarkerSize', 5)
    end
    errorbar(x, cellfun(@nanmean, dilations_session), cellfun(@ste, dilations_session), 'k.', 'CapSize', 15, 'LineWidth', 2)
    lims = ylim;
    plot([5,5], lims, 'k--')
    yticks([lims(1), 0, lims(2)])
    xticks(x)
    xticklabels(labels)
    xtickangle(45)
    ylabel('Mean Increase in NE_{s1} (z-score)')

    saveas(fig_sesh, 'Figures/fig4d.fig')
    saveas(fig_sesh, 'Figures/fig4d.svg')

    mat = [dilations_session{1}, dilations_session{2}, dilations_session{4}, dilations_session{4}];
    p = anova1(mat);
    fprintf('S1 NE stim induced increase:\n')
    fprintf(sprintf('Outcome anova: p = %d\n', p))
    fprintf(sprintf('Responded vs. Withheld, Wilcoxon signed-rank: p = %d\n', signrank(dilations_session{5}, dilations_session{6})))
    % fprintf(sprintf('Correct vs. Incorrect, Wilcoxon signed-rank: p = %d\n', signrank(dilations_session{7}, dilations_session{8})))

end