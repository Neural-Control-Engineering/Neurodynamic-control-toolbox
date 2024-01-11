function responseTimeVsStimStrengthByS1NeBaseline(data)
    animals = fetchAnimals(data);
    cols = {'b', 'r', 'g', 'm'};
    stim_strengths = unique(data.stimulus_strength);
    animal_avgs = {};
    session_avgs = {};
    
    [~, s1, ~] = avg_photo_traces(data, [-0.5, 0], 'stimulus');
    baselines = nanmean(s1,2);

    ptiles = [33, 66, 100];
    low = prctile(baselines, 0);
    for i = 1:length(ptiles)
        ptile = ptiles(i);
        high = prctile(baselines, ptile);
        x = baselines >= low & baselines <= high;
        low = high;
        ptmp = data(x,:);
        for a = 1:length(animals)
            animal = animals(a);
            tmp = filterTrials(ptmp, 'animal', num2str(animal));
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
            animal_avg{i}(a,:) = nanmean(dp);
        end
        stim_strengths = unique(ptmp.stimulus_strength);
        sessions = unique(ptmp.session_id);
        mat = nan(length(sessions), length(stim_strengths)-1);
        for s = 1:length(sessions)
            stmp = filterTrials(ptmp, 'session_id', num2str(sessions(s)));
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
        session_avg{i} = mat;
    end

    fig_session = figure();
    cols = distinguishable_colors(4);
    l = {'Low', 'Medium', 'High'};
    for i = 1:length(ptiles)
        errorbar(stim_strengths(2:end) .* 10, nanmean(session_avg{i}), nanstd(session_avg{i}) ./ sqrt(size(session_avg{i},1)), 'color', cols(i,:), 'linewidth', 2, 'DisplayName', l{i})
        hold on
    end
    xlabel('Stimulus Strength (PSI)', 'FontSize', 14)
    ylabel('Response Time (s)', 'FontSize', 14)
    leg = legend()
    leg.Title.String = 'Baseline NE_{S1}';

    fig_animal = figure();
    cols = distinguishable_colors(4);
    for i = 1:length(ptiles)
        errorbar(stim_strengths(2:end) .* 10, nanmean(animal_avg{i}), nanstd(animal_avg{i}) ./ sqrt(size(animal_avg{i},1)), 'color', cols(i,:), 'linewidth', 2, 'DisplayName', l{i})
        hold on
    end
    xlabel('Stimulus Strength (PSI)', 'FontSize', 14)
    ylabel('Response Time (s)', 'FontSize', 14)
    leg = legend()
    leg.Title.String = 'Baseline NE_{S1}';
end