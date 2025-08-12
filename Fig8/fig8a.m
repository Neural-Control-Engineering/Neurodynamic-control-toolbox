function fig8a(data, k, data_ver, ssd_version, psychver, animals, shuff)
    ps = lumpByResponseProb(data_ver, ssd_version, psychver, animals, data, k, shuff);
    % fprintf('Pupil baseline by outcome / state:\n')
end

function ps = lumpByResponseProb(data_ver, ssd_version, psychver, animals, data, k, shuff)
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
    
    tbounds = [-4,0];
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    Fs = getFs(data, 'photometry_ch1');
    Fs = Fs(1);
    % pupil = {zeros(a,k), zeros(a,k), zeros(a,k), zeros(a,k)};
    ps = {};
    session_xcor = {[], [], [], []};
    for s = 1:k
        cols = distinguishable_colors(k);
        state_rp = [];
        for as = 1:size(ordered_states,1)
            i = ordered_states(as,s);
            filename = sprintf('%s%i_%s_%i%s', base_path, animals(as), fformat{1}, k, fformat{2});
            results = load(filename);
            stim_strengths = unique(data.stimulus_strength);
            rp = nan(1,length(stim_strengths));
            tmp = filterTrials(data, 'animal', num2str(animals(as)));
            statetmp = tmp(results.predicted_states == i,:);
            sessions = unique(statetmp.session_id);
            for ss = 1:length(sessions)
                tmp = filterTrials(statetmp, 'session_id', num2str(sessions(ss)));
                [mpfc, s1, t] = avg_photo_traces(tmp, tbounds, 'stimulus', ver);
                Fs = getFs(data, 'photometry_ch1');
                Fs = Fs(1);
                cs = zeros(size(tmp,1), length([tbounds(1):(1/Fs):tbounds(2)])*2-5);
                lags = zeros(size(tmp,1), length([tbounds(1):(1/Fs):tbounds(2)])*2-5);
                for i = 1:size(mpfc,1)
                    ch1 = mpfc(i,:);
                    ch2 = s1(i,:);
                    % mpfc x s1 
                    [c, lag] = xcorr(ch1(2:end-1), ch2(2:end-1), 'normalized');
                    try
                        lags(i,:) = lag ./ Fs;
                        cs(i,:) = c; % ./ length(ch1(2:end-1));
                    catch
                        lags(i,:) = nan(1, size(lags,2));
                        cs(i,:) = nan(1,size(cs,2));
                    end
                end
                if size(cs,1) > 1
                    try
                        session_xcor{s} = [session_xcor{s}; nanmean(cs)];
                    catch
                        keyboard 
                    end
                else
                    session_xcor{s} = [session_xcor{s}; cs];
                end
            end
        end
    end
    fig = figure(); hold on;
    for s = 1:k 
        semshade(session_xcor{s} - nanmean(shuff), 0.3, cols(s,:), cols(s,:), lags(1,:), 1);
    end
    xlabel('Lag (s)', 'FontSize', 16)
    ylabel('Shuffle Corrected Cross Correlation')
    saveas(fig, 'Figures/fig8a.fig')
    saveas(fig, 'Figures/fig8a.svg')
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
