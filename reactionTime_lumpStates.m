% Script for plotting transition probabilities between states
% averaged over model folds.  Plots all states for each animal 
% and version of the model.
% Craig Kelley, NEC Lab, 9/8/23

ssd_version = 'v3';
kstates = [2, 3, 4, 5, 6];
data_versions = {'spontaneous_pupil_stim_v2'}
data = filterTrials(Datastore.Datastore, 'recording_location', 'mPFC-S1');
data(cellfun(@isempty, data.photometry_ch1),:) = [];
animals = fetchAnimals(data);

data_ver = data_versions{1};
k = 4;
base_path = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ssd_version, data_ver);
psychver = 'byanimal';
reaction_times = lumpByResponseProb(data_ver, ssd_version, psychver, animals, data, k, [0:4]);
% lumpByResponseProbSlope(data_ver, ssd_version, psychver, animals, data, k, [0:4])

function reaction_times = lumpByResponseProb(data_ver, ssd_version, psychver, animals, data, k, folds)
    % set paths 
    fformat = {data_ver, 'state_Python2mat.mat'};
    base_path = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ssd_version, data_ver);
   
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

    reaction_times = zeros(length(animals), k);
    for s = 1:k
        for as = 1:size(ordered_states,1)
            i = ordered_states(as,s);
            filename = sprintf('%s%i_%s_%i%s', base_path, animals(as), fformat{1}, k, fformat{2});
            results = load(filename);
            stim_strengths = unique(data.stimulus_strength);
            rp = nan(1,length(stim_strengths));
            tmp = filterTrials(data, 'animal', num2str(animals(as)));
            statetmp = tmp(results.predicted_states == i,:);
            statetmp = filterTrials(statetmp, 'categorical_outcome', 'Hit');
            reaction_times(as,s) = nanmean(statetmp.response_time);
        end
    end
    avg = nanmean(reaction_times);
    for i = size(reaction_times,2)
        err(i) = nanstd(reaction_times(:,i)) / sum(~isnan(reaction_times(:,i)));
    end
    errorbar(0:3, avg, err, 'k.')
    hold on
    bar(0:3, avg, 'FaceColor', 'k', 'EdgeColor', 'k')
    xlim([-0.7,3.7])
    xticks([0:3])
    xlabel('State', 'FontSize', 16)
    ylabel('Reaction Time (s)', 'FontSize', 16)
end

function lumpByResponseProbSlope(data_ver, ssd_version, psychver, animals, data, k, folds)
    % set paths 
    fformat = {data_ver, 'state_Python2mat.mat'};
    base_path = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ssd_version, data_ver);
   
    if startsWith(data_ver, 'behvaior') || startsWith(data_ver, 'last_trial')
        data = removeFirstTrials(data);
    end

    % for single number of states, get the states ordered by average response probability
    % in each state
    rpss = zeros(length(animals), k);
    ordered_states = rpss;
    for a = 1:length(animals)
        tmp = filterTrials(data, 'animal', num2str(animals(a)));
        filename = sprintf('%s%i_%s_%i%s', base_path, animals(a), fformat{1}, k, fformat{2});
        rpss(a,:) = responseProbSlope(filename, tmp, k);
        [~, inds] = sort(rpss(a,:));
        ordered_states(a,:) = inds - 1;
    end

    all_mat = zeros(k,k,length(animals));
    for a = 1:length(animals)
        tmp = filterTrials(data, 'animal', num2str(animals(a)));
        mat = zeros(k,k,length(folds));
        for f = folds
            fname = sprintf('%s%i_%s_%istate_%ifold_params.mat', base_path, animals(a), data_ver, k, f);
            params = load(fname);
            states = params.params{2} + 10;
            for i = 1:size(ordered_states,2)
                states(states == (i-1)*10) == ordered_states(a,i);
            end
            % mat(:,:,f+1) = exp(reshape(params.params{2},[k,k]));
            mat(:,:,f+1) = exp(reshape(states-10,[k,k]));
        end
        
        all_mat(:,:,a) = mean(mat, 3);
    end
    imagesc(0:k-1, 0:k-1, mean(all_mat,3))
    xticks([0:4])
    yticks([0:4])
    ylabel('Current State', 'FontSize', 16)
    xlabel('Next State', 'FontSize', 16)
    cbar = colorbar()
    ylabel(cbar, 'Transition Probability', 'FontSize', 16)
end

function fig = plotTransitionsAllNstates(base_path, animal, data_ver, kstates, folds)

    fig = figure('Visible', 'off');
    tlc = tiledlayout(1, length(kstates));
    tlc.TileSpacing = 'compact';

    for k = kstates 
        mat = zeros(k,k,length(folds));
        for f = folds
            fname = sprintf('%s%i_%s_%istate_%ifold_params.mat', base_path, animal, data_ver, k, f);
            params = load(fname);
            mat(:,:,f+1) = exp(reshape(params.params{2},[k,k]));
        end
        nexttile(tlc)
        imagesc(0:k-1, 0:k-1, mean(mat,3))
        axis square
        xticks(0:k-1)
        yticks(0:k-1)
        colorbar()
        title(sprintf('%i States', k))
        clim([0,1])
        xtickangle(0)
    end
end

function fig = plotTransitions(base_path, animal, data_ver, k, folds)

    fig = figure('Visible', 'on');
   
    mat = zeros(k,k,length(folds));
    for f = folds
        fname = sprintf('%s%i_%s_%istate_%ifold_params.mat', base_path, animal, data_ver, k, f);
        params = load(fname);
        mat(:,:,f+1) = exp(reshape(params.params{2},[k,k]));
    end
    imagesc(0:k-1, 0:k-1, mean(mat,3))
    axis square
    xticks(0:k-1)
    yticks(0:k-1)
    colorbar()
    title(sprintf('%i States', k))
    clim([0,1])
    xtickangle(0)
end

function fig = plotTransitionsAllInputs(animal, data_versions, ssd_version, k, folds, titles)
    fig = figure('Visible', 'on');
    for dv = 1:length(data_versions)
        data_ver = data_versions{dv};
        mat = zeros(k,k,length(folds));
        base_path = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ssd_version, data_ver);
        for f = folds
            fname = sprintf('%s%i_%s_%istate_%ifold_params.mat', base_path, animal, data_ver, k, f);
            params = load(fname);
            mat(:,:,f+1) = exp(reshape(params.params{2},[k,k]));
        end
        subplot(1, length(data_versions), dv)
        imagesc(0:k-1, 0:k-1, mean(mat,3))
        axis square
        xticks(0:k-1)
        yticks(0:k-1)
        cb = colorbar();
        xlabel('State', 'FontSize', 14)
        ylabel('State', 'FontSize', 14)
        tl = titles{dv};
        title(tl)
        titleHandle = get(cb, 'Title');
        set(titleHandle, 'String', 'Transition Probability')
        clim([0,1])
    end
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
