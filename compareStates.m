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
%     'spontaneous_pupil_stim'};
data_versions = {'last_trial_behavior_no_bias', ... 
    'spontaneous_mpfc_s1_pupil_normalized', ... 
    'spontaneous_mpfc_stim', ...
    'spontaneous_s1_stim', ...
    'spontaneous_pupil_stim'};

animals_v1 = [3316, 3258, 3133, 200, 199, 198, 197, 196, 180, 167, 152];
animals_v2 = [240, 241, 242, 243];

for animal = animals_v2
    for k = kstates 
        fig = figure('Visible', 'off', 'WindowState', 'maximized');
        count = 1;
        for i = 1:length(data_versions)
            % load results for each model version
            ver1 = data_versions{i};
            results_dir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ... 
                ssd_version, ver1);
            fformat = {ver1, 'state_Python2mat.mat'};
            fname = sprintf('%s%i_%s_%i%s', results_dir, animal, fformat{1}, k, fformat{2});
            results1 = load(fname);
            % handle difference in number of trials in using previous trial behavior 
            if startsWith(ver1, 'last_trial') || startsWith(ver1, 'behavior')
                predicted_states = insertFirstTrials(data, animal, ...
                    results1.predicted_states);
            else
                predicted_states = results1.predicted_states;
            end
            for j = 1:length(data_versions)
                if i ~= j
                    ver2 = data_versions{j};
                    results_dir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ... 
                            ssd_version, ver2);
                    fformat = {ver2, 'state_Python2mat.mat'};
                    fname = sprintf('%s%i_%s_%i%s', results_dir, animal, fformat{1}, k, fformat{2});
                    results2 = load(fname);
                    % handle difference in number of trials in using previous trial behavior 
                    if startsWith(ver2, 'last_trial') || startsWith(ver2, 'behavior')
                        predicted_states2 = insertFirstTrials(data, ...
                            animal, results2.predicted_states);
                    else
                        predicted_states2 = results2.predicted_states;
                    end
                    states = sort(unique(predicted_states(~isnan(predicted_states))));
                    overlap = nan(length(states));
                    for s1 = states
                        for s2 = states
                            inds1 = find(results1.predicted_states == s1);
                            inds2 = find([results2.predicted_states] == s2);
                            overlap(s1+1, s2+1) = length(intersect(inds1, inds2)) / max([length(predicted_states),length(predicted_states2)]);
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
                    x = strrep(x, '_stim', '');
                    x = strrep(x, '_no_bias', '');
                    ylabel(strrep(x, '_', '-'))
                    y = strrep(ver2, 'spontaneous_', '');
                    y = strrep(y, '_combo', '');
                    y = strrep(y, '_normalized', '');
                    y = strrep(y, 'last_trial_', '');
                    y = strrep(y, 'behavior', 'behave');
                    y = strrep(y, '_no_bias', '');
                    y = strrep(y, '_stim', '');
                    xlabel(strrep(y, '_', '-'))
                    clim([0.0, 0.7])
                    xtickangle(0)
                end
                count = count + 1;
            end
        end
        saveas(fig, sprintf('NT-GLM-HMM/data/v2/compare_states/animal_%i_state_%i.svg', animal, k))
        saveas(fig, sprintf('NT-GLM-HMM/data/v2/compare_states/animal_%i_state_%i.png', animal, k))
        saveas(fig, sprintf('NT-GLM-HMM/data/v2/compare_states/animal_%i_state_%i.fig', animal, k))
        close
    end
end

function first_trials = getFirstTrials(data)
    sessions = unique(data.session_id);
    first_trials = zeros(1,length(sessions));
    for s = 1:length(sessions)
        session = sessions{s};
        trials = find(data.session_id == session);
        first_trials(s) = min(trials);
    end
end
    
function results = insertFirstTrials(data, animal, results)
    tmp = filterTrials(data, 'animal', num2str(animal));
    first_trials = getFirstTrials(tmp);
    tmp_results = zeros(1,size(tmp,1));
    tmp_results(first_trials) = nan;
    ts = [];
    for t = 1:size(tmp,1)
        if ~any(ismember(first_trials, t))
            ts = [ts, t];
        end
    end
    tmp_results(ts) = results;
    results = tmp_results;
end