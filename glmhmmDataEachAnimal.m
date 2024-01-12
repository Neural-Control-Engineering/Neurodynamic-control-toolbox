data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
animals = fetchAnimals(data);
data(cellfun(@isempty, data.photometry_ch1),:) = [];
ssd_version = 'v2';

%% behavior from previous trial
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
%     'behavior_pupil_combo'};
% data_versions = {'spontaneous_mpfc_stim', ...
%                 'spontaneous_s1_stim', ...
%                 'spontaneous_pupil_stim'};
% data_versions = {'dynamic_state'};
% data_versions = {'spontaneous_mpfc_s1_stim'}
data_versions = {'spontaneous_pupil_stim_drop_outliers'};

for i = 1:length(data_versions)
    data_version = data_versions{i};
    outdir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/', ssd_version, data_version);
    if ~exist(outdir, 'dir')
        mkdir(outdir)
    end

    for a = 1:length(animals)
        animal = num2str(animals(a));
        tmp = filterTrials(data, 'animal', animal);
        tmp = rmDiscrepantTrials(tmp);
        genHmmGlmData(tmp, sprintf('%s%s_%s.mat', outdir, animal, data_version), data_version, false)
    end
end

%%
% N_shuffles = 10;
% for n = 1:N_shuffles
%     outdir = sprintf('NT-GLM-HMM/prev_behavior/shuffled/shuffle_%i/',n);
%     if ~exist(outdir, 'dir')
%         mkdir(outdir)
%     end

%     for a = 1:length(animals)
%         animal = num2str(animals(a));
%         tmp = filterTrials(data, 'animal', animal);
%         version = 'last_trial_behavior';
%         genHmmGlmData(tmp, sprintf('%s%s_%s.mat', outdir, animal, version), version, true, n)
%     end
% end