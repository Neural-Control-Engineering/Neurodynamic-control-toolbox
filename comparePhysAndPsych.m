data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
animals = fetchAnimals(data);
data(cellfun(@isempty, data.photometry_ch1),:) = [];
ssd_version = 'v2';
kstates = [2, 3, 4, 5, 6];
% data_versions = {'last_trial_behavior_no_bias', ... 
%     'spontaneous_mpfc_stim', ...
%     'spontaneous_s1_stim', ...
%     'spontaneous_pupil_stim'};
data_versions = {'last_trial_behavior_no_bias', ... 
    'spontaneous_pupil_stim'};
% data = rmDiscrepantTrials(data);
animals_v1 = [3316, 3258, 3133, 200, 199, 198, 197, 196, 180, 167, 152];
animals_v2 = [240, 241, 242, 243];
animals = animals_v2;

animal = 241;
k = 3;

fig = figure('Visible', 'on', 'WindowState', 'maximized');
hold on;
for dv = 1:length(data_versions)
    data_ver = data_versions{dv};
    fformat = {data_ver, 'state_Python2mat.mat'};
    results_dir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ssd_version, data_ver);
    tmp = filterTrials(data, 'animal', num2str(animal));
    if startsWith(data_ver, 'behvaior') || startsWith(data_ver, 'last_trial')
        tmp = removeFirstTrials(tmp);
    end
    % if endsWith(data_ver, 'outliers')
    %     tmp = tmp((tmp.pupil_base_before_stimulus > -6 & tmp.pupil_base_before_stimulus < 6),:);
    % end
    fname = sprintf('%s%i_%s_%i%s', results_dir, animal, fformat{1}, k, fformat{2});
    subplot(length(data_versions), 4, (dv-1)*4+1)
    hold on
    plot_psycho_curves_states(fname, tmp, num2str(animal), k, data_ver);
    xlabel('Stimulus Strength (PSI)', 'FontSize', 14, 'FontWeight', 'bold')
    ylabel('Performance', 'FontSize', 14, 'FontWeight', 'bold')
    plot_phys_by_states(fname, tmp, num2str(animal), k, length(data_versions), 4, (dv-1)*4+2)
    annotation('textbox', [0.4, 0.87, 0.1, 0.1], 'String', 'Prev. Trial Behavior + Stim. Strength', 'FontSize', 16)
    annotation('textbox', [0.43, 0.4, 0.1, 0.1], 'String', 'Pupil Area + Stim. Strength', 'FontSize', 16)
end

% for dv = 1:length(data_versions)
%     data_ver = data_versions{dv};
%     fformat = {data_ver, 'state_Python2mat.mat'};
%     results_dir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ssd_version, data_ver);
%     tmp = filterTrials(data, 'animal', num2str(animal));
%     if startsWith(data_ver, 'behvaior') || startsWith(data_ver, 'last_trial')
%         tmp = removeFirstTrials(tmp);
%     end
%     fname = sprintf('%s%i_%s_%i%s', results_dir, animal, fformat{1}, k, fformat{2});
%     % dilationByState(tmp, fname, k, data_ver)
%     baselinePupilByState(tmp, fname, k, data_ver)
% end

% [base_fig, base_axs] = baselineBarGraphs(data, k, data_versions, animal);
% [evoked_fig, evoked_axs] = evokedBarGraphs(data, k, data_versions, animal);

function [fig, axs] = evokedBarGraphs(data, k, data_versions, animal);
    fig = figure('Visible', 'on', 'WindowState', 'maximized');
    axs = zeros(2,3);
    tl = tiledlayout(2,3,'TileSpacing','Compact');
    for r = 1:2
        for c = 1:3
            axs(r,c) = nexttile;
        end
    end
    dilationByState(data, k, data_versions, animal, axs(:,1))
    increaseInNeByState(data, k, data_versions, animal, axs(:,2:3))
    axes(axs(1,2))
    title('Prev. Trial Behavior + Stim. Strength', 'FontSize', 14)
    axes(axs(2,2))
    title('Pupil Area + Stim. Strength', 'FontSize', 14)
    for c = 1:3
        ys = zeros(2,2);
        for r = 1:2 
            axes(axs(r,c))
            ys(r,:) = ylim;
        end
        for r = 1:2 
            axes(axs(r,c))
            ylim([min(ys(:,1))-0.05, max(ys(:,2))+0.05])
        end
    end
        
    % 242 - 3 states 
    % axes(axs(1,1))
    % ylim([-0.5,1.2])
    % axes(axs(2,1))
    % ylim([-0.5,1.2])
    % axes(axs(1,3))
    % ylim([-0.3,0.7])
    % axes(axs(2,3))
    % ylim([-0.3,0.7])
    % 240 - 4 states 
    % axes(axs(1,1))
    % ylim([-1,1])
    % axes(axs(2,1))
    % ylim([-1,1])
    % axes(axs(1,2))
    % ylim([-0.3,0.3])
    % axes(axs(2,2))
    % ylim([-0.3,0.3])
    % axes(axs(1,3))
    % ylim([-0.3,0.5])
    % axes(axs(2,3))
    % ylim([-0.3,0.5])
end

function [fig, axs] = baselineBarGraphs(data, k, data_versions, animal)
    fig = figure('Visible', 'on', 'WindowState', 'maximized');
    axs = zeros(2,3);
    tl = tiledlayout(2,3,'TileSpacing','Compact');
    for r = 1:2
        for c = 1:3
            axs(r,c) = nexttile;
        end
    end
    baselinePupilByState(data, k, data_versions, animal, axs(:,1))
    baselineNeByState(data, k, data_versions, animal, axs(:,2:3))
    axes(axs(1,2))
    title('Prev. Trial Behavior + Stim. Strength', 'FontSize', 16)
    axes(axs(2,2))
    title('Pupil Area + Stim. Strength', 'FontSize', 16)
    for c = 1:3
        ys = zeros(2,2);
        for r = 1:2 
            axes(axs(r,c))
            ys(r,:) = ylim;
        end
        for r = 1:2 
            axes(axs(r,c))
            ylim([min(ys(:,1))-0.05, max(ys(:,2))+0.05])
        end
    end
    % axes(axs(1,1))
    % ylim([-1,1])
    % axes(axs(2,1))
    % ylim([-1,1])
    % axes(axs(1,2))
    % % ylim([-1.2,1.2])
    % % axes(axs(2,2))
    % % ylim([-1.2,1.2])
    % axes(axs(1,3))
    % ylim([-0.5,0.3])
    % axes(axs(2,3))
    % ylim([-0.5,0.3])
    % axes(axs(2,2))
    % ylim([-1.2,0.2])
    % axes(axs(2,3))
    % ylim([-0.5,0.3])
end

function plot_psycho_curves_states(filename, data, animal, k, data_version)
    % identifies all sessions in which a particular state occurs, generates a 
    % psychometric curve for that session-state pair, then averages psychometric 
    % curves of a particular state across sessions 
    results = load(filename);
    strengths = [0, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0];
    states = 0:k-1;
    cols = distinguishable_colors(length(states));

    for i = states 
        tmp = data(results.predicted_states == i,:);
        if ~isempty(tmp)
            sessions = unique(tmp.session_id);
            mat = nan(size(sessions,1), length(strengths));
            for sesh = 1:length(sessions)
                session = filterTrials(tmp, 'session_id', sessions{sesh});
                sesh_mat = nan(size(session,1), length(strengths));
                for trial = 1:size(session,1)
                    ind = find(strengths == session.stimulus_strength(trial));
                    if strcmp(session.categorical_outcome{trial}, 'Hit') || strcmp(session.categorical_outcome{trial}, 'CR')
                        sesh_mat(trial, ind) = 1;
                    else
                        sesh_mat(trial, ind) = 0;
                    end
                end
                mat(sesh,:) = nansum(sesh_mat,1) ./ sum(~isnan(sesh_mat),1);
            end
            n = length(sessions);
            try
                semshade(mat(:,2:end), 0.3, cols(i+1, :), cols(i+1,:), strengths(2:end) .* 10, 1, sprintf('State %i (n=%i)', i, n));
            catch
                plot(strengths(2:end) .* 10, mat(2:end), 'DisplayName', sprintf('State %i (n=%i)', i, n))
            end
            hold on
        end
    end
    % xlabel('Stimulus Strength (x10 PSI)')
    % ylabel('Performance')
    % legend()

    lg = legend('location','southeast');
    fontsize(lg, 10, 'points');
    % xlabel('Stimulus Strength (PSI)')
    % ylabel('Accuracy')
    % title(sprintf('%s, %s - Accuracy: %.3f', animal, strrep(data_version, '_', '-'), mean(results.accuracy)))
    % ylim([0,1.05])
    % saveas(fig, sprintf('%s%s_%istates.png', outdir, animal,length(states)))
    % saveas(fig, sprintf('%s%s_%istates.svg', outdir, animal,length(states)))
    % saveas(fig, sprintf('%s%s_%istates.fig', outdir, animal,length(states)))
    % close
end

function data = removeFirstTrials(data)
    sessions = unique(data.session_id);
    first_trials = zeros(1,length(sessions));
    for s = 1:length(sessions)
        session = sessions{s};
        trials = find(data.session_id == session);
        first_trials(s) = min(trials);
    end
    data(first_trials, :) = [];
end


function plot_phys_by_states(filename, data, animal, k, nrows, ncols, si)
    results = load(filename);
    
    states = 0:k-1;
    tbounds = [-0.5, 6.0];
    cols = distinguishable_colors(length(states));

    for i = states
        tmp = data(results.predicted_states == i,:);
        if ~isempty(tmp)
            [ch1, ch2, t] = avg_photo_traces(tmp, tbounds);
            % keyboard
            n = size(tmp,1);
            subplot(nrows,ncols,si)
            hold on 
            try
                semshade(ch1(:,2:end-1), 0.3, cols(i+1,:), cols(i+1,:), t(2:end-1), 1, sprintf('State %i (n=%i)', i, n));
            catch
                % keyboard
                plot(t, ch1, 'DisplayName', sprintf('State %i (n=%i)', i, n))
            end
            xlim([tbounds(1), tbounds(2)])
            subplot(nrows,ncols,si+1)
            hold on 
            try
                semshade(ch2(:,2:end-1), 0.3, cols(i+1,:), cols(i+1,:), t(2:end-1), 1, sprintf('State %i (n=%i)', i, n));
            catch
                % keyboard
                plot(t, ch2, 'DisplayName', sprintf('State %i (n=%i)', i, n))
            end
            xlim([tbounds(1), tbounds(2)])
            [pupil, t] = avg_pupil_traces(tmp, [tbounds(1)-0.1, tbounds(2)+0.1]);
            % keyboard
            subplot(nrows,ncols,si+2)
            hold on
            try
                semshade(pupil(:,2:end-1), 0.3, cols(i+1, :), cols(i+1, :), t(2:end-1), 1, sprintf('State %i (n=%i)', i, n));
            catch
                % keyboard
                plot(t, pupil, 'DisplayName', sprintf('State %i (n=%i)', i, n));
            end
            xlim([tbounds(1), tbounds(2)])
            ch1_region = tmp.photometry_region_ch1{1,1};
            ch2_region = tmp.photometry_region_ch2{1,1};
        end
    end
    subplot(nrows, ncols, si)
    % ylabel(sprintf('%s', ch1_region))
    ylabel('mPFC NE', 'FontSize', 14, 'FontWeight', 'bold')
    xlabel('Time (s)', 'FontSize', 14, 'FontWeight', 'bold')
    ylim1 = ylim;
    lg = legend('location', 'northwest');
    fontsize(lg, 10, 'points');
    subplot(nrows, ncols, si+1)
    % ylabel(sprintf('%s', ch2_region))
    ylabel('S1 NE', 'FontSize', 14, 'FontWeight', 'bold')
    xlabel('Time (s)', 'FontSize', 14, 'FontWeight', 'bold')
    ylim2 = ylim;

    subplot(nrows, ncols, si)
    plot([0,0],[min(horzcat(ylim1,ylim2)), max(horzcat(ylim1,ylim2))], 'k:', 'HandleVisibility','off')
    ylim([min(horzcat(ylim1,ylim2)), max(horzcat(ylim1,ylim2))])
    subplot(nrows, ncols, si+1)
    plot([0,0],[min(horzcat(ylim1,ylim2)), max(horzcat(ylim1,ylim2))], 'k:', 'HandleVisibility','off')
    ylim([min(horzcat(ylim1,ylim2)), max(horzcat(ylim1,ylim2))])
    subplot(nrows, ncols, si+2)
    ylims = ylim;
    ylabel('Pupil Area', 'FontSize', 14, 'FontWeight', 'bold')
    xlabel('Time (s)', 'FontSize', 14, 'FontWeight', 'bold')
    plot([0,0],[ylims(1), ylims(2)], 'k:', 'HandleVisibility','off')
    % saveas(fig, sprintf('%s%s_%istates.png', outdir, animal,length(states)))
    % saveas(fig, sprintf('%s%s_%istates.svg', outdir, animal,length(states)))
    % saveas(fig, sprintf('%s%s_%istates.fig', outdir, animal,length(states)))
    % close
end

function [ch1mat, ch2mat, time] = avg_photo_traces(data, tbounds, alignTo)
    % generates averages of photometry traces 
    if ~exist('alignTo', 'var')
        starts = data.stimulus_time;
    elseif strcmp(alignTo, 'stimulus')
        starts = data.stimulus_time;
    elseif strcmp(alignTo, 'response')
        starts = data.stimulus_time + data.response_time;
        data(isnan(starts),:) = [];
        starts = starts(~isnan(starts));
    else
        starts = data.stimulus_time;
    end
    Fss = getFs(data, 'photometry_ch1');
    ch1mat = zeros(size(data,1), round(max(Fss)*diff(tbounds)));
    ch2mat = ch1mat;
    time = linspace(tbounds(1), tbounds(2), round(max(Fss)*diff(tbounds)));

    for i = 1:size(data,1)
        t = data.photometry_ch1{i,1}(:,1) - starts(i);
        ch1 = data.photometry_ch1{i,1}(:,2);
        ch2 = data.photometry_ch2{i,1}(:,2);
        ch1 = ch1(t > tbounds(1) & t < tbounds(2));
        ch2 = ch2(t > tbounds(1) & t < tbounds(2));
        t = t(t > tbounds(1) & t < tbounds(2));
        % using interp1 to avoid issues with differing sample rates
        ch1mat(i,:) = interp1(t, ch1, time);
        ch2mat(i,:) = interp1(t, ch2, time);
    end
end

function [pupil, time] = avg_pupil_traces(data, tbounds, alignTo)
    % generates averages of pupil traces
    if ~exist('alignTo', 'var')
        starts = data.stimulus_time;
    elseif strcmp(alignTo, 'stimulus')
        starts = data.stimulus_time;
    elseif strcmp(alignTo, 'response')
        starts = data.stimulus_time + data.response_time;
        data(isnan(starts), :) = [];
        starts = starts(~isnan(starts));
    else
        starts = data.stimulus_time;
    end
    Fs = 1 / (data.pupil_area{1,1}(2,1)-data.pupil_area{1,1}(1,1));
    pupil = nan(size(data,1), round(Fs*diff(tbounds)));
    time = linspace(tbounds(1), tbounds(2), round(Fs*diff(tbounds)));

    for i = 1:size(data,1)
        t = data.pupil_area{i,1}(:,1) - starts(i);
        p = data.pupil_area{i,1}(:,2);
        p = p(t >= tbounds(1) & t <= tbounds(2));
        t = t(t >= tbounds(1) & t <= tbounds(2));
        try
            % again with the sample rate issues
            pupil(i,:) = interp1(t,p,time);
        end
    end
end

function dilationByState(data, k, data_versions, animal, axs)
    data = filterTrials(data, 'animal', num2str(animal));
    % fig = figure();
    % tl = tiledlayout(length(data_versions),1);
    % axs = zeros(length(data_versions),1);
    % for i = 1:length(data_versions)
    %     axs(i) = nexttile;
    % end
    states = 0:k-1;
    cols = distinguishable_colors(length(states));
    for dv = 1:length(data_versions)
        data_ver = data_versions{dv};
        fformat = {data_ver, 'state_Python2mat.mat'};
        results_dir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', 'v2', data_ver);
        fname = sprintf('%s%i_%s_%i%s', results_dir, animal, fformat{1}, k, fformat{2});
        if startsWith(data_ver, 'behvaior') || startsWith(data_ver, 'last_trial')
           tmp = removeFirstTrials(data);
        else
           tmp = data;
        end
        results = load(fname);
        offset = -0.2;
        for i = states
            stmp = tmp(results.predicted_states == i,:);
            if ~isempty(stmp)
                pupilDilationByOutcome(stmp, offset, axs(dv), cols(i+1,:))
                offset = offset + 0.2;
            end
        end
    end
end

function increaseInNeByState(data, k, data_versions, animal, axs)
    data = filterTrials(data, 'animal', num2str(animal));
    % fig = figure();
    % tl = tiledlayout(length(data_versions),2);
    % axs = zeros(length(data_versions),2);
    % for i = 1:length(data_versions)
    %     axs(i,1) = nexttile;
    %     axs(i,2) = nexttile;
    % end
    states = 0:k-1;
    cols = distinguishable_colors(length(states));
    for dv = 1:length(data_versions)
        data_ver = data_versions{dv};
        fformat = {data_ver, 'state_Python2mat.mat'};
        results_dir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', 'v2', data_ver);
        fname = sprintf('%s%i_%s_%i%s', results_dir, animal, fformat{1}, k, fformat{2});
        if startsWith(data_ver, 'behvaior') || startsWith(data_ver, 'last_trial')
           tmp = removeFirstTrials(data);
        else
           tmp = data;
        end
        results = load(fname);
        offset = -0.2;
        for i = states
            stmp = tmp(results.predicted_states == i,:);
            if ~isempty(stmp)
                increaseInNE(stmp, offset, axs(dv,:), cols(i+1,:))
                offset = offset + 0.2;
            end
        end
    end
end

function baselineNeByState(data, k, data_versions, animal, axs)
    data = filterTrials(data, 'animal', num2str(animal));
    % fig = figure();
    % tl = tiledlayout(length(data_versions),2);
    % axs = zeros(length(data_versions),2);
    % for i = 1:length(data_versions)
    %     axs(i,1) = nexttile;
    %     axs(i,2) = nexttile;
    % end
    states = 0:k-1;
    cols = distinguishable_colors(length(states));
    for dv = 1:length(data_versions)
        data_ver = data_versions{dv};
        fformat = {data_ver, 'state_Python2mat.mat'};
        results_dir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', 'v2', data_ver);
        fname = sprintf('%s%i_%s_%i%s', results_dir, animal, fformat{1}, k, fformat{2});
        if startsWith(data_ver, 'behvaior') || startsWith(data_ver, 'last_trial')
           tmp = removeFirstTrials(data);
        else
           tmp = data;
        end
        results = load(fname);
        offset = -0.2;
        for i = states
            stmp = tmp(results.predicted_states == i,:);
            if ~isempty(stmp)
                baselineNeByOutcome(stmp, offset, axs(dv,:), cols(i+1,:))
                offset = offset + 0.2;
            end
        end
    end
end

function baselinePupilByState(data, k, data_versions, animal, axs)
    data = filterTrials(data, 'animal', num2str(animal));
    % fig = figure();
    % tl = tiledlayout(length(data_versions),1);
    % axs = zeros(length(data_versions),1);
    % for i = 1:length(data_versions)
    %     axs(i) = nexttile;
    % end
    states = 0:k-1;
    cols = distinguishable_colors(length(states));
    for dv = 1:length(data_versions)
        data_ver = data_versions{dv};
        fformat = {data_ver, 'state_Python2mat.mat'};
        results_dir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', 'v2', data_ver);
        fname = sprintf('%s%i_%s_%i%s', results_dir, animal, fformat{1}, k, fformat{2});
        if startsWith(data_ver, 'behvaior') || startsWith(data_ver, 'last_trial')
           tmp = removeFirstTrials(data);
        else
           tmp = data;
        end
        results = load(fname);
        offset = -0.2;
        for i = states
            stmp = tmp(results.predicted_states == i,:);
            if ~isempty(stmp)
                baselinePupilByOutcome(stmp, offset, axs(dv), cols(i+1,:))
                offset = offset + 0.2;
            end
        end
    end
end

function pupilDilationByOutcome(data, offset, ax, c)
    % outcomes = unique(data.categorical_outcome);
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    dilations = zeros(2,length(outcomes));
    for o = 1:length(outcomes)
        outcome = outcomes{o};
        tmp = filterTrials(data, 'categorical_outcome', outcome);
        if ~isempty(tmp)
            [pupil, ~] = avg_pupil_traces(tmp, [0,6.0]);
            [baseline, ~] = avg_pupil_traces(tmp, [-0.5,0.0], 'stimulus');
            dilations(1,o) = nanmean(nanmean(pupil))-nanmean(nanmean(baseline));
            dilations(2,o) = nanstd(nanmean(pupil,2)-nanmean(baseline,2)) / size(pupil,1);
        else
            dilations(1,o) = nan;
            dilations(2,o) = nan;
        end
    end
    axes(ax)
    hold on
    errorbar([1:size(dilations,2)]+offset, dilations(1,:), dilations(2,:), '.', 'Color', c)
    bar([1:size(dilations,2)]+offset, dilations(1,:), 'FaceColor', c, 'BarWidth', 0.15)
    action_outcomes = {{'Hit', 'FA'}, {'Miss', 'CR'}};
    action_dilations = zeros(2,length(action_outcomes));
    for ao = 1:length(action_outcomes)
        outcome = action_outcomes{ao};
        tmp = filterTrials(data, 'categorical_outcome', outcome);
        if ~isempty(tmp)
            [pupil, ~] = avg_pupil_traces(tmp, [0,6.0], 'stimulus');
            [baseline, ~] = avg_pupil_traces(tmp, [-0.5,0.0], 'stimulus');
            action_dilations(1,ao) = nanmean(nanmean(pupil))-nanmean(nanmean(baseline));
            action_dilations(2,ao) = nanstd(nanmean(pupil,2)-nanmean(baseline,2)) / size(pupil,1);
        else
            action_dilations(1,ao) = nan;
            action_dilations(2,ao) = nan;
        end
    end
    x = size(dilations,2)+2:size(dilations,2)+1+size(action_dilations,2);
    x = x + offset;
    errorbar(x, action_dilations(1,:), action_dilations(2,:), '.', 'Color', c)
    bar(x, action_dilations(1,:), 'FaceColor', c, 'BarWidth', 0.15)
    xticks([1:size(dilations,2), x])
    labels = [outcomes, {'Responded', 'Withheld'}];
    xticklabels(labels)
    ylabel('Mean Pupil Dilation (z-score)', 'FontSize', 16)
end
        

function baselinePupilByOutcome(data, offset, ax, c)
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    baselines = zeros(2,length(outcomes));
    for o = 1:length(outcomes)
        outcome = outcomes{o};
        tmp = filterTrials(data, 'categorical_outcome', outcome);
        if ~isempty(tmp)
            [baseline, ~] = avg_pupil_traces(tmp, [-0.5,0.0], 'stimulus');
            baselines(1,o) = nanmean(nanmean(baseline));
            baselines(2,o) = nanstd(nanmean(baseline,2)) / size(baseline,1);
        else
            baselines(1,o) = nan;
            baselines(2,o) = nan;
        end
    end
    axes(ax)
    hold on
    errorbar([1:size(baselines,2)]+offset, baselines(1,:), baselines(2,:), '.', 'Color', c)
    bar([1:size(baselines,2)]+offset, baselines(1,:), 'FaceColor', c, 'BarWidth', 0.15)
    action_outcomes = {{'Hit', 'FA'}, {'Miss', 'CR'}};
    action_baselines = zeros(2,length(action_outcomes));
    for ao = 1:length(action_outcomes)
        outcome = action_outcomes{ao};
        tmp = filterTrials(data, 'categorical_outcome', outcome);
        if ~isempty(tmp)
            [baseline, ~] = avg_pupil_traces(tmp, [-0.5,0.0], 'stimulus');
            action_baselines(1,ao) = nanmean(nanmean(baseline));
            action_baselines(2,ao) = nanstd(nanmean(baseline,2)) / size(baseline,1);
        else
            action_baselines(1,ao) = nan;
            action_baselines(2,ao) = nan;
        end
    end
    x = size(baselines,2)+2:size(baselines,2)+1+size(action_baselines,2);
    x = x + offset;
    errorbar(x, action_baselines(1,:), action_baselines(2,:), '.', 'Color', c)
    bar(x, action_baselines(1,:), 'FaceColor', c, 'BarWidth', 0.15)
    xticks([1:size(baselines,2), x])
    labels = [outcomes, {'Responded', 'Withheld'}];
    xticklabels(labels)
    ylabel('Mean Baseline Pupil Area (z-score)', 'FontSize', 16)
end

function baselineNeByOutcome(data, offset, ax, c)
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    ch1b = zeros(2,length(outcomes));
    ch2b = zeros(2,length(outcomes));
    for o = 1:length(outcomes)
        outcome = outcomes{o};
        tmp = filterTrials(data, 'categorical_outcome', outcome);
        if ~isempty(tmp)
            [ch1, ch2, ~] = avg_photo_traces(tmp, [-0.5,0.0], 'stimulus');
            ch1b(1,o) = nanmean(nanmean(ch1));
            ch1b(2,o) = nanstd(nanmean(ch1,2)) / size(ch1,1);
            ch2b(1,o) = nanmean(nanmean(ch2));
            ch2b(2,o) = nanstd(nanmean(ch2,2)) / size(ch2,1);
        else
            ch1b(1,o) = nan;
            ch1b(2,o) = nan;
            ch2b(1,o) = nan;
            ch2b(2,o) = nan;
        end
    end
    axes(ax(1))
    hold on
    errorbar([1:size(ch1b,2)]+offset, ch1b(1,:), ch1b(2,:), '.', 'Color', c)
    bar([1:size(ch1b,2)]+offset, ch1b(1,:), 'FaceColor', c, 'BarWidth', 0.15)
    axes(ax(2))
    hold on
    errorbar([1:size(ch2b,2)]+offset, ch2b(1,:), ch2b(2,:), '.', 'Color', c)
    bar([1:size(ch2b,2)]+offset, ch2b(1,:), 'FaceColor', c, 'BarWidth', 0.15)
    % action trials
    action_outcomes = {{'Hit', 'FA'}, {'Miss', 'CR'}};
    action_ch1b = zeros(2,length(action_outcomes));
    action_ch2b = zeros(2,length(action_outcomes));
    for ao = 1:length(action_outcomes)
        outcome = action_outcomes{ao};
        tmp = filterTrials(data, 'categorical_outcome', outcome);
        if ~isempty(tmp)
            [ch1, ch2, ~] = avg_photo_traces(tmp, [-0.5,0.0], 'stimulus');
            action_ch1b(1,ao) = nanmean(nanmean(ch1));
            action_ch1b(2,ao) = nanstd(nanmean(ch1,2)) / size(ch1,1);
            action_ch2b(1,ao) = nanmean(nanmean(ch2));
            action_ch2b(2,ao) = nanstd(nanmean(ch2,2)) / size(ch2,1);
        else
            action_ch1b(1,ao) = nan;
            action_ch1b(2,ao) = nan;
            action_ch2b(1,ao) = nan;
            action_ch2b(2,ao) = nan;
        end
    end
    axes(ax(1))
    x = size(ch1b,2)+2:size(ch1b,2)+1+size(action_ch1b,2);
    x = x + offset;
    errorbar(x, action_ch1b(1,:), action_ch1b(2,:), '.', 'Color', c)
    bar(x, action_ch1b(1,:), 'FaceColor', c, 'BarWidth', 0.15)
    xticks([1:size(ch1b,2), x])
    labels = [outcomes, {'Responded', 'Withheld'}];
    xticklabels(labels)
    xtickangle(45)
    ylabel('Mean Baseline mPFC NE (z-score)', 'FontSize', 14)
    axes(ax(2))
    x = size(ch2b,2)+2:size(ch2b,2)+1+size(action_ch2b,2);
    x = x + offset;
    errorbar(x, action_ch2b(1,:), action_ch2b(2,:), '.', 'Color', c)
    bar(x, action_ch2b(1,:), 'FaceColor', c, 'BarWidth', 0.15)
    xticks([1:size(ch2b,2), x])
    labels = [outcomes, {'Responded', 'Withheld'}];
    xticklabels(labels)
    xtickangle(45)
    ylabel('Mean Baseline S1 NE (z-score)', 'FontSize', 14)
end    

function increaseInNE(data, offset, ax, c)
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    mpfc = zeros(2,length(outcomes));
    s1 = mpfc;
    for o = 1:length(outcomes)
        outcome = outcomes{o};
        tmp = filterTrials(data, 'categorical_outcome', outcome);
        if ~isempty(tmp)
            [ch1, ch2, ~] = avg_photo_traces(tmp, [0,4.0], 'stimulus');
            [ch1b, ch2b, ~] = avg_photo_traces(tmp, [-0.5,0.0], 'stimulus');
            mpfc(1,o) = nanmean(nanmean(ch1))-nanmean(nanmean(ch1b));
            mpfc(2,o) = nanstd(nanmean(ch1,2)-nanmean(ch1,2)) / size(ch1,1);
            s1(1,o) = nanmean(nanmean(ch2))-nanmean(nanmean(ch2b));
            s1(2,o) = nanstd(nanmean(ch2,2)-nanmean(ch2b,2)) / size(ch2,1);
        else
            mpfc(1,o) = nan;
            mpfc(2,o) = nan;
            s1(1,o) = nan;
            s1(2,o) = nan;
        end
    end
    action_outcomes = {{'Hit', 'FA'}, {'Miss', 'CR'}};
    action_mpfc = zeros(2,length(action_outcomes));
    action_s1 = action_mpfc;
    for ao = 1:length(action_outcomes)
        outcome = action_outcomes{ao};
        tmp = filterTrials(data, 'categorical_outcome', outcome);
        if ~isempty(tmp)
            [ch1, ch2, ~] = avg_photo_traces(tmp, [0,6.0], 'stimulus');
            [ch1b, ch2b, ~] = avg_photo_traces(tmp, [-0.5,0.0], 'stimulus');
            action_mpfc(1,ao) = nanmean(nanmean(ch1))-nanmean(nanmean(ch1b));
            action_mpfc(2,ao) = nanstd(nanmean(ch1,2)-nanmean(ch1b,2)) / size(ch1,1);
            action_s1(1,ao) = nanmean(nanmean(ch2))-nanmean(nanmean(ch2b));
            action_s1(2,ao) = nanstd(nanmean(ch2,2)-nanmean(ch2b,2)) / size(ch2,1);
        else
            action_mpfc(1,ao) = nan;
            action_mpfc(2,ao) = nan;
            action_s1(1,ao) = nan;
            action_s1(2,ao) = nan;
        end
    end
    x = size(mpfc,2)+2:size(mpfc,2)+1+size(action_mpfc,2);
    x = x + offset;
    axes(ax(1))
    hold on
    errorbar([1:size(mpfc,2)]+offset, mpfc(1,:), mpfc(2,:), '.', 'Color', c)
    bar([1:size(mpfc,2)]+offset, mpfc(1,:), 'FaceColor', c, 'BarWidth', 0.15)
    errorbar(x, action_mpfc(1,:), action_mpfc(2,:), '.', 'Color', c)
    bar(x, action_mpfc(1,:), 'FaceColor', c, 'BarWidth', 0.15)
    xticks([1:size(mpfc,2), x])
    labels = [outcomes, {'Responded', 'Withheld'}];
    xticklabels(labels)
    xtickangle(45)
    ylabel('Mean Evoked mPFC NE (z-score)', 'FontSize', 14)
    axes(ax(2))
    hold on
    errorbar([1:size(s1,2)]+offset, s1(1,:), s1(2,:), '.', 'Color', c)
    bar([1:size(s1,2)]+offset, s1(1,:), 'FaceColor', c, 'BarWidth', 0.15)
    errorbar(x, action_s1(1,:), action_s1(2,:), '.', 'Color', c)
    bar(x, action_s1(1,:), 'FaceColor', c, 'BarWidth', 0.15)
    xticks([1:size(s1,2), x])
    labels = [outcomes, {'Responded', 'Withheld'}];
    xticklabels(labels)
    xtickangle(45)
    ylabel('Mean Evoked S1 NE (z-score)', 'FontSize', 14)
end