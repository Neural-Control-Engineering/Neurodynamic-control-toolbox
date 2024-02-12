function avgPsychCurves(data)
    animals = fetchAnimals(data);
    cols = {'b', 'r', 'g', 'm'};
    stim_strengths = unique(data.stimulus_strength);
    fig_session = figure()
    fig_animal = figure()
    for a = 1:length(animals)
        animal = animals(a);
        tmp = filterTrials(data, 'animal', num2str(animal));
        sessions = unique(tmp.session_id);
        stim_strengths = unique(tmp.stimulus_strength);
        dp = nan(length(sessions),length(stim_strengths));
        for s = 1:length(sessions)
            stmp = filterTrials(tmp, 'session_id', num2str(sessions(s)));
            stim_strengths = unique(stmp.stimulus_strength);
            sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(1));
            otmp = filterTrials(sstmp, 'categorical_outcome', 'FA');
            far = size(otmp,1) / size(sstmp,1);
            dp(s,1) = far;
            for ss = 2:length(stim_strengths)
                sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(ss));
                otmp = filterTrials(sstmp, 'categorical_outcome', 'Hit');
                hr = size(otmp,1) / size(sstmp,1);
                if length(stim_strengths) == 2
                    dp(s,end) = hr;
                else
                    dp(s, ss) = hr;
                end
            end
        end
        figure(fig_session)
        plot(stim_strengths .* 10, nanmean(dp), 'color', [.5 .5 .5], 'linewidth', 2, 'DisplayName', sprintf('Animal %i (N_{sessions}=%i)', a-1, length(sessions)));
        hold on
        figure(fig_animal)
        plot(stim_strengths .* 10, nanmean(dp), 'color', [.5 .5 .5], 'linewidth', 2, 'DisplayName', sprintf('Animal %i (N_{sessions}=%i)', a-1, length(sessions)));
        hold on
        animal_avg(a,:) = nanmean(dp);
    end
    % animals = fetchAnimals(data);
    % stim_strengths = unique(data.stimulus_strength);
    sessions = unique(data.session_id);
    mat = nan(length(sessions), length(stim_strengths));
    
    for s = 1:length(sessions)
        stmp = filterTrials(data, 'session_id', num2str(sessions(s)));
        stim_strengths = unique(stmp.stimulus_strength);
        sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(1));
        otmp = filterTrials(sstmp, 'categorical_outcome', 'FA');
        far = size(otmp,1) / size(sstmp,1);
        mat(s,1) = far;
        for ss = 2:length(stim_strengths)
            sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(ss));
            otmp = filterTrials(sstmp, 'categorical_outcome', 'Hit');
            if length(stim_strengths) == 2
                mat(s,end) = size(otmp,1) / size(sstmp,1);
            else
                mat(s,ss) = size(otmp,1) / size(sstmp,1);
            end
        end
    end
    % mat = nansum(mat,1) ./ sum(~isnan(mat),1);
    % semshade(mat(:,2:end), 0.3, 'k', 'k', stim_strengths(2:end) .* 10, 1, sprintf('Mean: (N_{animals}=%i)', length(animals)));
    % plot(stim_strengths(2:end) .* 10, nanmean(mat(:,2:end)), 'k--', 'LineWidth', 2, 'DisplayName', sprintf('Mean: (N_{animals}=%i)', length(animals)))
    figure(fig_session)
    errorbar(stim_strengths .* 10, nanmean(mat), nanstd(mat) ./ sqrt(size(mat,1)), 'color', 'k', 'linewidth', 2, 'DisplayName', sprintf('(N_{sessions}=%i)', length(sessions)))
    xlabel('Stimulus Strength (PSI)', 'FontSize', 14)
    ylabel('Response Probability', 'FontSize', 14)
    legend('location', 'southeast')

    figure(fig_animal)
    errorbar(stim_strengths .* 10, nanmean(animal_avg), nanstd(animal_avg) ./ sqrt(size(animal_avg,1)), 'color', 'k', 'linewidth', 2, 'DisplayName', sprintf('(N_{animals}=%i)', size(animal_avg,1)))
    xlabel('Stimulus Strength (PSI)', 'FontSize', 14)
    ylabel('Response Probability', 'FontSize', 14)
    legend('location', 'southeast')
    % saveas(fig, 'Analysis/paper_figures/figure2/baselinePupilByOutcome.fig')
end