function fig2g(data)
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    animals = fetchAnimals(data);
    sessions = unique(data.session_id);

    if ~exist('alignTo', 'var')
        alignTo = 'stimulus';
    end

    rts = {};
    sesh = {};
    ptiles = [20,40,60,80,100];

    low = prctile(data.pupil_base_before_stimulus, 0);
    for i = 1:length(ptiles)
        ptile = ptiles(i);
        high = prctile(data.pupil_base_before_stimulus, ptile);
        x = data.pupil_base_before_stimulus >= low & data.pupil_base_before_stimulus <= high;
        low = high;
        tmp = data(x,:);
        tmp = filterTrials(tmp, 'categorical_outcome', 'Hit');
        rts{i} = tmp.response_time;
        sesh{i} = tmp.session_id;
    end
    
    session = vertcat(sesh{1}, sesh{2}, sesh{3}, sesh{4}, sesh{5});
    reaction_times = vertcat(rts{1}, rts{2}, rts{3}, rts{4}, rts{5});
    pupil = [zeros(size(rts{1}))+1; zeros(size(rts{2}))+2; zeros(size(rts{3}))+3; zeros(size(rts{4}))+4; zeros(size(rts{5}))+5];
    subject = {};
    for i = 1:length(session)
        subject{i} = session{i}(1:3);
    end
    subject = subject';

    x = 1:length(ptiles);

    fig_sesh = figure();
    hold on 
    % for i = 1:length(x)
    %     plot(zeros(1,length(session{i}))+x(i)+(rand([1,length(session{i})])-0.5)*-0.3, ...
    %         session{i}, 'o', 'MarkerFaceColor', [0.5,0.5,0.5], 'MarkerEdgeColor', [1,1,1], 'MarkerSize', 5)
    % end
    bar(x, cellfun(@nanmean, rts), 'FaceColor', [0.5,0.5,0.5])
    errorbar(x, cellfun(@nanmean, rts), cellfun(@ste, rts), 'k.', 'CapSize', 15, 'LineWidth', 2)
    lims = ylim;
    ylim([0,lims(2)])
    yticks([0, lims(2)])
    xticks(x)
    % xticklabels(l)
    % xtickangle(45)
    ylabel('Reaction Time (s)', 'FontSize', 16)
    xlabel('Baseline Pupil Area Quintile', 'FontSize', 16)

    T = table(reaction_times, pupil, session, subject,  'VariableNames', {'RT', 'Pupil', 'Session', 'Subject'});

    lmeTbl = T(:, {'RT','Pupil', 'Session', 'Subject'});

    % Make sure response is numeric
    lmeTbl.RT = double(lmeTbl.RT);

    % Make predictors categorical
    lmeTbl.Pupil = categorical(lmeTbl.Pupil);
    lmeTbl.Session  = categorical(lmeTbl.Session);
    lmeTbl.Subject  = categorical(lmeTbl.Subject);

    % Remove rows with missing values in any model variable
    badRows = isnan(lmeTbl.RT) | ...
            isundefined(lmeTbl.Pupil) | ...
            isundefined(lmeTbl.Subject) | ...
            isundefined(lmeTbl.Session);

    lmeTbl(badRows,:) = [];

    % Optional but useful: remove unused category levels
    lmeTbl.Pupil = removecats(lmeTbl.Pupil);
    lmeTbl.Session  = removecats(lmeTbl.Session);
    lmeTbl.Subject  = removecats(lmeTbl.Subject);

    fprintf('RT by baseline pupil LME\n')
    lme = fitlme(lmeTbl, ...
        'RT ~ Pupil + (1|Session) + (1|Subject)');
    anova(lme)

    saveas(fig_sesh, 'Figures/fig2g.fig')
    saveas(fig_sesh, 'Figures/fig2g.svg')

    % animal_fig = figure();
    % hold on
    % errorbar(x, sesh_avg, sesh_err, 'k.')
    % bar(x, sesh_avg, 'FaceColor', 'k', 'EdgeColor', 'k')
    % xticks(x)
    % xticklabels(l)
    % xtickangle(45)
    % ylabel('Reaction Time (s)', 'FontSize', 16)
    % xlabel('Baseline Pupil Area', 'FontSize', 16)
    % anova1(cell2mat(animal))

end
