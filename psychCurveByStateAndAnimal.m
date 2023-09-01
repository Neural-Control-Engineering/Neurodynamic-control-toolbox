% script for plotting psychometric curves based on states identified by glm-hmm
% Craig Kelley, NEC Lab, 8/21/23

ssd_version = 'v2';
kstates = [2, 3, 4, 5, 6];
data_versions = {'last_trial_behavior_no_bias', ... 
    'spontaneous_mpfc_s1_pupil_normalized', ... 
    'last_trial_behavior_drop_stim_no_bias', ...
    'behavior_pupil_mpfc_s1_combo', ... 
    'behavior_pupil_mpfc_combo', ... 
    'behavior_pupil_s1_combo', ...
    'spontaneous_mpfc_s1_pupil_drop_stim', ...
    'behavior_mpfc_s1_combo', ...
    'behavior_mpfc_combo', ...
    'behavior_s1_combo', ...
    'behavior_pupil_combo'};
animals_v1 = [3316, 3258, 3133, 200, 199, 198, 197, 196, 180, 167, 152];
animals_v2 = [240, 241, 242, 243];
animal = animals_v2(1);
k = 4;

for i = 1:length(data_versions)
    results_dir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ... 
        ssd_version, data_versions{i});
    fformat = {data_versions{i}, 'state_Python2mat.mat'};
    fname = sprintf('%s%i_%s_%i%s', results_dir, animal, fformat{1}, k, fformat{2});
    tmp = filterTrials(data, 'animal', num2str(animal));
    fig = plot_psycho_curves_states(fname, tmp, num2str(animal), data_versions{i});
end

function fig = plot_psycho_curves_states(filename, data, animal, data_version)
    results = load(filename);
    fig = figure('Visible', 'on');
    hold on;

    % strengths = [0, 0.2, 0.5, 1, 2, 4];
    strengths = [0, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0];
    cols = ['b', 'r', 'g', 'c', 'y'];
    states = unique(results.predicted_states);

    for i = states
        tmp = data(results.predicted_states == i,:);
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
            semshade(mat(:,2:end), 0.3, cols(i+1), cols(i+1), strengths(2:end) .* 10, 1, sprintf('State %i (n=%i)', i, n));
        catch
            plot(strengths(2:end) .* 10, mat(2:end), 'DisplayName', sprintf('State %i (n=%i)', i, n))
        end
        hold on
    end
    xlabel('Stimulus Strength (x10 PSI)')
    ylabel('Performance')
    legend()

    legend('location','southeast')
    xlabel('Stimulus Strength (PSI)')
    ylabel('Accuracy')
    title(sprintf('%s, %s - Accuracy: %.3f', animal, strrep(data_version, '_', '-'), mean(results.accuracy)))
    ylim([0,1.05])
    % saveas(fig, sprintf('%s%s_%istates.png', outdir, animal,length(states)))
end
