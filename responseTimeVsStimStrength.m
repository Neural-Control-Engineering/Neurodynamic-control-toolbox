function responseTimeVsStimStrength(data)
    fig = figure();
    animals = fetchAnimals(data);
    cols = {'b', 'r', 'g', 'm'};
    stim_strengths = unique(data.stimulus_strength);
    for a = 1:length(animals)
        animal = animals(a);
        tmp = filterTrials(data, 'animal', num2str(animal));
        sessions = unique(tmp.session_id);
        stim_strengths = unique(tmp.stimulus_strength);
        dp = nan(length(sessions),length(stim_strengths)-1);
        for s = 1:length(sessions)
            stmp = filterTrials(tmp, 'session_id', num2str(sessions(s)));
            stim_strengths = unique(stmp.stimulus_strength);
            for ss = 2:length(stim_strengths)
                sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(ss));
                otmp = filterTrials(sstmp, 'categorical_outcome', 'Hit');
                dp(s,ss-1) = nanmean(otmp.response_time);
            end
        end
        plot(stim_strengths(2:end).*10, nanmean(dp), 'color', [0.5,0.5,0.5])
        hold on
        animal_avg(a,:) = nanmean(dp);
    end
    stim_strengths = unique(data.stimulus_strength);
    sessions = unique(data.session_id);
    mat = nan(length(sessions), length(stim_strengths)-1);
    for s = 1:length(sessions)
        stmp = filterTrials(data, 'session_id', num2str(sessions(s)));
        stim_strengths = unique(stmp.stimulus_strength);
        for ss = 2:length(stim_strengths)
            sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(ss));
            otmp = filterTrials(sstmp, 'categorical_outcome', 'Hit');
            if length(stim_strengths) == 2
                mat(s,end) = nanmean(otmp.response_time);
            else
                mat(s,ss-1) = nanmean(otmp.response_time);
            end
        end
    end
    errorbar(stim_strengths(2:end) .* 10, nanmean(mat), nanstd(mat) ./ sqrt(size(mat,1)), 'color', 'k', 'linewidth', 2, 'DisplayName', sprintf('(N_{sessions}=%i)', length(sessions)))
    % semshade(mat(:,2:end), 0.3, cols{a}, cols{a}, stim_strengths(2:end) .* 10, 1, sprintf('N_{animals}=4)'));
    xlabel('Stimulus Strength (PSI)', 'FontSize', 14)
    ylabel('Response Time (s)', 'FontSize', 14)
end