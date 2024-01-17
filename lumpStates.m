% script for plotting physiology data based on states identified by glm-hmm
% Craig Kelley, NEC Lab, 8/25/23

% data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
data = filterTrials(Datastore.Datastore, 'recording_location', 'mPFC-S1');
animals = fetchAnimals(data);
data(cellfun(@isempty, data.photometry_ch1),:) = [];
ssd_version = 'v3';
kstates = [2, 3, 4, 5, 6];
% data_versions = {'last_trial_behavior_no_bias', ... 
%     'spontaneous_mpfc_s1_pupil_normalized', ... 
%     'last_trial_behavior_drop_stim_no_bias', ...
%     'behavior_pupil_mpfc_s1_combo', ... 
%     'behavior_pupil_mpfc_combo', ... 
%     'behavior_pupil_s1_combo', ...
%     'spontaneous_mpfc_s1_pupil_drop_stim', ...
%     'behavior_mpfc_s1_combo', ...
%     'behavior_mpfc_combo', ...
%     'behavior_s1_combo', ...
%     'behavior_pupil_combo', ...
%     'spontaneous_mpfc_stim', ...
%     'spontaneous_s1_stim', ...
%     'spontaneous_pupil_stim', ...
%     'dynamic_state' ...
%     'spontaneous_mpfc_s1_stim', ...
%     'spontaneous_pupil_stim_v2'};
% data = rmDiscrepantTrials(data);
data_versions = {'last_trial_behavior_no_bias', ... 
    'last_trial_behavior_drop_stim_no_bias', ...
    'spontaneous_pupil_stim_v2', ...
     };
animals_v1 = [3316, 3258, 3133, 200, 199, 198, 197, 196, 180, 167, 152];
animals_v2 = [240, 241, 242, 243];
animals = animals_v2;
psychver = 'byanimal';

% p = gcp('nocreate');
% if isempty(p)
%     parpool(11)
% end

% data_ver = data_versions{1};
% % data_ver = data_versions{1};
% k = 4;
% fformat = {data_ver, 'state_Python2mat.mat'};
% base_path = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ssd_version, data_ver);
% a = 241;
% filename = sprintf('%s%i_%s_%i%s', base_path, a, fformat{1}, k, fformat{2});
% % plot_phys_by_states_outcomes(filename, data, a, k)
% tmp = filterTrials(data, 'animal', num2str(a));
% plot_phys_by_states(filename, tmp, a, k, 'Analysis/paper_figures/figure4/')

% for dv = 1:length(data_versions)
%     data_ver = data_versions{dv};
%     fformat = {data_ver, 'state_Python2mat.mat'};
%     base_path = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ssd_version, data_ver);
%     outdir = strcat(base_path, 'figures/phys_by_state/', psychver, '/');
%     if ~exist(outdir, 'dir')
%         mkdir(outdir)
%     end
%     for a = animals
%         tmp = filterTrials(data, 'animal', num2str(a));
%         if startsWith(data_ver, 'behvaior') || startsWith(data_ver, 'last_trial')
%             tmp = removeFirstTrials(tmp);
%         end
%         for k = kstates
%             filename = sprintf('%s%i_%s_%i%s', base_path, a, fformat{1}, k, fformat{2});
%             plot_phys_by_states(filename, tmp, num2str(a), k, outdir, psychver)
%         end
%     end
% end

% boilerplate
data_ver = data_versions{1};
fformat = {data_ver, 'state_Python2mat.mat'};
base_path = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ssd_version, data_ver);
outdir = strcat(base_path, 'figures/phys_by_state/', psychver, '/');
if ~exist(outdir, 'dir')
    mkdir(outdir)
end
% for single number of states, get the states ordered by average response probability
% in each state
k = 4;
mrps = zeros(length(animals), k);
ordered_states = mrps;
for a = 1:length(animals)
    tmp = filterTrials(data, 'animal', num2str(animals(a)));
    filename = sprintf('%s%i_%s_%i%s', base_path, animals(a), fformat{1}, k, fformat{2});
    mrps(a,:) = meanResponseProb(filename, tmp, animals(a), k);
    [~, inds] = sort(mrps(a,:));
    ordered_states(a,:) = inds - 1;
end

% average psychometric curves for each animal in each ordered state (starting with lowest)

figure()
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
subplot(1,4,2)
xlim(tbounds)
subplot(1,4,3)
xlim(tbounds)
subplot(1,4,4)
xlim(tbounds)

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

function plot_phys_by_states_outcomes(filename, data, animal, k)
    results = load(filename);
    fig = figure('Visible', 'on', 'WindowState', 'maximized');
    hold on;
    states = 0:k-1;
    tbounds = [-0.5, 6.0];
    outcomes = {'Hit', 'Miss', 'CR'};
    cols = distinguishable_colors(length(outcomes));
    for i = states
        tmp = data(results.predicted_states == i,:);
        % outcomes = unique(tmp.categorical_outcome);
        for o = 1:length(outcomes)
            outcome = outcomes{o};
            otmp = filterTrials(tmp, 'categorical_outcome', outcome);
            if ~isempty(otmp)
                [ch1, ch2, t] = avg_photo_traces(otmp, tbounds, 'stimulus', 'filtered');
                n = size(ch1,1);
                subplot(length(states), 3, ((i+1)*3-3)+1)
                hold on 
                try
                    semshade(ch1(:,2:end-1), 0.3, cols(o,:), cols(o,:), t(2:end-1), 1, sprintf('%s (n=%i)', outcome, n));
                catch
                    % keyboard
                    plot(t, ch1, 'DisplayName',sprintf('%s (n=%i)', outcome, n));
                end
                subplot(length(states), 3,((i+1)*3-3)+2)
                hold on 
                try
                    semshade(ch2(:,2:end-1), 0.3, cols(o,:), cols(o,:), t(2:end-1), 1, sprintf('%s (n=%i)', outcome, n));
                catch
                    % keyboard
                    plot(t, ch2, 'DisplayName', sprintf('%s (n=%i)', outcome, n));
                end
                [pupil, t] = avg_pupil_traces(otmp, tbounds);
                subplot(length(states), 3,((i+1)*3-3)+3)
                hold on
                try
                    semshade(pupil(:,2:end-1), 0.3, cols(o, :), cols(o, :), t(2:end-1), 1, sprintf('%s (n=%i)', outcome, n));
                catch
                    % keyboard
                    plot(t, pupil, 'DisplayName', sprintf('State %i (n=%i)', i, n));
                end
            end
        end
        subplot(length(states),3,((i+1)*3-3)+1)
        xlabel('Time (s)', 'FontSize', 14)
        ylabel('mPFC NE', 'FontSize', 14)
        subplot(length(states),3,((i+1)*3-3)+2)
        xlabel('Time (s)', 'FontSize', 14)
        ylabel('S1 NE', 'FontSize', 14)
        title(sprintf('State %i',i), 'FontSize', 14)
        subplot(length(states),3,((i+1)*3-3)+3)
        xlabel('Time (s)', 'FontSize', 14)
        ylabel('Pupil Area', 'FontSize', 14)
        legend()
    end
end

function mrp = meanResponseProb(filename, data, animal, k)
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

