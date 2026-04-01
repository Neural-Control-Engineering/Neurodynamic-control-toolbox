function [animal, session] = fig4k(data)
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    animals = fetchAnimals(data);
    sessions = unique(data.session_id);
    animal = {[],[],[],[],[]};
    session = {[],[],[],[],[]};
    ver = 'filtered';

    if ~exist('alignTo', 'var')
        alignTo = 'stimulus';
    end

    [mpfc, ~, ~] = avg_photo_traces(data, [-0.5, 0], 'stimulus', ver);
    baselines = nanmean(mpfc,2);
    ptiles = [20,40,60,80,100];
    low = prctile(baselines, 0);
    for i = 1:length(ptiles)
        ptile = ptiles(i);
        high = prctile(baselines, ptile);
        x = baselines >= low & baselines <= high;
        low = high;
        tmp = data(x,:);
        tmp = filterTrials(tmp, 'categorical_outcome', 'Hit');
        for a = 1:length(animals)
            atmp = filterTrials(tmp, 'animal', num2str(animals(a)));
            animal{i} = [animal{i}; nanmean(atmp.response_time)];
        end
        for s = 1:length(sessions)
            stmp = filterTrials(tmp, 'session_id', num2str(sessions(s)));
            session{i} = [session{i}; nanmean(stmp.response_time)];
        end
    end

    for i = 1:length(ptiles)
        animal_avg(i) = nanmean(animal{i});
        animal_err(i) = nanstd(animal{i}) / sqrt(length(animal{i}));
        sesh_avg(i) = nanmean(session{i});
        sesh_err(i) = nanstd(session{i}) / sqrt(length(session{i}));
    end

    x = 1:length(ptiles);
    l = {'1', '2', '3', '4', '5'};

    fig_sesh = figure();
    hold on 
    for i = 1:length(x)
        plot(zeros(1,length(session{i}))+x(i)+(rand([1,length(session{i})])-0.5)*-0.3, ...
            session{i}, 'o', 'MarkerFaceColor', [0.5,0.5,0.5], 'MarkerEdgeColor', [1,1,1], 'MarkerSize', 5)
    end
    errorbar(x, cellfun(@nanmean, session), cellfun(@ste, session), 'k.', 'CapSize', 15, 'LineWidth', 2)
    lims = ylim;
    ylim([0,lims(2)])
    yticks([0, lims(2)])
    xticks(x)
    xticklabels(l)
    xtickangle(45)
    ylabel('Reaction Time (s)', 'FontSize', 16)
    xlabel('Baseline NE_{mPFC}', 'FontSize', 16)
    p = anova1(cell2mat(session));
    fprintf('Reaction Time by Baseline NE mPFC:\n')
    fprintf(sprintf('One way anova: p = %d\n', p))

    saveas(fig_sesh, 'Figures/fig4k.fig')
    saveas(fig_sesh, 'Figures/fig4k.svg')

end
