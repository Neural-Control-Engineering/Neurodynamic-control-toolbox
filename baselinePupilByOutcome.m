function [baselines_animal, baselines_session] = baselinePupilByOutcome(data, tbounds, alignTo)
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
                    animal{o} = [animal{o}; nanmean(pupil)];
                else
                    animal{o} = [animal{o}; pupil];
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
                [pupil, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
                if size(pupil,1) > 1
                    session{o} = [session{o}; nanmean(pupil)];
                else
                    session{o} = [session{o}; pupil];
                end
            end
        end
    end

    baselines_animal = {[], [], [], []};
    baselines_sessions = {[], [], [], []};
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
    
    figure()
    hold on
    errorbar(x, avg, err, 'k.');
    bar(x, avg, 'k')
    xticks(x)
    xticklabels(labels)
    xtickangle(45)
    ylabel('Baseline Pupil Area (z-score)')

    for i = 1:length(baselines_animal) 
        avg(i) = mean(baselines_animal{i});
        err(i) = std(baselines_animal{i}) / sqrt(length(baselines_animal{i}));
    end
    
    figure()
    hold on
    errorbar(x, avg, err, 'k.');
    bar(x, avg, 'k')
    xticks(x)
    xticklabels(labels)
    xtickangle(45)
    ylabel('Baseline Pupil Area (z-score)')

end