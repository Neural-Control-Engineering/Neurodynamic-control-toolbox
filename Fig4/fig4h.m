function fig4h(data, tbounds, alignTo, ver)

    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    animal_ne = {};
    session_ne = {};
    for i = 1:length(outcomes)
        animal_ne{i} = [];
        session_ne{i} = [];
    end
    
    animals = fetchAnimals(data);
    sessions = unique(data.session_id);

    for a = 1:length(animals)
        atmp = filterTrials(data, 'animal', num2str(animals(a)));
        for i = 1:length(outcomes)
            otmp = filterTrials(atmp, 'categorical_outcome', outcomes{i});
            if ~isempty(otmp)
                [mpfc, ~, t] = avg_photo_traces(otmp, tbounds, alignTo, ver);
                animal_ne{i} = [animal_ne{i}; nanmean(mpfc)];
            end
        end
    end

    for a = 1:length(sessions)
        atmp = filterTrials(data, 'session_id', num2str(sessions(a)));
        for i = 1:length(outcomes)
            otmp = filterTrials(atmp, 'categorical_outcome', outcomes{i});
            if ~isempty(otmp)
                [mpfc, ~, t] = avg_photo_traces(otmp, tbounds, alignTo, ver);
                if size(mpfc,1) > 1
                    session_ne{i} = [session_ne{i}; nanmean(mpfc)];
                else
                    session_ne{i} = [session_ne{i}; mpfc];
                end
            end
        end
    end

    
    session_fig = figure();
    tl_sesh = tiledlayout(1,4);
    tls = {'Hit', 'Miss', 'Correct Rejection', 'False Alarm'};
    for i = 1:length(tls)
        axs_sesh(i) = nexttile;
        out = semshade(session_ne{i}, 0.3, 'k', 'k', ...
                t, 1, tls{i});
        hold on
        xlim(tbounds)
        plot([0,0], [-3,3], 'k:', 'HandleVisibility', 'off')
        title(tls{i}, 'FontSize', 16)
        ylim([-0.4, 1.0])
    end
    xlabel(tl_sesh, 'Time (s)', 'FontSize', 16)
    ylabel(tl_sesh, 'NE_{mPFC}', 'FontSize', 16)
    
end