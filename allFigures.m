addpath(genpath('./'))
Datastore = load('~/Downloads/Combined-Datastore_created_14-Jan-2024.mat');
data = filterTrials(Datastore.Datastore, 'recording_location', 'mPFC-S1');
animals = fetchAnimals(data);
data(cellfun(@isempty, data.photometry_ch1),:) = [];
tbounds = [-0.5, 6.0];
alignTo = 'stimulus';
ssd_version = 'v3';
kstates = [2,3,4,5];
data_versions = {'last_trial_behavior_no_bias', ... 
    'last_trial_behavior_drop_stim_no_bias', ...
    'just_stim', ...
    'spontaneous_pupil_stim_v2', ...
     };
data_version = 'spontaneous_pupil_stim_v2';
k = 4;
psychver = 'byanimal';

% figure 1
fig1c(data);
fig1ef(data);

% figure 2
fig2b(data, tbounds, alignTo);
fig2c(data, tbounds, alignTo);
fig2d(data, tbounds, alignTo);
fig2e(data, tbounds, alignTo);
fig2f(data, tbounds, alignTo);
fig2g(data, tbounds, alignTo);
fig2h(data, tbounds, alignTo);
fig2i(data);
fig2j(data);
fig2k(data);

% figure 3
shuff_xcor = fig3b(data, 'z-score');
fig3c(data, 'z-score', shuff_xcor);
fig3d(data, 'z-score', 'atzero', shuff_xcor);
shuff_ppfc = fig3e(data, 'z-score');
fig3f(data, 'z-score', shuff_ppfc);
fig3g(data, 'z-score', 'peak', shuff_ppfc);
shuff_ps1 = fig3h(data, 'z-score');
fig3i(data, 'z-score', shuff_ps1);
fig3j(data, 'z-score', 'peak', shuff_ps1);

% figure 4
%% s1
fig4a(data, tbounds, alignTo, 'z-score');
fig4b(data, tbounds, alignTo, 'z-score');
fig4c(data, tbounds, alignTo, 'z-score');
fig4d(data, tbounds, alignTo, 'z-score');
fig4e(data);
fig4f(data, 'z-score');
%% s2
fig4g(data, tbounds, alignTo, 'z-score');
fig4h(data, tbounds, alignTo, 'z-score');
fig4i(data, tbounds, alignTo, 'z-score');
fig4k(data);
fig4l(data, 'z-score');

% figure 5
fig5b(animals, data_versions, kstates)
fig5c(data, k, data_version, ssd_version, psychver, animals)
fig5d(data, k, data_version, ssd_version, psychver, animals)
fig5g(data, k, data_version, ssd_version, psychver, animals)
fig5h(data, k, data_version, ssd_version, psychver, animals)

% figure 6 
fig6a(data, k, data_version, ssd_version, psychver, animals)
fig6b(data, k, data_version, ssd_version, psychver, animals)
fig6c(data, k, data_version, ssd_version, psychver, animals)

% figure 7
%% s1
fig7a(data, k, data_version, ssd_version, psychver, animals)
fig7b(data, k, data_version, ssd_version, psychver, animals)
fig7c(data, k, data_version, ssd_version, psychver, animals)
%% s2 
fig7d(data, k, data_version, ssd_version, psychver, animals)
fig7e(data, k, data_version, ssd_version, psychver, animals)
fig7f(data, k, data_version, ssd_version, psychver, animals)

% figure 8 
fig8a(data, k, data_version, ssd_version, psychver, animals, shuff_xcor)
fig8b(data, k, data_version, ssd_version, psychver, animals, shuff_xcor)