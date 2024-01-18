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

lumpByResponseProb(data_versions{1}, ssd_version, psychver, animals, data, k)
lumpByResponseProb(data_versions{end}, ssd_version, psychver, animals, data, k)
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
        semshade(ch1, 0.3, cols(s,:), cols(s,:), t);
        hold on
        subplot(1,4,3)
        semshade(ch2, 0.3, cols(s,:), cols(s,:), t);
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
        semshade(ch1, 0.3, cols(s,:), cols(s,:), t);
        hold on
        subplot(1,4,3)
        semshade(ch2, 0.3, cols(s,:), cols(s,:), t);
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
        semshade(ch1, 0.3, cols(s,:), cols(s,:), t);
        hold on
        subplot(1,4,3)
        semshade(ch2, 0.3, cols(s,:), cols(s,:), t);
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


function plot_phys_by_states(filename, data, animal, k, outdir, psychver)
    results = load(filename);
    fig = figure('Visible', 'off', 'WindowState', 'maximized');
    hold on;
    states = 0:k-1;
    tbounds = [-0.5, 6.0];
    cols = distinguishable_colors(length(states));
    stim_strengths = unique(data.stimulus_strength);
    for i = states
        rp = nan(1,length(stim_strengths));
        tmp = data(results.predicted_states == i,:);
        if ~isempty(tmp)
            if strcmp(psychver, 'byanimal')
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
                subplot(1,4,1)
                hold on
                plot(stim_strengths .* 10, rp, 'Color', cols(i+1,:))
            else
                sessions = unique(tmp.session_id);
                rp = nan(length(sessions),length(stim_strengths));
                for s = 1:length(sessions)
                    stmp = filterTrials(tmp, 'session_id', sessions{s});
                    tmp_strengths = unique(stmp.stimulus_strength);
                    for ss = 1:length(tmp_strengths)
                        sstmp = filterTrials(stmp, 'stim_strength', tmp_strengths(ss));
                        if tmp_strengths(ss)
                            rtmp = filterTrials(stmp, 'categorical_outcome', 'Hit');
                        else
                            rtmp = filterTrials(stmp, 'categorical_outcome', 'FA');
                        end
                        ind = find(stim_strengths == tmp_strengths(ss));
                        rp(s,ind) = size(rtmp,1) / size(sstmp,1);
                    end
                end
                subplot(1,4,1)
                hold on
                % plot(stim_strengths .* 10, rp, 'Color', cols(i+1,:))
                try
                    semshade(rp, 0.3, cols(i+1,:), cols(i+1,:), stim_strengths .* 10, 1, 'label');
                catch
                    plot(stim_strengths .* 10, rp, 'Color', cols(i+1,:))
                end
            end

            [ch1, ch2, t] = avg_photo_traces(tmp, tbounds, 'stimulus', 'filtered');
            % keyboard
            n = size(tmp,1);
            subplot(1,4,2)
            hold on 
            try
                semshade(ch1(:,2:end-1), 0.3, cols(i+1,:), cols(i+1,:), t(2:end-1), 1, sprintf('State %i (n=%i)', i, n));
            catch
                % keyboard
                plot(t, ch1, 'DisplayName', sprintf('State %i (n=%i)', i, n))
            end
            subplot(1,4,3)
            hold on 
            try
                semshade(ch2(:,2:end-1), 0.3, cols(i+1,:), cols(i+1,:), t(2:end-1), 1, sprintf('State %i (n=%i)', i, n));
            catch
                % keyboard
                plot(t, ch2, 'DisplayName', sprintf('State %i (n=%i)', i, n))
            end
            [pupil, t] = avg_pupil_traces(tmp, [tbounds(1)-0.1,tbounds(2)+0.1], 'stimulus');
            % keyboard
            subplot(1,4,4)
            hold on
            try
                semshade(pupil(:,2:end-1), 0.3, cols(i+1, :), cols(i+1, :), t(2:end-1), 1, sprintf('State %i (n=%i)', i, n));
            catch
                % keyboard
                plot(t, pupil, 'DisplayName', sprintf('State %i (n=%i)', i, n));
            end
            ch1_region = tmp.photometry_region_ch1{1,1};
            ch2_region = tmp.photometry_region_ch2{1,1};
        end
    end
    subplot(1,4,1)
    ylabel('Response Probability')
    xlabel('Stimulus Strength (PSI)')
    subplot(1,4,2)
    ylabel(sprintf('%s NE', ch1_region))
    ylim1 = ylim;
    xlim(tbounds)
    subplot(1,4,3)
    ylabel(sprintf('%s NE', ch2_region))
    xlabel('Time (s)')
    ylim2 = ylim;
    subplot(1,4,2)
    plot([0,0],[min(horzcat(ylim1,ylim2)), max(horzcat(ylim1,ylim2))], 'k:', 'HandleVisibility','off')
    subplot(1,4,3)
    plot([0,0],[min(horzcat(ylim1,ylim2)), max(horzcat(ylim1,ylim2))], 'k:', 'HandleVisibility','off')
    xlim(tbounds)
    subplot(1,4,4)
    legend('location', 'northeast')
    ylims = ylim;
    ylabel('Pupil Area')
    plot([0,0],[ylims(1), ylims(2)], 'k:', 'HandleVisibility','off')
    xlim(tbounds)
    saveas(fig, sprintf('%s%s_%istates.png', outdir, num2str(animal),length(states)))
    saveas(fig, sprintf('%s%s_%istates.svg', outdir, num2str(animal),length(states)))
    saveas(fig, sprintf('%s%s_%istates.fig', outdir, num2str(animal),length(states)))
    close
end

% function [ch1mat, ch2mat, time] = avg_photo_traces(data, tbounds)
%     % generates averages of photometry traces 
%     Fss = getFs(data, 'photometry_ch1');
%     ch1mat = zeros(size(data,1), round(max(Fss)*diff(tbounds)));
%     ch2mat = ch1mat;
%     starts = data.stimulus_time;
%     time = linspace(tbounds(1), tbounds(2), round(max(Fss)*diff(tbounds)));

%     for i = 1:size(data,1)
%         t = data.photometry_ch1{i,1}(:,1) - starts(i);
%         ch1 = data.photometry_ch1{i,1}(:,2);
%         ch2 = data.photometry_ch2{i,1}(:,2);
%         ch1 = ch1(t > tbounds(1) & t < tbounds(2));
%         ch2 = ch2(t > tbounds(1) & t < tbounds(2));
%         t = t(t > tbounds(1) & t < tbounds(2));
%         % using interp1 to avoid issues with differing sample rates
%         ch1mat(i,:) = interp1(t, ch1, time);
%         ch2mat(i,:) = interp1(t, ch2, time);
%     end
% end

% function [pupil, time] = avg_pupil_traces(data, tbounds)
%     % generates averages of pupil traces
%     Fs = 1 / (data.pupil_area{1,1}(2,1)-data.pupil_area{1,1}(1,1));
%     pupil = nan(size(data,1), round(Fs*diff(tbounds)));
%     starts = data.stimulus_time;
%     time = linspace(tbounds(1), tbounds(2), round(Fs*diff(tbounds)));

%     for i = 1:size(data,1)
%         t = data.pupil_area{i,1}(:,1) - starts(i);
%         p = data.pupil_area{i,1}(:,2);
%         p = p(t >= tbounds(1) & t <= tbounds(2));
%         t = t(t >= tbounds(1) & t <= tbounds(2));
%         try
%             % again with the sample rate issues
%             pupil(i,:) = interp1(t,p,time);
%         end
%     end
% end

