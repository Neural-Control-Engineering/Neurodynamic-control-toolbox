function [x, ss, tcile] = fig2jk(data)
    % ptiles = 25:25:100;
    ptiles = [33, 66, 100];
    low = prctile(data.pupil_base_before_stimulus, 0);
    stim_strengths = unique(data.stimulus_strength);
    cols = distinguishable_colors(5);
    animal_fig = figure();
    session_fig = figure();
    rppa_session = {};
    rppa_animal = {};
    for i = 1:length(ptiles)
        ptile = ptiles(i);
        high = prctile(data.pupil_base_before_stimulus, ptile);
        x = data.pupil_base_before_stimulus >= low & data.pupil_base_before_stimulus <= high;
        low = high;
        tmp = data(x,:);
        stim_strengths = unique(tmp.stimulus_strength);
        sessions = unique(tmp.session_id);
        animals = fetchAnimals(tmp);
        session_mat = nan(length(sessions), length(stim_strengths));
        for s = 1:length(sessions)
            stmp = filterTrials(tmp, 'session_id', num2str(sessions(s)));
            sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(1));
            fatmp = filterTrials(sstmp, 'categorical_outcome', 'FA');
            session_mat(s,1) = size(fatmp,1) / size(sstmp,1);
            for ss = 2:length(stim_strengths)
                sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(ss));
                otmp = filterTrials(sstmp, 'categorical_outcome', 'Hit');
                hr = size(otmp,1) / size(sstmp,1);
                if length(unique(stmp.stimulus_strength)) == 2
                    session_mat(s,end) = hr;
                else
                    session_mat(s, ss) = hr;
                end
            end
        end
        animal_mat = nan(length(animals), length(stim_strengths));
        for s = 1:length(animals)
            stmp = filterTrials(tmp, 'animal', num2str(animals(s)));
            sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(1));
            fatmp = filterTrials(sstmp, 'categorical_outcome', 'FA');
            animal_mat(s,1) = size(fatmp,1) / size(sstmp,1);
            for ss = 2:length(stim_strengths)
                sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(ss));
                otmp = filterTrials(sstmp, 'categorical_outcome', 'Hit');
                hr = size(otmp,1) / size(sstmp,1);
                if length(unique(stmp.stimulus_strength)) == 2
                    animal_mat(s,end) = hr;
                else
                    animal_mat(s, ss) = hr;
                end
            end
        end
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
        figure(session_fig)
        n = size(session_mat,1);
        semshade(session_mat, 0.3, cols(i,:), cols(i,:), stim_strengths .* 10, 1, sprintf('%s (n=%i)', l, n));
        hold on
        rppa_session{i} = session_mat;
        figure(animal_fig)
        n = size(animal_mat,1);
        semshade(animal_mat, 0.3, cols(i,:), cols(i,:), stim_strengths .* 10, 1, sprintf('%s (n=%i)', l, n));
        hold on
        rppa_animal{i} = session_mat;
    end
    x = [];
    ss = {};
    tcile = {};
    all_count = 1;
    for k = 1:length(ptiles)
        for i = 1:size(rppa_animal{k},1)
            for j = 1:size(rppa_animal{k},2)
                if ~isnan(rppa_animal{k}(i,j))
                    x = [x, rppa_animal{k}(i,k)];
                    ss{all_count} = num2str(stim_strengths(j));
                    tcile{all_count} = num2str(k);
                    all_count = all_count + 1;
                end
            end
        end
    end

    % keyboard
    figure(animal_fig)
    xlabel('Stimulus Strength (PSI)', 'FontSize', 14)
    ylabel('Response Probability', 'FontSize', 14)
    leg = legend('location', 'southeast');
    leg.Title.String = 'Baseline Pupil Area';

    figure(session_fig)
    xlabel('Stimulus Strength (PSI)', 'FontSize', 14)
    ylabel('Response Probability', 'FontSize', 14)
    leg = legend('location', 'southeast');
    leg.Title.String = 'Baseline Pupil Area';

    saveas(session_fig, 'Figures/fig2j.fig')
    saveas(session_fig, 'Figures/fig2j.svg')

end