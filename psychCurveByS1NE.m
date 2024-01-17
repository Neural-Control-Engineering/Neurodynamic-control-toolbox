function psychCurveByS1NE(data, ver)

    [~, s1, ~] = avg_photo_traces(data, [-0.5, 0], 'stimulus', ver);
    baselines = nanmean(s1,2);

    % ptiles = 25:25:100;
    ptiles = [33, 66, 100];
    low = prctile(baselines, 0);
    stim_strengths = unique(data.stimulus_strength);
    cols = distinguishable_colors(5);
    fig = figure();
    for i = 1:length(ptiles)
        ptile = ptiles(i);
        high = prctile(baselines, ptile);
        x = baselines >= low & baselines <= high;
        low = high;
        tmp = data(x,:);
        stim_strengths = unique(tmp.stimulus_strength);
        sessions = unique(tmp.session_id);
        animals = fetchAnimals(tmp);
        % mat = nan(length(sessions), length(stim_strengths));
        % for s = 1:length(sessions)
        %     stmp = filterTrials(tmp, 'session_id', num2str(sessions(s)));
        %     sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(1));
        %     fatmp = filterTrials(sstmp, 'categorical_outcome', 'FA');
        %     mat(s,1) = size(fatmp,1) / size(sstmp,1);
        mat = nan(length(animals), length(stim_strengths));
        for s = 1:length(animals)
            stmp = filterTrials(tmp, 'animal', num2str(animals(s)));
            sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(1));
            fatmp = filterTrials(sstmp, 'categorical_outcome', 'FA');
            mat(s,1) = size(fatmp,1) / size(sstmp,1);
            for ss = 2:length(stim_strengths)
                sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(ss));
                otmp = filterTrials(sstmp, 'categorical_outcome', 'Hit');
                hr = size(otmp,1) / size(sstmp,1);
                if length(unique(stmp.stimulus_strength)) == 2
                    mat(s,end) = hr;
                else
                    mat(s, ss) = hr;
                end
            end
        end
        % mat = nan(size(tmp,1), length(stim_strengths));
        % for trial = 1:size(tmp,1)
        %     ind = find(stim_strengths == tmp.stimulus_strength(trial));
        %     if strcmp(tmp.categorical_outcome{trial}, 'Hit') || strcmp(tmp.categorical_outcome{trial}, 'CR')
        %         mat(trial, ind) = 1;
        %     else
        %         mat(trial, ind) = 0;
        %     end
        % end
        switch i 
            case 1  
                l = sprintf('Low', i);
            case 2
                l = sprintf('Medium', i);
            case 3
                l = sprintf('High', i);
            otherwise
                l = sprintf('%ith quartile', i);
        end
        n = size(mat,1);
        semshade(mat, 0.3, cols(i,:), cols(i,:), stim_strengths .* 10, 1, sprintf('%s (n=%i)', l, n));
        hold on
    end
    xlabel('Stimulus Strength (PSI)', 'FontSize', 14)
    ylabel('Response Probability', 'FontSize', 14)
    leg = legend('location', 'southeast');
    leg.Title.String = 'Baseline NE_{S1}';
end