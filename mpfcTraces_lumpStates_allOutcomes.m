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

lumpByResponseProb(data_versions{end}, ssd_version, psychver, animals, data, k)

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
    figure('Position', [1220 1373 569 465])
    tbounds = [-0.5,6.0];
    sessions = unique(data.session_id);
    for s = 1:k
        cols = distinguishable_colors(k);
        state_rp = [];
        ne_ch1 = [];
        % for as = 1:size(ordered_states,1)
        for sesh = 1:length(sessions)
            session_id = sessions{sesh};
            sesh_spl = strsplit(session_id, '-');
            as = str2num(sesh_spl{1})-240+1;
            i = ordered_states(as,s);
            filename = sprintf('%s%i_%s_%i%s', base_path, animals(as), fformat{1}, k, fformat{2});
            results = load(filename);
            stim_strengths = unique(data.stimulus_strength);
            rp = nan(1,length(stim_strengths));
            tmp = filterTrials(data, 'animal', num2str(animals(as)));
            statetmp = tmp(results.predicted_states == i,:);
            statetmp = filterTrials(statetmp, 'session_id', session_id);
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
                [ch1, ~, t] = avg_photo_traces(statetmp, [-2,6], 'stimulus','filtered');
                        % ne_ch1{o} = [ne_ch1{o}; ch1];
                if size(ch1,1)>1
                    ne_ch1 = [ne_ch1; nanmean(ch1)];
                else
                    ne_ch1 = [ne_ch1; ch1];
                end
            end
        end
        semshade(ne_ch1, 0.3, cols(s,:), cols(s,:), t, 1, sprintf('State %i', s-1));
        hold on
        xlim(tbounds)
    end

    
    ylabel('NE_{mPFC} (z-score)', 'FontSize', 16)
    xlabel('Time (s)', 'FontSize', 16)
    legend()
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
