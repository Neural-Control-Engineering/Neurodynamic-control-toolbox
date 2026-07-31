function fig6()

    Datastore = load('Combined-Datastore_created_14-Jan-2024.mat');
    data = filterTrials(Datastore.Datastore, 'recording_location', 'mPFC-S1');
    animals = fetchAnimals(data);
    model = readtable('glmhmm_K3_state_assignments_corrected.csv');
    model = model(strcmp(model.model, 'corrected'),:);
    model(cellfun(@isempty, data.photometry_ch1),:) = [];
    data(cellfun(@isempty, data.photometry_ch1),:) = [];
    sessions = unique(data.session_id);
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    rps = {[], [], []};
    stim_strengths = unique(data.stimulus_strength);
    for s = 1:length(sessions)
        tmp = data(strcmp(data.session_id, sessions{s}),:);
        model_tmp = model(strcmp(model.session, sessions{s}),:);
        states = unique(model_tmp.state);
        for ss = 1:length(states)
            stmp = tmp(model_tmp.state == states(ss),:);
            rp = nan(1,length(stim_strengths));
            for sss = 1:length(stim_strengths)
                strtmp = stmp(stmp.stimulus_strength == stim_strengths(sss),:);
                rp(sss) = (sum(strcmp(strtmp.categorical_outcome, 'Hit') | strcmp(strtmp.categorical_outcome, 'FA'))) / size(strtmp,1);
            end 
            rps{states(ss)+1} = [rps{states(ss)+1}; rp];
        end
    end 
    cols = distinguishable_colors(length(rps));
    fig = figure();
    hold on
    for i = 1:length(rps)
        semshade(rps{i}, 0.3, cols(i,:), cols(i,:), stim_strengths .* 10, 1)
    end
    xlabel('Stimulus Intensity (PSI)', 'FontSize', 16)
    ylabel('Response Probability', 'FontSize', 16)
    rp_mat = [];
    state_mat = [];
    for i = 1:length(rps)
        rp_mat = [rp_mat; rps{i}];
        state_mat = [state_mat; repmat(i-1,size(rps{i},1),1)];
    end
    tbl = table(state_mat, rp_mat(:,1), 'VariableNames', {'state', 't0'});
    for c = 2:size(rp_mat,2)
        tbl = [tbl, table(rp_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
    end
    rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', stim_strengths);
    fprintf('Response probability:\n')
    ranova(rm)
    saveas(fig, 'Figures/fig6d.fig')
    saveas(fig, 'Figures/fig6d.svg')

    sessions = unique(data.session_id);
    tmp_model = model(strcmp(model.session, sessions{6}),:);
    tmp_data = data(strcmp(data.session_id, sessions{6}),:);
    exampfig = figure();
    % tl = tiledlayout(2,1);
    % axs(1) = nexttile;
    plot(tmp_model.p_state0, 'b', 'LineWidth', 2, 'DisplayName', 'state 0')
    hold on; 
    plot(tmp_model.p_state1, 'r', 'LineWidth', 2, 'DisplayName', 'state 1')
    plot(tmp_model.p_state2, 'g', 'LineWidth', 2, 'DisplayName', 'state 2')
    legend()
    ylabel('State Probability', 'FontSize', 16)
    xlim([1,120])
    saveas(exampfig, 'Figures/fig6f.fig')
    saveas(exampfig, 'Figures/fig6f.svg')

    fracs = {[],[],[]};
    states = unique(model.state);
    for s = 1:length(sessions)
        tmp_model = model(strcmp(model.session, sessions{s}),:);
        for ss = 1:length(states)
            fracs{states(ss)+1} = [fracs{states(ss)+1}; sum(tmp_model.state == states(ss))/size(tmp_model,1)];
        end 
    end 
    ffig = figure(); 
    hold on;
    for i = 1:length(fracs)
        plot(zeros(size(fracs{i}))+(i-1)+(rand(size(fracs{i}))-0.5)*0.1, fracs{i}, 'o', 'MarkerFaceColor', cols(i,:), 'MarkerEdgeColor', [1,1,1])
    end
    errorbar(0:2, cellfun(@nanmean,fracs), cellfun(@ste,fracs), 'k.', 'CapSize', 15, 'LineWidth', 2)
    xticks(0:2)
    yticks([0,1])
    xlabel('State', 'FontSize', 16)
    ylabel('Fracion of trials per session', 'FontSize', 16)
    mat = [fracs{1}, fracs{2}, fracs{3}];
    fprintf('trials per session:\n')
    [p,tbl,stats] = anova1(mat)
    saveas(ffig, 'Figures/fig6e.fig')
    saveas(ffig, 'Figures/fig6e.svg')

    transitions = zeros(3,3);
    totals = zeros(3,1);
    for s = 1:length(sessions)
        tmp_model = model(strcmp(model.session, sessions{s}),:);
        for t = 1:(size(tmp_model,1)-1)
            transitions(tmp_model(t,:).state+1,tmp_model(t+1,:).state+1) = transitions(tmp_model(t,:).state+1,tmp_model(t+1,:).state+1) + 1;
            totals(tmp_model(t,:).state+1) = totals(tmp_model(t,:).state+1) + 1;
        end 
    end
    for t = 1:length(totals)
        transitions(t,:) = transitions(t,:) ./ totals(t);
    end
    tfig = figure();
    imagesc(0:2, 0:2, log(transitions));
    colorbar()
    xticks(0:2)
    yticks(0:2)
    xlabel('Current State', 'FontSize', 16)
    ylabel('Next State', 'FontSize', 16)
    cbar = colorbar();
    ylabel(cbar, 'log Transition Probability', 'FontSize', 16, 'Rotation', 270)
    saveas(tfig, 'Figures/fig6g.fig')
    saveas(tfig, 'Figures/fig6g.svg')

    fracs = {[],[],[]};
    states = unique(model.state);
    for s = 1:length(sessions)
        tmp_model = model(strcmp(model.session, sessions{s}),:);
        tmp_data = data(strcmp(model.session, sessions{s}),:);
        for ss = 1:length(states)
            stmp = tmp_data(tmp_model.state == states(ss),:);
            if ~isempty(stmp)
                fracs{states(ss)+1} = [fracs{states(ss)+1}; nanmean(stmp.response_time)];
            else
                fracs{states(ss)+1} = [fracs{states(ss)+1}; nan];
            end
        end 
    end 
    rtfig = figure(); 
    hold on;
    for i = 1:length(fracs)
        fracs{i}(fracs{i} > 1) = nan;
        plot(zeros(size(fracs{i}))+(i-1)+(rand(size(fracs{i}))-0.5)*0.1, fracs{i}, 'o', 'MarkerFaceColor', cols(i,:), 'MarkerEdgeColor', [1,1,1])
    end
    errorbar(0:2, cellfun(@nanmean,fracs), cellfun(@ste,fracs), 'k.', 'CapSize', 15, 'LineWidth', 2)
    xticks(0:2)
    yticks([0,1])
    xlabel('State', 'FontSize', 16)
    ylabel('Response Time (s)', 'FontSize', 16)
    ylim([0,1])
    yticks([0,1])
    mat = [fracs{1}, fracs{2}, fracs{3}];
    fprintf('Response time:\n')
    [p,tbl,stats] = anova1(mat)
    saveas(rtfig, 'Figures/fig6h.fig')
    saveas(rtfig, 'Figures/fig6h.svg')

    fracs = {[],[],[]};
    states = unique(model.state);
    for s = 1:length(sessions)
        tmp_model = model(strcmp(model.session, sessions{s}),:);
        tmp_data = data(strcmp(model.session, sessions{s}),:);
        for ss = 1:length(states)
            stmp = tmp_data(tmp_model.state == states(ss),:);
            if ~isempty(stmp)
                hr = (sum(strcmp(stmp.categorical_outcome, 'Hit'))+0.5) / ((sum(strcmp(stmp.categorical_outcome, 'Hit') | strcmp(stmp.categorical_outcome, 'Miss')))+1.0);
                far =( sum(strcmp(stmp.categorical_outcome, 'FA'))+0.5) / ((sum(strcmp(stmp.categorical_outcome, 'FA') | strcmp(stmp.categorical_outcome, 'CR')))+1.0);
                fracs{states(ss)+1} = [fracs{states(ss)+1}; -0.5 * (norminv(hr) + norminv(far));];
            else 
                fracs{states(ss)+1} = [fracs{states(ss)+1}; nan];
            end
        end 
    end 
    cfig = figure(); 
    hold on;
    for i = 1:length(fracs)
        plot(zeros(size(fracs{i}))+(i-1)+(rand(size(fracs{i}))-0.5)*0.1, fracs{i}, 'o', 'MarkerFaceColor', cols(i,:), 'MarkerEdgeColor', [1,1,1])
    end
    errorbar(0:2, cellfun(@nanmean,fracs), cellfun(@ste,fracs), 'k.', 'CapSize', 15, 'LineWidth', 2)
    xticks(0:2)
    xlabel('State', 'FontSize', 16)
    ylabel('Decision Criterion (s)', 'FontSize', 16)
    mat = [fracs{1}, fracs{2}, fracs{3}];
    [p,tbl,stats] = anova1(mat)
    saveas(cfig, 'Figures/fig6i.fig')
    saveas(cfig, 'Figures/fig6i.svg')

    % Cross-validation for the CORRECTED (column-routed) model. The legacy
    % glmhmm_cv_results.csv held the pre-correction fits (model=='New', pupil
    % still in the observation GLM), so 6B/6C were showing the superseded model.
    T = readtable('glmhmm_cv_corrected_full.csv');
    acc = T(T.K == 1 & strcmp(T.model, 'corrected'),:).accuracy;
    roc_auc = T(T.K == 1 & strcmp(T.model, 'corrected'),:).roc_auc;
    for k = 2:4
        acc = [acc, T(T.K == k & strcmp(T.model, 'corrected'),:).accuracy];
        roc_auc = [roc_auc, T(T.K == k & strcmp(T.model, 'corrected'),:).roc_auc];
    end
    acc_fig = figure();
    hold on;
    for i = 1:size(acc,2)
        plot(repmat(i,size(acc,1),1)+(rand(size(acc,1),1)-0.5)*0.1, acc(:,i), 'o', 'MarkerFaceColor', [0.5,0.5,0.5], 'MarkerEdgeColor', [1,1,1])
    end 
    errorbar(1:size(acc,2), mean(acc), ste(acc), 'k*-')
    xticks(1:4)
    xticklabels({'L', '2', '3', '4'})
    xlabel('States', 'FontSize', 16)
    ylabel('Accuracy', 'FontSize', 16)
    roc_auc_fig = figure();
    hold on;
    for i = 1:size(roc_auc,2)
        plot(repmat(i,size(roc_auc,1),1)+(rand(size(roc_auc,1),1)-0.5)*0.1, roc_auc(:,i), 'o', 'MarkerFaceColor', [0.5,0.5,0.5], 'MarkerEdgeColor', [1,1,1])
    end 
    errorbar(1:size(roc_auc,2), mean(roc_auc), ste(roc_auc), 'k*-')
    xticks(1:4)
    xticklabels({'L', '2', '3', '4'})
    xlabel('States', 'FontSize', 16)
    ylabel('ROC-AUC', 'FontSize', 16)
    saveas(acc_fig, 'Figures/fig6b.fig')
    saveas(acc_fig, 'Figures/fig6b.svg')
    saveas(roc_auc_fig, 'Figures/fig6c.fig')
    saveas(roc_auc_fig, 'Figures/fig6c.svg')

    % Per-animal weights from the corrected (column-routed) GLM-HMM: baseline
    % pupil enters ONLY the transition softmax, stimulus+bias enter ONLY the
    % choice GLM. The superseded glmhmm_K3_per_animal_params.json carried a
    % pupil term in its observation weights (the circularity R2 raised), so
    % pupil is plotted on its own axes here rather than beside the
    % observation weights -- they are parameters of different sub-models.
    jsonFileName = 'glmhmm_K3_per_animal_params_corrected.json';
    jsonStr = fileread(jsonFileName);
    jsonData = jsondecode(jsonStr);
    animals = fieldnames(jsonData.animals);
    nA = length(animals);
    stim = {[],[],[]};
    bias = {[],[],[]};
    pupil = {[],[],[]};
    labels = cell(1,3);
    for s = 1:3
        fld = sprintf('state_%i', s-1);
        labels{s} = jsonData.state_labels.(fld);
        for a = 1:nA
            A = jsonData.animals.(animals{a});
            stim{s}  = [stim{s};  A.observation_weights.(fld).stim];
            bias{s}  = [bias{s};  A.observation_weights.(fld).bias];
            pupil{s} = [pupil{s}; A.transition_pupil_weight.(fld)];
        end
    end
    cols = {'b', 'r', 'g'};

    wfig = figure('Position', [100, 100, 1000, 460]);
    set(wfig, 'PaperPositionMode', 'auto')   % otherwise saveas clips to paper size

    % --- left: observation weights (stimulus, bias) ---
    subplot(1,2,1); hold on;
    h = gobjects(1,3);
    for s = 1:3
        x0 = (s-1)*3 + 1;   % groups at 1-2, 4-5, 7-8
        h(s) = plot(repmat(x0,nA,1)+(rand(nA,1)-0.5)*0.2, stim{s}, 'o', 'MarkerFaceColor', cols{s}, 'MarkerEdgeColor', [1,1,1], 'MarkerSize', 10);
        plot(repmat(x0+1,nA,1)+(rand(nA,1)-0.5)*0.2, bias{s}, 'o', 'MarkerFaceColor', cols{s}, 'MarkerEdgeColor', [1,1,1], 'MarkerSize', 10)
        errorbar([x0, x0+1], mean([stim{s}, bias{s}]), ste([stim{s}, bias{s}]), 'k.', 'LineWidth', 2, 'CapSize', 15)
    end
    xlim([0.25, 8.75])
    plot(xlim, [0 0], 'k:')
    xticks([1:2, 4:5, 7:8])
    xticklabels({'Stimulus', 'Bias', 'Stimulus', 'Bias', 'Stimulus', 'Bias'})
    xtickangle(45)
    ylabel('Observation Weight', 'FontSize', 16)
    title('Choice GLM (stimulus + bias)', 'FontSize', 14)
    legend(h, labels, 'Location', 'southwest', 'FontSize', 11, 'Box', 'off')

    % --- right: pupil -> transition weights ---
    subplot(1,2,2); hold on;
    for s = 1:3
        plot(repmat(s,nA,1)+(rand(nA,1)-0.5)*0.2, pupil{s}, 'o', 'MarkerFaceColor', cols{s}, 'MarkerEdgeColor', [1,1,1], 'MarkerSize', 10)
    end
    errorbar(1:3, cellfun(@mean, pupil), cellfun(@ste, pupil), 'k.', 'LineWidth', 2, 'CapSize', 15)
    plot(xlim, [0 0], 'k:')
    xlim([0.5, 3.5])
    xticks(1:3)
    xticklabels(labels)
    xtickangle(45)
    ylabel('Pupil \rightarrow Transition Weight', 'FontSize', 16)
    title('Transition GLM (baseline pupil)', 'FontSize', 14)

    saveas(wfig, 'Figures/fig6j.fig')
    saveas(wfig, 'Figures/fig6j.svg')

end
