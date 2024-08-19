function fig4g(data, tbounds, alignTo, ver)

    animal_ne = {};
    session_ne = {};
    for i = 1:length(unique(data.stimulus_strength))
        animal_ne{i} = [];
        session_ne{i} = [];
    end
    
    animals = fetchAnimals(data);
    sessions = unique(data.session_id);

    for a = 1:length(animals)
        atmp = filterTrials(data, 'animal', num2str(animals(a)));
        stim_strengths = unique(atmp.stimulus_strength);
        for i = 1:length(stim_strengths)
            stim = stim_strengths(i);
            otmp = filterTrials(atmp, 'stim_strength', stim);
            if ~isempty(otmp)
                [mPFC, ~, t] = avg_photo_traces(otmp, tbounds, alignTo, ver);
                if length(stim_strengths) == 2 && i == 2
                    animal_ne{end} = [animal_ne{end}; nanmean(mPFC)];
                else
                    animal_ne{i} = [animal_ne{i}; nanmean(mPFC)];
                end
            end
        end
    end

    for a = 1:length(sessions)
        atmp = filterTrials(data, 'session_id', num2str(sessions(a)));
        stim_strengths = unique(atmp.stimulus_strength);
        for i = 1:length(stim_strengths)
            stim = stim_strengths(i);
            otmp = filterTrials(atmp, 'stim_strength', stim);
            if ~isempty(otmp)
                [mPFC, ~, t] = avg_photo_traces(otmp, tbounds, alignTo, ver);
                if length(stim_strengths) == 2 && i == 2
                    if size(mPFC,1) > 1
                        session_ne{end} = [session_ne{end}; nanmean(mPFC)];
                    else
                        session_ne{end} = [session_ne{end}; mPFC];
                    end
                else
                    if size(mPFC,1) > 1
                        session_ne{i} = [session_ne{i}; nanmean(mPFC)];
                    else
                        session_ne{i} = [session_ne{i}; mPFC];
                    end
                end
            end
        end
    end

    stim_strengths = unique(data.stimulus_strength);
    cols = distinguishable_colors(length(stim_strengths)+1);
    
    session_fig = figure();
    hold on
    for i = 1:length(stim_strengths)
        stim = stim_strengths(i);
        l = sprintf('%.1f PSI', stim*10);
        out = semshade(session_ne{i}, 0.3, cols(i,:), cols(i,:), ...
                t, 1, l);
    end
    xlim(tbounds)
    plot([0,0], [-3,3], 'k:', 'HandleVisibility', 'off')
    xlabel('Time (s)', 'FontSize', 16)
    ylabel('NE_{mPFC}', 'FontSize', 16)
    ylim([-0.22, 1])
    leg = legend();
    leg.Title.String = 'Stimulus Strength';
    
    % animal_fig = figure();
    % hold on
    % for i = 1:length(stim_strengths)
    %     stim = stim_strengths(i);
    %     l = sprintf('%.1f PSI', stim*10);
    %     out = semshade(animal_ne{i}, 0.3, cols(i,:), cols(i,:), ...
    %             t, 1, l);
    % end
    % xlim(tbounds)
    % plot([0,0], [-3,3], 'k:', 'HandleVisibility', 'off')
    % xlabel('Time (s)', 'FontSize', 16)
    % ylabel('NE_{mPFC}', 'FontSize', 16)
    % ylim([-0.22, 0.7])
    % leg = legend();
    % leg.Title.String = 'Stimulus Strength';
    
end