function dPrimeByStimStrength(data)
    animals = fetchAnimals(data);
    fig_session = figure();
    fig_animal = figure();
    for a = 1:length(animals)
        animal = animals(a);
        tmp = filterTrials(data, 'animal', num2str(animal));
        sessions = unique(tmp.session_id);
        stim_strengths = unique(tmp.stimulus_strength);
        dp = nan(length(sessions),length(stim_strengths)-1);
        for s = 1:length(sessions)
            stmp = filterTrials(tmp, 'session_id', num2str(sessions(s)));
            stim_strengths = unique(stmp.stimulus_strength);
            sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(1));
            otmp = filterTrials(sstmp, 'categorical_outcome', 'FA');
            far = (size(otmp,1)+0.5) / (size(sstmp,1)+1);
            for ss = 2:length(stim_strengths)
                sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(ss));
                otmp = filterTrials(sstmp, 'categorical_outcome', 'Hit');
                hr = (size(otmp,1)+0.5) / (size(sstmp,1)+1);
                if length(stim_strengths) == 2
                    dp(s,end) = norminv(hr) - norminv(far);
                else
                    dp(s, ss-1) = norminv(hr) - norminv(far);
                end
            end
        end
        figure(fig_session)
        plot(stim_strengths(2:end) .* 10, nanmean(dp), 'color', [.5 .5 .5], 'linewidth', 2, 'DisplayName', sprintf('Animal %i (N_{sessions}=%i)', a-1, length(sessions)));
        hold on
        figure(fig_animal)
        plot(stim_strengths(2:end) .* 10, nanmean(dp), 'color', [.5 .5 .5], 'linewidth', 2, 'DisplayName', sprintf('Animal %i (N_{sessions}=%i)', a-1, length(sessions)));
        hold on
        animal_avg(a,:) = nanmean(dp);
    end
    animals = fetchAnimals(data);
    stim_strengths = unique(data.stimulus_strength);
    dp = nan(length(sessions), length(stim_strengths)-1);
    % dp = mat;
    sessions = unique(data.session_id);
    for s = 1:length(sessions)
        stmp = filterTrials(data, 'session_id', num2str(sessions(s)));
        stim_strengths = unique(stmp.stimulus_strength);
        sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(1));
        otmp = filterTrials(sstmp, 'categorical_outcome', 'FA');
        far = (size(otmp,1)+0.5) / (size(sstmp,1)+1);
        for ss = 2:length(stim_strengths)
            sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(ss));
            otmp = filterTrials(sstmp, 'categorical_outcome', 'Hit');
            hr = (size(otmp,1)+0.5) / (size(sstmp,1)+1);
            if length(stim_strengths) == 2
                dp(s,end) = norminv(hr) - norminv(far);
            else
                dp(s, ss-1) = norminv(hr) - norminv(far);
            end
        end
    end
    figure(fig_session)
    errorbar(stim_strengths(2:end) .* 10, nanmean(dp), nanstd(dp) ./ sqrt(length(sessions)), 'color', 'k', 'linewidth', 2, 'DisplayName', sprintf('Mean \x00B1 SEM: (N_{sessions}=%i)', length(sessions)))
    ylabel('d''', 'FontSize', 16)
    xlabel('Stimulus Strength (PSI)', 'FontSize', 16)
    figure(fig_animal)
    errorbar(stim_strengths(2:end) .* 10, nanmean(animal_avg), nanstd(animal_avg) ./ sqrt(length(animals)), 'color', 'k', 'linewidth', 2, 'DisplayName', sprintf('Mean \x00B1 SEM: (N_{animals}=%i)', length(animals)))
    ylabel('d''', 'FontSize', 16)
    xlabel('Stimulus Strength (PSI)', 'FontSize', 16)
end