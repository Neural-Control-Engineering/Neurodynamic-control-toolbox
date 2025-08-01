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
    
    figure()
    bar(x, avg, 'EdgeColor', [0.5,0.5,0.5], 'FaceColor', [0.5,0.5,0.5])
    hold on
    errorbar(x, avg, err, 'k.');
    xticks(x)
    xticklabels(labels)
    xtickangle(45)
    ylabel('Mean Increase in NE_{s1} (z-score)')

    for i = 1:length(dilations_animal) 
        avg(i) = mean(dilations_animal{i});
        err(i) = std(dilations_animal{i}) / sqrt(length(dilations_animal{i}));
    end
    keyboard     
    % figure()
    % hold on
    % errorbar(x, avg, err, 'k.');
    % bar(x, avg, 'k')
    % xticks(x)
    % xticklabels(labels)
    % xtickangle(45)
    % ylabel('Mean Increase in NE_{s1} (z-score)')

end