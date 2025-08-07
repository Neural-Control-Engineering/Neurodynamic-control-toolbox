function [animal, session] = fig2f(data, tbounds, alignTo)
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
                [pupil, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
                if size(pupil,1) > 1
                    baselines = nanmean(pupil(:,(t > -0.5 & t < 0)),2);
                    evoked = nanmean(pupil(:,(t > 0 & t < 6.0)),2);
                    dilations = evoked - baselines;
                else
                    baselines = nanmean(pupil(t > -0.5 & t < 0));
                    evoked = nanmean(pupil(t > 0 & t < 6.0));
                    dilations = evoked - baselines;
                end
                pcc = corrcoef(baselines, dilations);
                animal{o} = [animal{o}; pcc(1,2)];
            end
        end
    end

    for a = 1:length(sessions)
        atmp = filterTrials(data, 'session_id', num2str(sessions(a)));
        for o = 1:length(outcomes)
            outcome = outcomes{o};
            otmp = filterTrials(atmp, 'categorical_outcome', outcome);
            if ~isempty(otmp)
                [pupil, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
                if size(pupil,1) > 1
                    baselines = nanmean(pupil(:,(t > -0.5 & t < 0)),2);
                    evoked = nanmean(pupil(:,(t > 0 & t < 6.0)),2);
                    dilations = evoked - baselines;
                    pcc = corrcoef(baselines, dilations);
                    session{o} = [session{o}; pcc(1,2)];
                else
                    session{o} = [session{o}; nan];
                end
            else
                session{o} = [session{o}; nan];
            end
        end
    end

    for i = 1:length(outcomes)
        sesh_avg(i) = nanmean(session{i});
        sesh_err(i) = nanstd(session{i}) / sqrt(length(session{i}));
        animal_avg(i) = nanmean(animal{i});
        animal_err(i) = nanstd(animal{i}) / sqrt(length(animal{i}));
    end

    x = [1:4, 6:7];
    l = {'Hit', 'Miss', 'CR', 'FA', 'Responded', 'Withheld'};

    fig_sesh = figure();
    hold on 
    for i = 1:length(x)
        plot(zeros(1,length(session{i}))+x(i)+(rand([1,length(session{i})])-0.5)*-0.3, ...
            session{i}, 'o', 'MarkerFaceColor', [0.5,0.5,0.5], 'MarkerEdgeColor', [1,1,1], 'MarkerSize', 5)
    end
    errorbar(x, cellfun(@nanmean, session), cellfun(@ste, session), 'k.', 'CapSize', 15, 'LineWidth', 2)
    lims = ylim;
    plot([5,5], lims, 'k--')
    yticks([lims(1), 0, lims(2)])
    xticks(x)
    xticklabels(l)
    xtickangle(45)
    ylabel({'Pearson''s correlation coefficient', '(pupil baseline vs. dilation)'})

    mat = [session{1}, session{2}, session{4}, session{4}];
    p = anova1(mat);
    fprintf('Pupil baseline vs dilation pearsons correlation coefficient:\n')
    fprintf(sprintf('Outcome anova: p = %d\n', p))
    fprintf(sprintf('Responded vs. Withheld, Wilcoxon signed-rank: p = %d\n', signrank(session{5}, session{6})))

end