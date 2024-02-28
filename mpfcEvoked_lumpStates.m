% script for plotting physiology data based on states identified by glm-hmm
% Craig Kelley, NEC Lab, 8/25/23

% data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
data = filterTrials(Datastore.Datastore, 'recording_location', 'mPFC-S1');
data(cellfun(@isempty, data.photometry_ch1),:) = [];
animals = fetchAnimals(data);
ssd_version = 'v3';
kstates = [2, 3, 4, 5, 6];
% boilerplate
k = 4;
data_versions = {'last_trial_behavior_no_bias', ... 
    'last_trial_behavior_drop_stim_no_bias', ...
    'spontaneous_pupil_stim_v2', ...
     };
psychver = 'byanimal';

% lumpByResponseProb(data_versions{1}, ssd_version, psychver, animals, data, k)
ps = lumpByResponseProb(data_versions{end}, ssd_version, psychver, animals, data, k);
% lumpByResponseProb_plotByOutcome(data_versions{end}, ssd_version, psychver, animals, data, k)
% lumpByResponseProbSlope(data_versions{1}, ssd_version, psychver, animals, data, k)
% lumpByResponseProbSlope(data_versions{end}, ssd_version, psychver, animals, data, k)
% lumpByPupilBaseline(data_versions{1}, ssd_version, psychver, animals, data, k)
% lumpByPupilBaseline(data_versions{end}, ssd_version, psychver, animals, data, k)


function lumpByPupilBaseline(data_ver, ssd_version, psychver, animals, data, k)
    % set paths 
    fformat = {data_ver, 'state_Python2mat.mat'};
    base_path = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ssd_version, data_ver);
    outdir = strcat(base_path, 'figures/phys_by_state/', psychver, '/');
    if ~exist(outdir, 'dir')
        mkdir(outdir)
    end

    mpbs = zeros(length(animals), k);
    ordered_states = mpbs;
    for a = 1:length(animals)
        tmp = filterTrials(data, 'animal', num2str(animals(a)));
        filename = sprintf('%s%i_%s_%i%s', base_path, animals(a), fformat{1}, k, fformat{2});
        mpbs(a,:) = pupilBaseline(filename, tmp, k);
        [~, inds] = sort(mpbs(a,:));
        ordered_states(a,:) = inds - 1;
    end

    % average psychometric curves for each animal in each ordered state (starting with lowest)
    figure('Position', [ 1151, 1516, 1830, 404])
    tbounds = [-0.5,6.0];
    for s = 1:k
        cols = distinguishable_colors(k);
        state_rp = [];
        ne_ch1 = [];
        ne_ch2 = [];
        pupil = [];
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
                [ch1, ch2, t] = avg_photo_traces(statetmp, tbounds, 'stimulus', 'filtered');
                ne_ch1 = [ne_ch1; nanmean(ch1)];
                ne_ch2 = [ne_ch2; nanmean(ch2)];
                [p, tp] = avg_pupil_traces(statetmp, [tbounds(1)-0.1, tbounds(2)+0.1], 'stimulus');
                pupil = [pupil; p];
            end
        end
        subplot(1,4,1)
        semshade(state_rp, 0.3, cols(s,:), cols(s,:), stim_strengths .* 10);
        hold on
        subplot(1,4,2)
        semshade(ne_ch1, 0.3, cols(s,:), cols(s,:), t);
        hold on
        subplot(1,4,3)
        semshade(ne_ch2, 0.3, cols(s,:), cols(s,:), t);
        hold on
        subplot(1,4,4)
        semshade(pupil, 0.3, cols(s,:), cols(s,:), tp);
        hold on
    end
    subplot(1,4,1)
    xlabel('Stimulus Strength (PSI)')
    ylabel('Response Probability')
    subplot(1,4,2)
    xlim(tbounds)
    ylabel('NE_{mPFC} (z-score)')
    subplot(1,4,3)
    xlim(tbounds)
    xlabel('Time (s)')
    ylabel('NE_{S1} (z-score)')
    subplot(1,4,4)
    xlim(tbounds)
    ylabel('Pupil Area (z-score)')
    subplot(1,4,4); ylim([-0.6,0.61])
    subplot(1,4,2); ylim([-0.5,0.8]); subplot(1,4,3); ylim([-0.5,0.8])
end

function lumpByResponseProbSlope(data_ver, ssd_version, psychver, animals, data, k)
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

    rpss = zeros(length(animals), k);
    ordered_states = rpss;
    for a = 1:length(animals)
        tmp = filterTrials(data, 'animal', num2str(animals(a)));
        filename = sprintf('%s%i_%s_%i%s', base_path, animals(a), fformat{1}, k, fformat{2});
        rpss(a,:) = responseProbSlope(filename, tmp, k);
        [~, inds] = sort(rpss(a,:));
        ordered_states(a,:) = inds - 1;
    end

    % average psychometric curves for each animal in each ordered state (starting with lowest)
    figure('Position', [ 1151, 1516, 1830, 404])
    tbounds = [-0.5,6.0];
    for s = 1:k
        cols = distinguishable_colors(k);
        state_rp = [];
        ne_ch1 = [];
        ne_ch2 = [];
        pupil = [];
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
                [ch1, ch2, t] = avg_photo_traces(statetmp, tbounds, 'stimulus', 'filtered');
                ne_ch1 = [ne_ch1; nanmean(ch1)];
                ne_ch2 = [ne_ch2; nanmean(ch2)];
                [p, tp] = avg_pupil_traces(statetmp, [tbounds(1)-0.1, tbounds(2)+0.1], 'stimulus');
                pupil = [pupil; p];
            end
        end
        subplot(1,4,1)
        semshade(state_rp, 0.3, cols(s,:), cols(s,:), stim_strengths .* 10);
        hold on
        subplot(1,4,2)
        semshade(ne_ch1, 0.3, cols(s,:), cols(s,:), t);
        hold on
        subplot(1,4,3)
        semshade(ne_ch2, 0.3, cols(s,:), cols(s,:), t);
        hold on
        subplot(1,4,4)
        semshade(pupil, 0.3, cols(s,:), cols(s,:), tp);
        hold on
    end
    subplot(1,4,1)
    xlabel('Stimulus Strength (PSI)')
    ylabel('Response Probability')
    subplot(1,4,2)
    xlim(tbounds)
    ylabel('NE_{mPFC} (z-score)')
    subplot(1,4,3)
    xlim(tbounds)
    xlabel('Time (s)')
    ylabel('NE_{S1} (z-score)')
    subplot(1,4,4)
    xlim(tbounds)
    ylabel('Pupil Area (z-score)')
    subplot(1,4,4); ylim([-0.6,0.61])
    subplot(1,4,2); ylim([-0.5,0.8]); subplot(1,4,3); ylim([-0.5,0.8])
end

function ps = lumpByResponseProb(data_ver, ssd_version, psychver, animals, data, k)
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
    figure('Position', [ 1220, 1418, 1707, 420])
    tl = tiledlayout(1,4);
    for i = 1:4
        axs(i) = nexttile;
    end
    tbounds = [-0.5,6.0];
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    % pupil = {zeros(a,k), zeros(a,k), zeros(a,k), zeros(a,k)};
    ps = {};
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
                        [ch1b, ~, ~] = avg_photo_traces(otmp, [-0.5,0], 'stimulus','filtered');
                        [ch1d, ~, ~] = avg_photo_traces(otmp, [0,1.0], 'stimulus','filtered');
                        ne_ch1{o} = [ne_ch1{o}; nanmean(ch1d,2) - nanmean(ch1b,2)];
                    % else
                    %     pupil{o}(as,s) = nan;
                    end
                end
            end
        end
        ps{s} = ne_ch1;
    end

    ttls = {'Hit', 'Miss', 'Correct Rejection', 'False Alarm'};
    for o = 1:length(outcomes)
        for i = 1:4                                        
            avgs(i) = nanmean(ps{i}{o});                       
            errs(i) = nanstd(ps{i}{o}) / sqrt(length(ps{i}{o}));
            axes(axs(o))
            errorbar(i-1, avgs(i), errs(i), 'Color', cols(i,:))
            hold on
            bar(i-1, avgs(i), 'EdgeColor', cols(i,:), 'FaceColor', cols(i,:))
        end
        % axes(axs(o))
        % errorbar([0:3], avgs, errs, 'k.')
        % hold on
        % bar([0:3], avgs, 'EdgeColor', 'k', 'FaceColor', 'k')
        xlim([-0.75, 3.75])
        ylim([-0.2,1.1])
        title(ttls{o}, 'FontSize', 16)
    end
    % for o = 1:length(outcomes)
    %     axes(axs(o))
    %     hold on
    %     avg = zeros(1,length(size(pupil{o},1)));
    %     err = zeros(1,length(size(pupil{o},1)));
    %     for c = 1:length(ps{o})
    %         avg(c) = nanmean(ps{o}{c});
    %         err(c) = nanstd(ps{o}{c}) / sqrt(sum(~isnan(ps{o}{c})));
    %     end
    %     errorbar([0:3], avg, err, 'k.')
    %     hold on
    %     bar([0:3], avg, 'EdgeColor', 'k', 'FaceColor', 'k')
    %     xticks([0:3])
    %     title(ttls{o})
    % end
    xlabel(tl, 'States', 'FontSize', 16)
    ylabel(tl, '\Delta NE_{mFPC} (z-score)', 'FontSize', 16)
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
    % ttls = {'Hit', 'Miss', 'Correct Rejection', 'False Alarm'};
    % for o = 1:length(outcomes)
    %     axes(axs(o))
    %     title(ttls{o}, 'FontSize', 16)
    %     ylim([-1,2])
    % end
    
    % ylabel(tl,'Pupil Area (z-score)', 'FontSize', 16)
    % % ylim([-0.3,0.4])
    % xlabel(tl, 'Time (s)', 'FontSize', 16)
    % axes(axs(1))
    % legend()
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
