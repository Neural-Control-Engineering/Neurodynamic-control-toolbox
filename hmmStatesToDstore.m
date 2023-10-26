data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
animals = fetchAnimals(data);
data(cellfun(@isempty, data.photometry_ch1),:) = [];
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
    'behavior_pupil_combo', ...
    'spontaneous_mpfc_stim', ...
    'spontaneous_s1_stim', ...
    'spontaneous_pupil_stim'};
column_names = {'last_trial_stim', ... 
    'mpfc_s1_pupil_stim', ... 
    'last_trial_no_stim', ...
    'last_trial_mpfc_s1_pupil_stim', ... 
    'last_trial_mpfc_pupil', ... 
    'last_trial_s1_pupil', ...
    'mpfc_s1_pupil_no_stim', ...
    'last_trial_mpfc_s1_stim', ...
    'last_trial_mpfc_stim', ...
    'last_tiral_s1_stim', ...
    'last_trial_pupil_stim', ...
    'mpfc_stim', ...
    's1_stim', ...
    'pupil_stim'};
animals_v1 = [3316, 3258, 3133, 200, 199, 198, 197, 196, 180, 167, 152];
animals_v2 = [240, 241, 242, 243];
animals = animals_v2;

for animal = animals 
    tmp = filterTrials(data, 'animal', num2str(animal));
    for dv = 1:length(data_versions)
        data_ver = data_versions{dv};
        fformat = {data_ver, 'state_Python2mat.mat'};
        base_path = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ssd_version, data_ver);
        states = zeros(size(tmp,1), length(kstates));

        if startsWith(data_ver, 'last_trial') || startsWith(data_ver, 'behavior')
            first_trials = getFirstTrials(tmp);
            for k = kstates
                filename = sprintf('%s%i_%s_%i%s', base_path, animal, fformat{1}, k, fformat{2});
                results = load(filename);
                states(first_trials,k-1) = nan;
                ts = [];
                for t = 1:size(tmp,1)
                    if ~any(ismember(first_trials, t))
                        ts = [ts, t];
                    end
                end
                states(ts,k-1) = results.predicted_states;
            end
        else
            for k = kstates
                filename = sprintf('%s%i_%s_%i%s', base_path, animal, fformat{1}, k, fformat{2});
                results = load(filename);
                states(:,k-1) = results.predicted_states;
            end
        end

        state_cell = cell(size(tmp,1),1);
        for t = 1:size(tmp,1)
            state_cell{t} = states(t,:);
        end

        x = table(state_cell, 'VariableNames', {column_names{dv}});
        tmp = [tmp, x];
    end
    save(sprintf('animal_%i_with_hmm_states.mat', animal), 'tmp')
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
