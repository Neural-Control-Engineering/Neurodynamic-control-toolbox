function fig7f_alt(data, k, data_ver, ssd_version, psychver, animals)
    lumpByResponseProb(data_ver, ssd_version, psychver, animals, data, k);
end

function lumpByResponseProb(data_ver, ssd_version, psychver, animals, data, k)
    % set paths 
    fformat = {data_ver, 'state_Python2mat.mat'};
    base_path = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ssd_version, data_ver);
    outdir = strcat(base_path, 'figures/phys_by_state/', psychver, '/');
    if ~exist(outdir, 'dir')
        mkdir(outdir)
    end

    if startsWith(data_ver, 'behvaior') || startsWith(data_ver, 'last_trial')
        data = removeFirstTrials(data);
    end

    % for single number of states, get the states ordered by average response probability
    % in each state
    mrps = zeros(length(animals), k);
    ordered_states = mrps;
    for a = 1:length(animals)
        tmp = filterTrials(data, 'animal', num2str(animals(a)));
        filename = sprintf('%s%i_%s_%i%s', base_path, animals(a), fformat{1}, k, fformat{2});
        mrps(a,:) = meanResponseProb(filename, tmp, k);
        [~, inds] = sort(mrps(a,:));
        ordered_states(a,:) = inds - 1;
    end

    % average psychometric curves for each animal in each ordered state (starting with lowest)
    % figure('Position', [ 1151, 1516, 1830, 404])
    
    tbounds = [-0.5,6.0];
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    all_ne = {};
    for s = 1:k
        cols = distinguishable_colors(k);
        state_rp = [];
        ne_ch1 = {[], [], [], []};
        ne_ch2 = {[], [], [], []};
        pupil = {[], [], [], []};
        for as = 1:size(ordered_states,1)
            i = ordered_states(as,s);
            filename = sprintf('%s%i_%s_%i%s', base_path, animals(as), fformat{1}, k, fformat{2});
            results = load(filename);
            stim_strengths = unique(data.stimulus_strength);
            rp = nan(1,length(stim_strengths));
            tmp = filterTrials(data, 'animal', num2str(animals(as)));
            statetmp = tmp(results.predicted_states == i,:);
            if ~isempty(statetmp)
                if strcmp(psychver, 'byanimal')
                    tmp_strengths = unique(statetmp.stimulus_strength);
                    for ss = 1:length(tmp_strengths)
                        sstmp = filterTrials(statetmp, 'stim_strength', tmp_strengths(ss));
                        if tmp_strengths(ss)
                            rtmp = filterTrials(sstmp, 'categorical_outcome', 'Hit');
                        else
                            rtmp = filterTrials(sstmp, 'categorical_outcome', 'FA');
                        end
                        ind = find(stim_strengths == tmp_strengths(ss));
                        rp(ind) = size(rtmp,1) / size(sstmp,1);
                    end
                end
                state_rp = [state_rp; rp];
                % [ch1, ch2, t] = avg_photo_traces(statetmp, tbounds, 'stimulus', 'filtered');
                % ne_ch1 = [ne_ch1; nanmean(ch1)];
                % ne_ch2 = [ne_ch2; nanmean(ch2)];
                for o = 1:length(outcomes)
                    otmp = filterTrials(statetmp, 'categorical_outcome', outcomes{o});
                    if ~isempty(otmp)
                        % [p, tp] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], 'stimulus');
                        [ch1, ~, t] = avg_photo_traces(otmp, tbounds, 'stimulus','filtered');
                        ne_ch1{o} = [ne_ch1{o}; ch1];
                    end
                end
            end
            all_ne{s} = ne_ch1;
        end
    end

    
    y = [];
    inds = [];
    outcomes = [];
    for o = 1:4
        y = [y; all_ne{1}{o}; all_ne{2}{o}; all_ne{3}{o}; all_ne{4}{o}];
        inds = [inds; zeros(size(all_ne{1}{o},1),1)+1; zeros(size(all_ne{2}{o},1),1)+2; zeros(size(all_ne{3}{o},1),1)+3; zeros(size(all_ne{4}{o},1),1)+4];
        outcomes = [outcomes; zeros(size(all_ne{1}{o},1),1)+o; zeros(size(all_ne{2}{o},1),1)+o; zeros(size(all_ne{3}{o},1),1)+o; zeros(size(all_ne{4}{o},1),1)+o];
    end
    [~, all_score, ~, ~, ~] = pca(y);
    fig_bar = figure('Position', [ 1220, 1418, 1707, 420]);
    tl = tiledlayout(1,4);
    cols = distinguishable_colors(4);
    for o = 1:4
        axs(o) = nexttile;
        hold on 
        for i = 1:4
            score = all_score(inds==i & outcomes == o,:);
            errorbar(nanmean(score(:,1)), nanmean(score(:,2)), ste(score(:,2)), ste(score(:,2)), ste(score(:,1)), ste(score(:,1)), 'o', 'Color', cols(i,:), 'LineWidth', 2)
        end
    end
    ylabel(tl,'NE_{mPFC} PC2', 'FontSize', 16)
    xlabel(tl, 'NE_{mPFC} PC1', 'FontSize', 16)

    fig_dot = figure('Position', [ 1220, 1418, 1707, 420]);
    tl = tiledlayout(1,4);
    cols = distinguishable_colors(4);
    for o = 1:4
        axs(o) = nexttile;
        hold on 
        for i = 1:4
            score = all_score(inds==i & outcomes == o,:);
            plot(score(:,1), score(:,2), '.', 'Color', cols(i,:))
        end
    end
    ylabel(tl,'NE_{S1} PC2', 'FontSize', 16)
    xlabel(tl, 'NE_{S1} PC1', 'FontSize', 16)    

    % figure()
    % for o = 1:4
    %     axs(o) = nexttile;
    %     y = [all_ne{1}{o}; all_ne{2}{o}; all_ne{3}{o}; all_ne{4}{o}];
    %     inds = [zeros(size(all_ne{1}{o},1),1)+1; zeros(size(all_ne{2}{o},1),1)+2; zeros(size(all_ne{3}{o},1),1)+3; zeros(size(all_ne{4}{o},1),1)+4];
    %     [~, score, ~, ~, explained] = pca(y);
    %     hold on 
    %     for i = 1:4
    %         % scatter3(nanmean(score(inds==i,1)), nanmean(score(inds==i,2)), nanmean(score(inds==i,3)), 36, cols(i,:))
    %         errorbar(nanmean(score(inds==i,1)), nanmean(score(inds==i,2)), ste(score(inds==i,2)), ste(score(inds==i,2)), ste(score(inds==i,1)), ste(score(inds==i,1)), 'o', 'Color', cols(i,:))
    %     end
    % end

    % ylabel(tl,'NE_{mPFC} PC2', 'FontSize', 16)
    % xlabel(tl, 'NE_{mPFC} PC1', 'FontSize', 16)    
    % unifyYLimits(fig)

    saveas(fig_bar, 'Figures/fig7f_alt_bar.fig')
    saveas(fig_bar, 'Figures/fig7f_alt_bar.svg')
    saveas(fig_dot, 'Figures/fig7f_alt_dot.fig')
    saveas(fig_dot, 'Figures/fig7f_alt_dot.svg')
    % leg = legend()
    % title(leg, 'HMM State', 'FontSize', 16)
end

function lumpByResponseProb_plotByOutcome(data_ver, ssd_version, psychver, animals, data, k)
    % set paths 
    fformat = {data_ver, 'state_Python2mat.mat'};
    base_path = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ssd_version, data_ver);
    outdir = strcat(base_path, 'figures/phys_by_state/', psychver, '/');
    if ~exist(outdir, 'dir')
        mkdir(outdir)
    end

    if startsWith(data_ver, 'behvaior') || startsWith(data_ver, 'last_trial')
        data = removeFirstTrials(data);
    end

    % for single number of states, get the states ordered by average response probability
    % in each state
    mrps = zeros(length(animals), k);
    ordered_states = mrps;
    for a = 1:length(animals)
        tmp = filterTrials(data, 'animal', num2str(animals(a)));
        filename = sprintf('%s%i_%s_%i%s', base_path, animals(a), fformat{1}, k, fformat{2});
        mrps(a,:) = meanResponseProb(filename, tmp, k);
        [~, inds] = sort(mrps(a,:));
        ordered_states(a,:) = inds - 1;
    end

    % average psychometric curves for each animal in each ordered state (starting with lowest)
    figure()
    outcomes = {'Hit', 'Miss', 'CR'};
    tbounds = [-0.5,6.0];
    for s = 1:k
        cols = distinguishable_colors(k);
        ne_ch1 = {[], [], []};
        ne_ch2 = {[], [], []};
        pupil = {[], [], []};
        for as = 1:size(ordered_states,1)
            i = ordered_states(as,s);
            filename = sprintf('%s%i_%s_%i%s', base_path, animals(as), fformat{1}, k, fformat{2});
            results = load(filename);
            stim_strengths = unique(data.stimulus_strength);
            rp = nan(1,length(stim_strengths));
            tmp = filterTrials(data, 'animal', num2str(animals(as)));
            statetmp = tmp(results.predicted_states == i,:);
            if ~isempty(statetmp)
                for o = 1:length(outcomes)
                    otmp = filterTrials(statetmp, 'categorical_outcome', outcomes{o});
                    [ch1, ch2, t] = avg_photo_traces(otmp, tbounds, 'stimulus', 'filtered');
                    ne_ch1{o} = [ne_ch1{o}; nanmean(ch1)];
                    ne_ch2{o} = [ne_ch2{o}; nanmean(ch2)];
                    [p, tp] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], 'stimulus');
                    pupil{o} = [pupil{o}; p];
                end
            end
        end
        subplot(k,3,(s-1)*3+1)
        for o = 1:3
            semshade(ne_ch1{o}, 0.3, cols(o,:), cols(o,:), t);
            hold on
        end
        subplot(k,3,(s-1)*3+2)
        for o = 1:3
            semshade(ne_ch2{o}, 0.3, cols(o,:), cols(o,:), t);
            hold on
        end
        subplot(k,3,(s-1)*3+3)
        for o = 1:3
            semshade(pupil{o}, 0.3, cols(o,:), cols(o,:), tp);
            hold on
        end
    end
    % subplot(1,4,1)
    % xlabel('Stimulus Strength (PSI)')
    % ylabel('Response Probability')
    % subplot(1,4,2)
    % xlim(tbounds)
    % ylabel('NE_{mPFC} (z-score)')
    % subplot(1,4,3)
    % xlim(tbounds)
    % xlabel('Time (s)')
    % ylabel('NE_{S1} (z-score)')
    % subplot(1,4,4)
    % xlim(tbounds)
    % ylabel('Pupil Area (z-score)')
    % subplot(1,4,4); ylim([-0.6,0.61])
    % subplot(1,4,2); ylim([-0.5,0.8]); subplot(1,4,3); ylim([-0.5,0.8])
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

function mpb = pupilBaseline(filename, data, k)
    results = load(filename);
    states = 0:k-1;
    mpb = zeros(1,length(states));
    for i = states
        tmp = data(results.predicted_states == i,:);
        if ~isempty(tmp)
            [pupil, ~] = avg_pupil_traces(tmp, [-0.5, 0], 'stimulus');
            pupil = nanmean(nanmean(pupil, 2));
            mpb(i+1) = pupil;
        end
    end     
end

function rps = responseProbSlope(filename, data, k)
    results = load(filename);
    states = 0:k-1;
    stim_strengths = unique(data.stimulus_strength);
    rps = zeros(1,length(states));
    cols = distinguishable_colors(length(states));
    % figure()
    for i = states
        rp = nan(1,length(stim_strengths));
        tmp = data(results.predicted_states == i,:);
        if ~isempty(tmp)
            tmp_strengths = unique(tmp.stimulus_strength);
            for ss = 1:length(tmp_strengths)
                sstmp = filterTrials(tmp, 'stim_strength', tmp_strengths(ss));
                if tmp_strengths(ss)
                    rtmp = filterTrials(sstmp, 'categorical_outcome', 'Hit');
                else
                    rtmp = filterTrials(sstmp, 'categorical_outcome', 'FA');
                end
                ind = find(stim_strengths == tmp_strengths(ss));
                rp(ind) = size(rtmp,1) / size(sstmp,1);
            end
        end
        % plot(stim_strengths.*10, rp, '*-', 'Color', cols(i+1,:))
        % hold on
        [p, ~] = polyfit(stim_strengths(1:5), rp(1:5), 1);
        rps(i+1) = p(1);
    end
end

function mrp = meanResponseProb(filename, data, k)
    results = load(filename);
    states = 0:k-1;
    stim_strengths = unique(data.stimulus_strength);
    mrp = zeros(1,length(states));
    cols = distinguishable_colors(length(states));
    % figure()
    for i = states
        rp = nan(1,length(stim_strengths));
        tmp = data(results.predicted_states == i,:);
        if ~isempty(tmp)
            tmp_strengths = unique(tmp.stimulus_strength);
            for ss = 1:length(tmp_strengths)
                sstmp = filterTrials(tmp, 'stim_strength', tmp_strengths(ss));
                if tmp_strengths(ss)
                    rtmp = filterTrials(sstmp, 'categorical_outcome', 'Hit');
                else
                    rtmp = filterTrials(sstmp, 'categorical_outcome', 'FA');
                end
                ind = find(stim_strengths == tmp_strengths(ss));
                rp(ind) = size(rtmp,1) / size(sstmp,1);
            end
            % plot(stim_strengths.*10, rp, 'Color', cols(i+1,:))
            % hold on
        end
        mrp(i+1) = nanmean(rp);
    end
end
