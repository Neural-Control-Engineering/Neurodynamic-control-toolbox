% script for plotting psychometric curves based on states identified by glm-hmm
% Craig Kelley, NEC Lab, 8/21/23

data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
animals = fetchAnimals(data);
data(cellfun(@isempty, data.photometry_ch1),:) = [];
ssd_version = 'v2';
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
%     'spontaneous_mpfc_s1_stim'};  %'dynamic_state' ...
    data_versions = {'last_trial_behavior_no_bias'};
    
% data = rmDiscrepantTrials(data);
animals_v1 = [3316, 3258, 3133, 200, 199, 198, 197, 196, 180, 167, 152];
animals_v2 = [240, 241, 242, 243];
animals = animals_v2;

for dv = 1:length(data_versions)
    data_ver = data_versions{dv};
    fformat = {data_ver, 'state_Python2mat.mat'};
    results_dir = sprintf('NT-GLM-HMM/data/lapse/%s/Lapse_Model/', data_ver);
    outdir = strcat(results_dir, 'figures/psych_curve_by_state/');
    if ~exist(outdir, 'dir')
        mkdir(outdir)
    end
    for animal = animals
        tmp = filterTrials(data, 'animal', num2str(animal));
        % if startsWith(data_ver, 'behvaior') || startsWith(data_ver, 'last_trial')
        %     tmp = removeFirstTrials(tmp);
        % end
        fname = sprintf('%s%i/results.mat', results_dir, animal);
        plot_psycho_curves_states(fname, tmp, num2str(animal), 2, data_ver, outdir);
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

function plot_psycho_curves_states(filename, data, animal, k, data_version, outdir)
    % identifies all sessions in which a particular state occurs, generates a 
    % psychometric curve for that session-state pair, then averages psychometric 
    % curves of a particular state across sessions 
    results = load(filename);
    fig = figure('Visible', 'off', 'WindowState', 'maximized');
    hold on;

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
            % semshade(mat(:,2:end), 0.3, cols(i+1), cols(i+1), strengths(2:end), 1, sprintf('State %i (n=%i)', i, n));
            % keyboard
            try
                % semshade(mat(:,any(~isnan(mat))), 0.3, cols(i+1), cols(i+1), strengths(any(~isnan(mat))) .* 10, 1, sprintf('State %i (n=%i)', i, n));
                semshade(mat(:,2:end), 0.3, cols(i+1, :), cols(i+1,:), strengths(2:end) .* 10, 1, sprintf('State %i (n=%i)', i, n));
            catch
                plot(strengths(2:end) .* 10, mat(2:end), 'DisplayName', sprintf('State %i (n=%i)', i, n))
            end
            hold on
        end
    end
    xlabel('Stimulus Strength (x10 PSI)')
    ylabel('Performance')
    legend()

    legend('location','southeast')
    xlabel('Stimulus Strength (PSI)')
    ylabel('Accuracy')
    title(sprintf('%s, %s - Accuracy: %.3f', animal, strrep(data_version, '_', '-'), mean(results.accuracy)))
    ylim([0,1.05])
    saveas(fig, sprintf('%s%s_%istates.png', outdir, animal,length(states)))
    saveas(fig, sprintf('%s%s_%istates.svg', outdir, animal,length(states)))
    saveas(fig, sprintf('%s%s_%istates.fig', outdir, animal,length(states)))
    close
end
