function responseTimeVsStimStrengthByPupil(data)
    % ptiles = 25:25:100;
    ptiles = [33, 66, 100];
    low = prctile(data.pupil_base_before_stimulus, 0);
    stim_strengths = unique(data.stimulus_strength);
    cols = distinguishable_colors(5);
    fig = figure();
    for i = 1:length(ptiles)
        ptile = ptiles(i);
        high = prctile(data.response_time, ptile);
        x = data.pupil_base_before_stimulus >= low & data.pupil_base_before_stimulus <= high;
        low = high;
        tmp = data(x,:);
        stim_strengths = unique(tmp.stimulus_strength);
        sessions = unique(tmp.session_id);
        animals = fetchAnimals(tmp);
        % mat = nan(length(sessions), length(stim_strengths)-1);
        % for s = 1:length(sessions)
        %     stmp = filterTrials(tmp, 'session_id', num2str(sessions(s)));
        mat = nan(length(animals), length(stim_strengths)-1);
        for s = 1:length(animals)
            stmp = filterTrials(tmp, 'animal', num2str(animals(s)));
            for ss = 2:length(stim_strengths)
                sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(ss));
                otmp = filterTrials(sstmp, 'categorical_outcome', 'Hit');
                if length(stim_strengths) == 2
                    mat(s,end) = nanmean(otmp.response_time);
                else
                    mat(s, ss-1) = nanmean(otmp.response_time);
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
                l = sprintf('%ist tercile', i);
            case 2
                l = sprintf('%ind tercile', i);
            case 3
                l = sprintf('%ird tercile', i);
            otherwise
                l = sprintf('%ith quartile', i);
        end
        n = size(mat,1);
        semshade(mat, 0.3, cols(i,:), cols(i,:), stim_strengths(2:end) .* 10, 1, sprintf('%s (n=%i)', l, n));
        hold on
    end
    xlabel('Stimulus Strength (PSI)', 'FontSize', 14)
    ylabel('Response Probability', 'FontSize', 14)
    leg = legend('location', 'southeast');
    leg.Title.String = 'Baseline Pupil Area';
end