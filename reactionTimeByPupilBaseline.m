function session = reactionTimeByPupilBaseline(data)
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    animals = fetchAnimals(data);
    sessions = unique(data.session_id);
    animal = {[],[],[]};
    session = {[],[],[]};

    if ~exist('alignTo', 'var')
        alignTo = 'stimulus';
    end

    ptiles = [33, 66, 100];
    low = prctile(data.pupil_base_before_stimulus, 0);
    for i = 1:length(ptiles)
        ptile = ptiles(i);
        high = prctile(data.pupil_base_before_stimulus, ptile);
        x = data.pupil_base_before_stimulus >= low & data.pupil_base_before_stimulus <= high;
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

    x = 1:3;
    l = {'Low', 'Medium', 'High'};

    sesh_fig = figure();
    hold on
    errorbar(x, sesh_avg, sesh_err, 'k.')
    bar(x, sesh_avg, 'FaceColor', 'k', 'EdgeColor', 'k')
    xticks(x)
    xticklabels(l)
    xtickangle(45)
    ylabel('Reaction Time (s)', 'FontSize', 16)
    xlabel('Baseline Pupil Area', 'FontSize', 16)
    anova1(cell2mat(session))

    animal_fig = figure();
    hold on
    errorbar(x, sesh_avg, sesh_err, 'k.')
    bar(x, sesh_avg, 'FaceColor', 'k', 'EdgeColor', 'k')
    xticks(x)
    xticklabels(l)
    xtickangle(45)
    ylabel('Reaction Time (s)', 'FontSize', 16)
    xlabel('Baseline Pupil Area', 'FontSize', 16)
    anova1(cell2mat(animal))

end
