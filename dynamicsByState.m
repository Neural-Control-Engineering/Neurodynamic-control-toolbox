function dynamicsByState()

    Datastore = load('Combined-Datastore_created_14-Jan-2024.mat');
    data = filterTrials(Datastore.Datastore, 'recording_location', 'mPFC-S1');
    animals = fetchAnimals(data);
    model = readtable('glmhmm_K3_state_assignments.csv');
    model = model(strcmp(model.model, 'New'),:);
    model(cellfun(@isempty, data.photometry_ch1),:) = [];
    data(cellfun(@isempty, data.photometry_ch1),:) = [];
    sessions = unique(data.session_id);
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    alignTo = 'stimulus';
    K = 3;
    s1_ne = {};
    mpfc_ne = {};
    pupil_baseline = {};
    s1_ne_baseline = {};
    mpfc_ne_baseline = {};
    pupil = {};
    for k = 1:K
        s1_ne{k} = {[], [], [], []};
        mpfc_ne{k} = {[], [], [], []};
        pupil{k} = {[], [], [], []};
        s1_ne_baseline{k} = {[], [], [], [], []};
        mpfc_ne_baseline{k} = {[], [], [], [], []};
        pupil_baseline{k} = {[], [], [], [], []};
    end
    tbounds = [-0.5, 6];
    for s = 1:length(sessions)
        tmp = data(strcmp(data.session_id, sessions{s}),:);
        model_tmp = model(strcmp(model.session, sessions{s}),:);
        for k = 1:K 
            ktmp = tmp(model_tmp.state == (k-1),:);
            for o = 1:length(outcomes)
                otmp = ktmp(strcmp(ktmp.categorical_outcome, outcomes{o}),:);
                if ~isempty(otmp)
                    [mpfc, s1, t] = avg_photo_traces(otmp, tbounds, alignTo, 'z-score');
                    [p, pt] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
                    if size(mpfc,1) > 1
                        s1_ne{k}{o} = [s1_ne{k}{o}; nanmean(s1)];
                        mpfc_ne{k}{o} = [mpfc_ne{k}{o}; nanmean(mpfc)];
                        pupil{k}{o} = [pupil{k}{o}; nanmean(p)];
                    else 
                        s1_ne{k}{o} = [s1_ne{k}{o}; s1];
                        mpfc_ne{k}{o} = [mpfc_ne{k}{o}; mpfc];
                        pupil{k}{o} = [pupil{k}{o}; p];
                    end 
                    [mpfc, s1, ~] = avg_photo_traces(otmp, [-0.5,0], alignTo, 'z-score');
                    [p, ~] = avg_pupil_traces(otmp, [-0.5-0.1, 0], alignTo);
                    if size(mpfc,1) > 1
                        s1_ne_baseline{k}{o} = [s1_ne_baseline{k}{o}; nanmean(nanmean(s1,2))];
                        mpfc_ne_baseline{k}{o} = [mpfc_ne_baseline{k}{o}; nanmean(nanmean(mpfc,2))];
                        pupil_baseline{k}{o} = [pupil_baseline{k}{o}; nanmean(nanmean(p),2)];
                    else 
                        s1_ne_baseline{k}{o} = [s1_ne_baseline{k}{o}; nanmean(s1)];
                        mpfc_ne_baseline{k}{o} = [mpfc_ne_baseline{k}{o}; nanmean(mpfc)];
                        pupil_baseline{k}{o} = [pupil_baseline{k}{o}; nanmean(p)];
                    end 
                else
                    s1_ne_baseline{k}{o} = [s1_ne_baseline{k}{o}; nan];
                    mpfc_ne_baseline{k}{o} = [mpfc_ne_baseline{k}{o}; nan];
                    pupil_baseline{k}{o} = [pupil_baseline{k}{o}; nan];
                end
            end 
            [mpfc, s1, ~] = avg_photo_traces(ktmp, [-0.5,0], alignTo, 'z-score');
            [p, ~] = avg_pupil_traces(ktmp, [-0.5-0.1, 0], alignTo);
            if size(mpfc,1) > 1
                s1_ne_baseline{k}{end} = [s1_ne_baseline{k}{end}; nanmean(nanmean(s1,2))];
                mpfc_ne_baseline{k}{end} = [mpfc_ne_baseline{k}{end}; nanmean(nanmean(mpfc,2))];
                pupil_baseline{k}{end} = [pupil_baseline{k}{end}; nanmean(nanmean(p),2)];
            elseif size(mpfc,1)
                s1_ne_baseline{k}{end} = [s1_ne_baseline{k}{end}; nanmean(s1)];
                mpfc_ne_baseline{k}{end} = [mpfc_ne_baseline{k}{end}; nanmean(mpfc)];
                pupil_baseline{k}{end} = [pupil_baseline{k}{end}; nanmean(p)];
            else 
                s1_ne_baseline{k}{end} = [s1_ne_baseline{k}{end}; nan];
                mpfc_ne_baseline{k}{end} = [mpfc_ne_baseline{k}{end}; nan];
                pupil_baseline{k}{end} = [pupil_baseline{k}{end}; nan];
            end
        end 
    end

    s1_fig = figure();
    tl = tiledlayout(1,4);
    axs = zeros(1,4);
    cols = distinguishable_colors(K);
    outcomes = {'Hit', 'Miss', 'Correct Rejection', 'False Alarm'};
    for o = 1:length(outcomes) 
        axs(o) = nexttile; hold on;
        for k = 1:K 
            semshade(s1_ne{k}{o}, 0.3, cols(k,:), cols(k,:), t, 5);
        end 
        xlim(tbounds)
        title(outcomes{o}, 'FontSize', 16)
    end
    xlabel(tl, 'Time (s)', 'FontSize', 16)
    ylabel(tl, 'NE in S1 (z-score)', 'FontSize', 16)
    unifyYLimits(s1_fig);

    mpfc_fig = figure();
    tl = tiledlayout(1,4);
    axs = zeros(1,4);
    cols = distinguishable_colors(K);
    outcomes = {'Hit', 'Miss', 'Correct Rejection', 'False Alarm'};
    for o = 1:length(outcomes) 
        axs(o) = nexttile; hold on;
        for k = 1:K 
            semshade(mpfc_ne{k}{o}, 0.3, cols(k,:), cols(k,:), t, 30);
        end 
        xlim(tbounds)
        title(outcomes{o}, 'FontSize', 16)
    end
    xlabel(tl, 'Time (s)', 'FontSize', 16)
    ylabel(tl, 'NE in mPFC (z-score)', 'FontSize', 16)
    unifyYLimits(mpfc_fig);

    pupil_fig = figure();
    tl = tiledlayout(1,4);
    axs = zeros(1,4);
    cols = distinguishable_colors(K);
    outcomes = {'Hit', 'Miss', 'Correct Rejection', 'False Alarm'};
    for o = 1:length(outcomes) 
        axs(o) = nexttile; hold on;
        for k = 1:K 
            semshade(pupil{k}{o}, 0.3, cols(k,:), cols(k,:), pt, 30);
        end 
        xlim(tbounds)
        title(outcomes{o}, 'FontSize', 16)
    end
    xlabel(tl, 'Time (s)', 'FontSize', 16)
    ylabel(tl, 'Pupil Area (z-score)', 'FontSize', 16)
    unifyYLimits(pupil_fig);

    pupil_hit_mat = [];
    s1_hit_mat = [];
    mpfc_hit_mat = [];
    state_hit_mat = [];
    pupil_miss_mat = [];
    s1_miss_mat = [];
    mpfc_miss_mat = [];
    state_miss_mat = [];
    pupil_cr_mat = [];
    s1_cr_mat = [];
    mpfc_cr_mat = [];
    state_cr_mat = [];
    pupil_fa_mat = [];
    s1_fa_mat = [];
    mpfc_fa_mat = [];
    state_fa_mat = [];
    baseline_pupil_hit_mat = [];
    baseline_s1_hit_mat = [];
    baseline_mpfc_hit_mat = [];
    baseline_state_hit_mat = [];
    baseline_pupil_miss_mat = [];
    baseline_s1_miss_mat = [];
    baseline_mpfc_miss_mat = [];
    baseline_state_miss_mat = [];
    baseline_pupil_cr_mat = [];
    baseline_s1_cr_mat = [];
    baseline_mpfc_cr_mat = [];
    baseline_state_cr_mat = [];
    baseline_pupil_fa_mat = [];
    baseline_s1_fa_mat = [];
    baseline_mpfc_fa_mat = [];
    baseline_state_fa_mat = [];
    for k = 1:length(pupil)
        o = 1;
        pupil_hit_mat = [pupil_hit_mat; pupil{k}{o}];
        s1_hit_mat = [s1_hit_mat; s1_ne{k}{o}];
        mpfc_hit_mat = [mpfc_hit_mat; mpfc_ne{k}{o}];
        state_hit_mat = [state_hit_mat; repmat(k,size(pupil{k}{o},1),1)];
        o = 2;
        pupil_miss_mat = [pupil_miss_mat; pupil{k}{o}];
        s1_miss_mat = [s1_miss_mat; s1_ne{k}{o}];
        mpfc_miss_mat = [mpfc_miss_mat; mpfc_ne{k}{o}];
        state_miss_mat = [state_miss_mat; repmat(k,size(pupil{k}{o},1),1)];
        o = 3;
        pupil_cr_mat = [pupil_cr_mat; pupil{k}{o}];
        s1_cr_mat = [s1_cr_mat; s1_ne{k}{o}];
        mpfc_cr_mat = [mpfc_cr_mat; mpfc_ne{k}{o}];
        state_cr_mat = [state_cr_mat; repmat(k,size(pupil{k}{o},1),1)];
        o = 4;
        pupil_fa_mat = [pupil_fa_mat; pupil{k}{o}];
        s1_fa_mat = [s1_fa_mat; s1_ne{k}{o}];
        mpfc_fa_mat = [mpfc_fa_mat; mpfc_ne{k}{o}];
        state_fa_mat = [state_fa_mat; repmat(k,size(pupil{k}{o},1),1)];
        o = 1;
        baseline_pupil_hit_mat = [baseline_pupil_hit_mat; pupil_baseline{k}{o}];
        baseline_s1_hit_mat = [baseline_s1_hit_mat; s1_ne_baseline{k}{o}];
        baseline_mpfc_hit_mat = [baseline_mpfc_hit_mat; mpfc_ne_baseline{k}{o}];
        baseline_state_hit_mat = [baseline_state_hit_mat; repmat(k,size(pupil_baseline{k}{o},1),1)];
        o = 2;
        baseline_pupil_miss_mat = [baseline_pupil_miss_mat; pupil_baseline{k}{o}];
        baseline_s1_miss_mat = [baseline_s1_miss_mat; s1_ne_baseline{k}{o}];
        baseline_mpfc_miss_mat = [baseline_mpfc_miss_mat; mpfc_ne_baseline{k}{o}];
        baseline_state_miss_mat = [baseline_state_miss_mat; repmat(k,size(pupil_baseline{k}{o},1),1)];
        o = 3;
        baseline_pupil_cr_mat = [baseline_pupil_cr_mat; pupil_baseline{k}{o}];
        baseline_s1_cr_mat = [baseline_s1_cr_mat; s1_ne_baseline{k}{o}];
        baseline_mpfc_cr_mat = [baseline_mpfc_cr_mat; mpfc_ne_baseline{k}{o}];
        baseline_state_cr_mat = [baseline_state_cr_mat; repmat(k,size(pupil_baseline{k}{o},1),1)];
        o = 4;
        baseline_pupil_fa_mat = [baseline_pupil_fa_mat; pupil_baseline{k}{o}];
        baseline_s1_fa_mat = [baseline_s1_fa_mat; s1_ne_baseline{k}{o}];
        baseline_mpfc_fa_mat = [baseline_mpfc_fa_mat; mpfc_ne_baseline{k}{o}];
        baseline_state_fa_mat = [baseline_state_fa_mat; repmat(k,size(pupil_baseline{k}{o},1),1)];
    end

    tbl = table(state_hit_mat, pupil_hit_mat(:,1), 'VariableNames', {'state', 't0'});
    for c = 2:size(pupil_hit_mat,2)
        tbl = [tbl, table(pupil_hit_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', pt);
    fprintf('Pupil Hit:\n')
    ranova(rm)

    s1_hit_mat = s1_hit_mat(:,t > 0 & t <= 5); 
    time = t(t > 0 & t <= 5);
    tbl = table(state_hit_mat, s1_hit_mat(:,1), 'VariableNames', {'state', 't0'});
    for c = 2:size(s1_hit_mat,2)
        tbl = [tbl, table(s1_hit_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', time);
    fprintf('S1 Hit:\n')
    ranova(rm)

    mpfc_hit_mat = mpfc_hit_mat(:,t > 0 & t <= 5); 
    time = t(t > 0 & t <= 5);
    tbl = table(state_hit_mat, mpfc_hit_mat(:,1), 'VariableNames', {'state', 't0'});
    for c = 2:size(mpfc_hit_mat,2)
        tbl = [tbl, table(mpfc_hit_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', time);
    fprintf('mPFC Hit:\n')
    ranova(rm)

    tbl = table(state_miss_mat, pupil_miss_mat(:,1), 'VariableNames', {'state', 't0'});
    for c = 2:size(pupil_miss_mat,2)
        tbl = [tbl, table(pupil_miss_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', pt);
    fprintf('Pupil Miss:\n')
    ranova(rm)

    s1_miss_mat = s1_miss_mat(:,t > 0 & t <= 5); 
    time = t(t > 0 & t <= 5);
    tbl = table(state_miss_mat, s1_miss_mat(:,1), 'VariableNames', {'state', 't0'});
    for c = 2:size(s1_miss_mat,2)
        tbl = [tbl, table(s1_miss_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', time);
    fprintf('S1 Miss:\n')
    ranova(rm)

    mpfc_miss_mat = mpfc_miss_mat(:,t > 0 & t <= 5); 
    time = t(t > 0 & t <= 5);
    tbl = table(state_miss_mat, mpfc_miss_mat(:,1), 'VariableNames', {'state', 't0'});
    for c = 2:size(mpfc_miss_mat,2)
        tbl = [tbl, table(mpfc_miss_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', time);
    fprintf('mPFC Miss:\n')
    ranova(rm)

    tbl = table(state_cr_mat, pupil_cr_mat(:,1), 'VariableNames', {'state', 't0'});
    for c = 2:size(pupil_cr_mat,2)
        tbl = [tbl, table(pupil_cr_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', pt);
    fprintf('Pupil CR:\n')
    ranova(rm)

    s1_cr_mat = s1_cr_mat(:,t > 0 & t <= 5); 
    time = t(t > 0 & t <= 5);
    tbl = table(state_cr_mat, s1_cr_mat(:,1), 'VariableNames', {'state', 't0'});
    for c = 2:size(s1_cr_mat,2)
        tbl = [tbl, table(s1_cr_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', time);
    fprintf('S1 CR:\n')
    ranova(rm)

    mpfc_cr_mat = mpfc_cr_mat(:,t > 0 & t <= 5); 
    time = t(t > 0 & t <= 5);
    tbl = table(state_cr_mat, mpfc_cr_mat(:,1), 'VariableNames', {'state', 't0'});
    for c = 2:size(mpfc_cr_mat,2)
        tbl = [tbl, table(mpfc_cr_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', time);
    fprintf('mPFC CR:\n')
    ranova(rm)

    tbl = table(state_fa_mat, pupil_fa_mat(:,1), 'VariableNames', {'state', 't0'});
    for c = 2:size(pupil_fa_mat,2)
        tbl = [tbl, table(pupil_fa_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', pt);
    fprintf('Pupil FA:\n')
    ranova(rm)

    s1_fa_mat = s1_fa_mat(:,t > 0 & t <= 5); 
    time = t(t > 0 & t <= 5);
    tbl = table(state_fa_mat, s1_fa_mat(:,1), 'VariableNames', {'state', 't0'});
    for c = 2:size(s1_fa_mat,2)
        tbl = [tbl, table(s1_fa_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', time);
    fprintf('S1 FA:\n')
    ranova(rm)

    mpfc_fa_mat = mpfc_fa_mat(:,t > 0 & t <= 5); 
    time = t(t > 0 & t <= 5);
    tbl = table(state_fa_mat, mpfc_fa_mat(:,1), 'VariableNames', {'state', 't0'});
    for c = 2:size(mpfc_fa_mat,2)
        tbl = [tbl, table(mpfc_fa_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', time);
    fprintf('mPFC FA:\n')
    ranova(rm)

    % pbfig = figure();
    % % tl = tiledlayout(1,4);
    % % for o = 1:length(outcomes)
    % %     axs(o) = nexttile;
    % pupil_baseline{k}{end}(pupil_baseline{k}{end} > 5) = nan;
    % hold on 
    % for k = 1:K 
    %     plot(repmat(k-1,size(pupil_baseline{k}{end},1),1)+(rand(size(pupil_baseline{k}{end}))-0.5)*0.1, pupil_baseline{k}{end}, 'o', 'MarkerFaceColor', cols(k,:), 'MarkerEdgeColor', [1,1,1])
    %     errorbar(repmat(k-1,size(pupil_baseline{k}{end},1),1), nanmean(pupil_baseline{k}{end}), ste(pupil_baseline{k}{end}), 'k.', 'LineWidth', 2, 'CapSize', 15)
    % end
    % % end
    % ylabel('Baseline Pupil Area (z-score)')
    % xlabel('State')
    % unifyYLimits(pbfig)

    % fprintf('Pupil baseline by state\n')
    % anova1([pupil_baseline{1}{end}, pupil_baseline{2}{end}, pupil_baseline{3}{end}])

    % sbfig = figure();
    % % tl = tiledlayout(1,4);
    % % for o = 1:length(outcomes)
    % %     axs(o) = nexttile;
    % s1_ne_baseline{k}{end}(s1_ne_baseline{k}{end} < -1) = nan;
    % hold on 
    % for k = 1:K 
    %     plot(repmat(k-1,size(s1_ne_baseline{k}{end},1),1)+(rand(size(s1_ne_baseline{k}{end}))-0.5)*0.1, s1_ne_baseline{k}{end}, 'o', 'MarkerFaceColor', cols(k,:), 'MarkerEdgeColor', [1,1,1])
    %     errorbar(repmat(k-1,size(s1_ne_baseline{k}{end},1),1), nanmean(s1_ne_baseline{k}{end}), ste(s1_ne_baseline{k}{end}), 'k.', 'LineWidth', 2, 'CapSize', 15)
    % end
    % % end
    % ylabel('Baseline s1 Area (z-score)')
    % xlabel('State')
    % unifyYLimits(sbfig)

    % fprintf('s1 baseline by state\n')
    % anova1([s1_ne_baseline{1}{end}, s1_ne_baseline{2}{end}, s1_ne_baseline{3}{end}])

    % mbfig = figure();
    % % tl = tiledlayout(1,4);
    % % for o = 1:length(outcomes)
    % %     axs(o) = nexttile;
    % mpfc_ne_baseline{k}{end}(mpfc_ne_baseline{k}{end} < -1) = nan;
    % hold on 
    % for k = 1:K 
    %     plot(repmat(k-1,size(mpfc_ne_baseline{k}{end},1),1)+(rand(size(mpfc_ne_baseline{k}{end}))-0.5)*0.1, mpfc_ne_baseline{k}{end}, 'o', 'MarkerFaceColor', cols(k,:), 'MarkerEdgeColor', [1,1,1])
    %     errorbar(repmat(k-1,size(mpfc_ne_baseline{k}{end},1),1), nanmean(mpfc_ne_baseline{k}{end}), ste(mpfc_ne_baseline{k}{end}), 'k.', 'LineWidth', 2, 'CapSize', 15)
    % end
    % % end
    % ylabel('Baseline mPFC Area (z-score)')
    % xlabel('State')
    % unifyYLimits(mbfig)

    % fprintf('mPFC Baseline by state\n')
    % anova1([mpfc_ne_baseline{1}{end}, mpfc_ne_baseline{2}{end}, mpfc_ne_baseline{3}{end}])
    saveas(pupil_fig, 'Figures/fig7.svg')
    saveas(pupil_fig, 'Figures/fig7.fig')
    saveas(s1_fig, 'Figures/fig8b.svg')
    saveas(s1_fig, 'Figures/fig8b.fig')
    saveas(mpfc_fig, 'Figures/fig8c.svg')
    saveas(mpfc_fig, 'Figures/fig8c.fig')

    sbfig = figure();
    tl = tiledlayout(1,4);
    for o = 1:length(outcomes)
        axs(o) = nexttile;
        hold on 
        for k = 1:K 
            plot(repmat(k-1,size(s1_ne_baseline{k}{o},1),1)+(rand(size(s1_ne_baseline{k}{o}))-0.5)*0.1, s1_ne_baseline{k}{o}, 'o', 'MarkerFaceColor', cols(k,:), 'MarkerEdgeColor', [1,1,1])
            errorbar(repmat(k-1,size(s1_ne_baseline{k}{o},1),1), nanmean(s1_ne_baseline{k}{o}), ste(s1_ne_baseline{k}{o}), 'k.', 'LineWidth', 2, 'CapSize', 15)
        end
        title(outcomes{o})
    end
    ylabel(tl, 'Baseline S1 NE (z-score)')
    xlabel(tl, 'State')
    unifyYLimits(sbfig)

    mbfig = figure();
    tl = tiledlayout(1,4);
    for o = 1:length(outcomes)
        axs(o) = nexttile;
        hold on 
        for k = 1:K 
            plot(repmat(k-1,size(mpfc_ne_baseline{k}{o},1),1)+(rand(size(mpfc_ne_baseline{k}{o}))-0.5)*0.1, mpfc_ne_baseline{k}{o}, 'o', 'MarkerFaceColor', cols(k,:), 'MarkerEdgeColor', [1,1,1])
            errorbar(repmat(k-1,size(mpfc_ne_baseline{k}{o},1),1), nanmean(mpfc_ne_baseline{k}{o}), ste(mpfc_ne_baseline{k}{o}), 'k.', 'LineWidth', 2, 'CapSize', 15)
        end
        title(outcomes{o})
    end
    ylabel(tl, 'Baseline mPFC NE (z-score)')
    xlabel(tl, 'State')
    unifyYLimits(mbfig)
    close all

    fprintf('Pupil baseline by state on hit\n')
    [~,tbl,~] = anova1([pupil_baseline{1}{1}, pupil_baseline{2}{1}, pupil_baseline{3}{1}])
    close all

    fprintf('Pupil baseline by state on miss\n')
    [~,tbl,~] = anova1([pupil_baseline{1}{2}, pupil_baseline{2}{2}, pupil_baseline{3}{2}])
    close all

    fprintf('Pupil baseline by state on cr\n')
    [~,tbl,~] = anova1([pupil_baseline{1}{3}, pupil_baseline{2}{3}, pupil_baseline{3}{3}])
    close all

    fprintf('Pupil baseline by state on fa\n')
    [~,tbl,~] = anova1([pupil_baseline{1}{4}, pupil_baseline{2}{4}, pupil_baseline{3}{4}])
    close all

    fprintf('mPFC baseline by state on hit\n')
    [~,tbl,~] = anova1([mpfc_ne_baseline{1}{1}, mpfc_ne_baseline{2}{1}, mpfc_ne_baseline{3}{1}])
    close all

    fprintf('mPFC baseline by state on miss\n')
    [~,tbl,~] = anova1([mpfc_ne_baseline{1}{2}, mpfc_ne_baseline{2}{2}, mpfc_ne_baseline{3}{2}])
    close all

    fprintf('mPFC baseline by state on cr\n')
    [~,tbl,~] = anova1([mpfc_ne_baseline{1}{3}, mpfc_ne_baseline{2}{3}, mpfc_ne_baseline{3}{3}])
    close all

    fprintf('mPFC baseline by state on fa\n')
    [~,tbl,~] = anova1([mpfc_ne_baseline{1}{4}, mpfc_ne_baseline{2}{4}, mpfc_ne_baseline{3}{4}])
    close all

    fprintf('S1 baseline by state on hit\n')
    [~,tbl,~] = anova1([s1_ne_baseline{1}{1}, s1_ne_baseline{2}{1}, s1_ne_baseline{3}{1}])
    close all

    fprintf('S1 baseline by state on miss\n')
    [~,tbl,~] = anova1([s1_ne_baseline{1}{2}, s1_ne_baseline{2}{2}, s1_ne_baseline{3}{2}])
    close all

    fprintf('S1 baseline by state on cr\n')
    [~,tbl,~] = anova1([s1_ne_baseline{1}{3}, s1_ne_baseline{2}{3}, s1_ne_baseline{3}{3}])
    close all

    fprintf('S1 baseline by state on fa\n')
    [~,tbl,~] = anova1([s1_ne_baseline{1}{4}, s1_ne_baseline{2}{4}, s1_ne_baseline{3}{4}])
    close all

    fprintf('Pupil by outcome state 1\n')
    [~,tbl,~] = anova1([pupil_baseline{1}{1}, pupil_baseline{1}{2}, pupil_baseline{1}{3}, pupil_baseline{1}{4}])
    close all

    fprintf('Pupil by outcome state 2\n')
    [~,tbl,~] = anova1([pupil_baseline{2}{1}, pupil_baseline{2}{2}, pupil_baseline{2}{3}, pupil_baseline{2}{4}])
    close all

    fprintf('Pupil by outcome state 3\n')
    [~,tbl,~] = anova1([pupil_baseline{3}{1}, pupil_baseline{3}{2}, pupil_baseline{3}{3}, pupil_baseline{3}{4}])
    close all

    fprintf('mPFC by outcome state 1\n')
    [~,tbl,~] = anova1([mpfc_ne_baseline{1}{1}, mpfc_ne_baseline{1}{2}, mpfc_ne_baseline{1}{3}, mpfc_ne_baseline{1}{4}])
    close all

    fprintf('mPFC by outcome state 2\n')
    [~,tbl,~] = anova1([mpfc_ne_baseline{2}{1}, mpfc_ne_baseline{2}{2}, mpfc_ne_baseline{2}{3}, mpfc_ne_baseline{2}{4}])
    close all

    fprintf('mPFC by outcome state 3\n')
    [~,tbl,~] = anova1([mpfc_ne_baseline{3}{1}, mpfc_ne_baseline{3}{2}, mpfc_ne_baseline{3}{3}, mpfc_ne_baseline{3}{4}])
    close all

    fprintf('S1 by outcome state 1\n')
    [~,tbl,~] = anova1([s1_ne_baseline{1}{1}, s1_ne_baseline{1}{2}, s1_ne_baseline{1}{3}, s1_ne_baseline{1}{4}])
    close all

    fprintf('S1 by outcome state 2\n')
    [~,tbl,~] = anova1([s1_ne_baseline{2}{1}, s1_ne_baseline{2}{2}, s1_ne_baseline{2}{3}, s1_ne_baseline{2}{4}])
    close all

    fprintf('S1 by outcome state 3\n')
    [~,tbl,~] = anova1([s1_ne_baseline{3}{1}, s1_ne_baseline{3}{2}, s1_ne_baseline{3}{3}, s1_ne_baseline{3}{4}])
    close all
end