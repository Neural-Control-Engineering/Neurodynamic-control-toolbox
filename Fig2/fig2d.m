function [animal, session, t] = fig2d(data, tbounds, alignTo)
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    animals = fetchAnimals(data);
    sessions = unique(data.session_id);
    animal = {{[],[],[],[],[]}, {[],[],[],[],[]}, {[],[],[],[],[]}, {[],[],[],[],[]}};
    session = {{[],[],[],[],[]}, {[],[],[],[],[]}, {[],[],[],[],[]}, {[],[],[],[],[]}};

    if ~exist('alignTo', 'var')
        alignTo = 'stimulus';
    end

    % ptiles = [33, 66, 100];
    ptiles = [20,40,60,80,100];
    low = prctile(data.pupil_base_before_stimulus, 0);
    for i = 1:length(ptiles)
        ptile = ptiles(i);
        high = prctile(data.pupil_base_before_stimulus, ptile);
        x = data.pupil_base_before_stimulus >= low & data.pupil_base_before_stimulus <= high;
        low = high;
        tmp = data(x,:);
        for a = 1:length(animals)
            atmp = filterTrials(tmp, 'animal', num2str(animals(a)));
            for o = 1:length(outcomes)
                outcome = outcomes{o};
                otmp = filterTrials(atmp, 'categorical_outcome', outcome);
                if ~isempty(otmp)
                    [pupil, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
                    if size(pupil,1) > 1
                        % animal{o}{i} = [animal{o}{i}; nanmean(pupil(:,2:end-1))];
                        animal{o}{i} = [animal{o}{i}; nanmean(pupil)];
                    else
                        % animal{o}{i} = [animal{o}{i}; pupil(2:end-1)];
                        animal{o}{i} = [animal{o}{i}; pupil];
                    end
                end
            end
        end
        for s = 1:length(sessions)
            stmp = filterTrials(tmp, 'session_id', num2str(sessions(s)));
            for o = 1:length(outcomes)
                outcome = outcomes{o};
                otmp = filterTrials(stmp, 'categorical_outcome', outcome);
                if ~isempty(otmp)
                    [pupil, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
                    if size(pupil,1) > 1
                        % session{o}{i} = [session{o}{i}; nanmean(pupil(:,2:end-1))];
                        session{o}{i} = [session{o}{i}; nanmean(pupil)];
                    else
                        % session{o}{i} = [session{o}{i}; pupil(2:end-1)];
                        session{o}{i} = [session{o}{i}; pupil];
                    end
                end
            end
        end
    end
    % t = t(2:end-1);
            
    cols = distinguishable_colors(length(ptiles));
    fig_sesh = figure('Visible', 'on', 'WindowState', 'maximized');
    tl_sesh = tiledlayout(2,2);

    l = {'1st quintile', '2nd quintile', '3rd quintile', '4th quintile', '5th quintile'};
    for o = 1:length(outcomes)
        axs_sesh(o) = nexttile;
        for i = 1:length(ptiles)
            axis square
            hold on
            n = size(pupil,1);
            semshade(session{o}{i}, 0.3, cols(i,:), cols(i,:), ...
                    t, 1, l{i});
            title(outcomes{o}, 'FontSize', 16)
            ylim([-1.2,2])
            xlim(tbounds)
            plot([0,0], [-1.2,2], 'k:', 'HandleVisibility', 'off')
        end
    end
    ylabel(tl_sesh, 'Pupil Area (z-score)', 'FontSize', 14)
    xlabel(tl_sesh, 'Time (s)', 'FontSize', 14)
    axes(axs_sesh(1))
    legend()
    saveas(fig_sesh, 'Figures/fig2d.fig')
    saveas(fig_sesh, 'Figures/fig2d.svg')
    % fig_animal = figure('Visible', 'on', 'WindowState', 'maximized');
    % tl_animal = tiledlayout(2,2);
    
    % for o = 1:length(outcomes)
    %     axs_animal(o) = nexttile;
    %     for i = 1:3    
    %         axis square
    %         hold on
    %         n = size(pupil,1);
    %         semshade(animal{o}{i}, 0.3, cols(i,:), cols(i,:), ...
    %                 t, 1, l{i});
    %         title(outcomes{o}, 'FontSize', 16)
    %         ylim([-1.2,2])
    %         xlim(tbounds)
    %         plot([0,0], [-1.2,2], 'k:', 'HandleVisibility', 'off')
    %     end
    % end
    % ylabel(tl_animal, 'Pupil Area (z-score)', 'FontSize', 14)
    % xlabel(tl_animal, 'Time (s)', 'FontSize', 14)
    % axes(axs_animal(1))
    % legend()
    % saveas(fig_sesh, 'Analysis/paper_figures/figure2/pupilByOutcome.fig')
end