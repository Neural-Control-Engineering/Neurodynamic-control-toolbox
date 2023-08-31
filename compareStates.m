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
% data_versions = {'last_trial_behavior_no_bias', ... 
%     'spontaneous_mpfc_s1_pupil_normalized', ... 
%     'last_trial_behavior_drop_stim_no_bias', ...
%     'behavior_pupil_mpfc_s1_combo', ... 
%     'behavior_pupil_mpfc_combo', ... 
%     'behavior_pupil_s1_combo', ...
%     'spontaneous_mpfc_s1_pupil_drop_stim'};

animals_v1 = [3316, 3258, 3133, 200, 199, 198, 197, 196, 180, 167, 152];
animals_v2 = [240, 241, 242, 243];

animal = animals_v2(1);
k = 4;
fig = figure('Visible', 'on', 'WindowState', 'maximized');

count = 1;
for i = 1:length(data_versions)
    % load results for fir
    ver1 = data_versions{i};
    results_dir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ... 
        ssd_version, ver1);
    fformat = {ver1, 'state_Python2mat.mat'};
    fname = sprintf('%s%i_%s_%i%s', results_dir, animal, fformat{1}, k, fformat{2});
    results1 = load(fname);
    for j = 1:length(data_versions)
        if i ~= j
            ver2 = data_versions{j};
            results_dir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ... 
                    ssd_version, ver2);
            fformat = {ver2, 'state_Python2mat.mat'};
            fname = sprintf('%s%i_%s_%i%s', results_dir, animal, fformat{1}, k, fformat{2});
            results2 = load(fname);

            states = sort(unique(results1.predicted_states));
            overlap = nan(length(states));
            for s1 = states
                for s2 = states
                    inds1 = find(results1.predicted_states == s1);
                    inds2 = find(results2.predicted_states == s2);
                    overlap(s1+1, s2+1) = length(intersect(inds1, inds2)) / length(results1.predicted_states);
                end
            end
            subplot(length(data_versions), length(data_versions), count)
            imagesc(states, states, overlap)
            xticks(states)
            yticks(states)
            colorbar()
            x = strrep(ver1, 'spontaneous_', '');
            x = strrep(x, '_combo', '');
            x = strrep(x, '_normalized', '');
            x = strrep(x, 'last_trial_', '');
            x = strrep(x, 'behavior', 'behave');
            x = strrep(x, '_no_bias', '');
            ylabel(strrep(x, '_', '-'))
            y = strrep(ver2, 'spontaneous_', '');
            y = strrep(y, '_combo', '');
            y = strrep(y, '_normalized', '');
            y = strrep(y, 'last_trial_', '');
            y = strrep(y, 'behavior', 'behave');
            y = strrep(y, '_no_bias', '');
            xlabel(strrep(y, '_', '-'))
            clim([0.0, 0.5])
        end
        count = count + 1;
    end
end
    