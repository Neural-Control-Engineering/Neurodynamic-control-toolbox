function [animal, session, t] = pupilTraceByOutcome(data, tbounds, alignTo)
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    animals = fetchAnimals(data);
    sessions = unique(data.session_id);
    animal = {[], [], [], []};
    session = {[], [], [], []};

    if ~exist('alignTo', 'var')
        alignTo = 'stimulus';
    end

    for a = 1:length(animals)
        atmp = filterTrials(data, 'animal', num2str(animals(a)));
        for o = 1:length(outcomes)
            outcome = outcomes{o};
            otmp = filterTrials(atmp, 'categorical_outcome', outcome);
            if ~isempty(otmp)
                [pupil, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
                if size(pupil,1) > 1
                    animal{o} = [animal{o}; nanmean(pupil(:,2:end-1))];
                else
                    animal{o} = [animal{o}; pupil(2:end-1)];
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
                [pupil, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
                if size(pupil,1) > 1
                    session{o} = [session{o}; nanmean(pupil(:,2:end-1))];
                else
                    session{o} = [session{o}; pupil(2:end-1)];
                end
            end
        end
    end
            
    fig_sesh = figure('Visible', 'on', 'WindowState', 'maximized');
    axs_sesh = 1:length(outcomes);
    tl_sesh = tiledlayout(1,length(outcomes));
    
    for o = 1:length(outcomes)
        axs_sesh(o) = nexttile;
        axis square
        hold on
        n = size(pupil,1);
        semshade(session{o}, 0.3, 'k', 'k', ...
                t(2:end-1), 1, sprintf('%s (n=%i)', outcome, n));
        title(outcomes{o}, 'FontSize', 16)
        ylim([-0.7,1.0])
        xlim(tbounds)
        plot([0,0], [-0.7, 1.55], 'k:', 'HandleVisibility', 'off')
    end
    ylabel(tl_sesh, 'Pupil Area (z-score)', 'FontSize', 14)
    xlabel(tl_sesh, 'Time (s)', 'FontSize', 14)

    fig_animal = figure('Visible', 'on', 'WindowState', 'maximized');
    axs_animal = 1:length(outcomes);
    tl_animal = tiledlayout(1,length(outcomes));
    
    t = t(2:end-1);
    for o = 1:length(outcomes)
        axs_animal(o) = nexttile;
        axis square
        hold on
        n = size(pupil,1);
        semshade(animal{o}, 0.3, 'k', 'k', ...
                t, 1, sprintf('%s (n=%i)', outcome, n));
        title(outcomes{o}, 'FontSize', 16)
        ylim([-0.7,1.0])
        xlim(tbounds)
        plot([0,0], [-0.7, 1.55], 'k:', 'HandleVisibility', 'off')
    end
    ylabel(tl_animal, 'Pupil Area (z-score)', 'FontSize', 14)
    xlabel(tl_animal, 'Time (s)', 'FontSize', 14)
    % saveas(fig_sesh, 'Analysis/paper_figures/figure2/pupilByOutcome.fig')
end