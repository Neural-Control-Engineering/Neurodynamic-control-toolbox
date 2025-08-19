diary ssd_stats.txt
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
fprintf('Figure 1:\n')
fprintf('Figure 1c:\n')
fig1c(data);
fprintf('Figure 1e:\n')
fig1e(data);
fprintf('Figure 1f:\n')
fig1f(data);
close all

% figure 2
fprintf('Figure 2:\n')
fprintf('Figure 2a:\n')
fig2a(data)
fprintf('Figure 2b:\n')
fig2b(data, tbounds, alignTo);
fprintf('Figure 2c:\n')
fig2c(data, tbounds, alignTo);
fprintf('Figure 2d:\n')
fig2d(data, tbounds, alignTo);
fprintf('Figure 2e:\n')
fig2e(data, tbounds, alignTo);
fprintf('Figure 2f:\n')
fig2f(data, tbounds, alignTo);
fprintf('Figure 2g:\n')
fig2g(data, tbounds, alignTo);
fprintf('Figure 2h:\n')
fig2h(data, tbounds, alignTo);
fprintf('Figure 2i:\n')
fig2i(data);
fprintf('Figure 2j:\n')
fig2j(data);
fprintf('Figure 2k:\n')
fig2k(data);
close all

% figure 3
fprintf('Figure 3:\n')
fprintf('Figure 3b:\n')
shuff_xcor = fig3b(data, 'z-score');
fprintf('Figure 3c:\n')
fig3c(data, 'z-score', shuff_xcor);
fprintf('Figure 3d:\n')
fig3d(data, 'z-score', 'atzero', shuff_xcor);
% shuff_ppfc = fig3e(data, 'z-score');
% fig3f(data, 'z-score', shuff_ppfc);
% fig3g(data, 'z-score', 'peak', shuff_ppfc);
% shuff_ps1 = fig3h(data, 'z-score');
% fig3i(data, 'z-score', shuff_ps1);
% fig3j(data, 'z-score', 'peak', shuff_ps1);
close all

% figure 4
%% s1
fprintf('Figure 4:\n')
fprintf('Figure 4a:\n')
fig4a(data, tbounds, alignTo, 'z-score');
fprintf('Figure 4b:\n')
fig4b(data, tbounds, alignTo, 'z-score');
fprintf('Figure 4c:\n')
fig4c(data, tbounds, alignTo, 'z-score');
fprintf('Figure 4d:\n')
fig4d(data, tbounds, alignTo, 'z-score');
fprintf('Figure 4e:\n')
fig4e(data);
fprintf('Figure 4f:\n')
fig4f(data, 'z-score');
%% s2
fprintf('Figure 4g:\n')
fig4g(data, tbounds, alignTo, 'z-score');
fprintf('Figure 4h:\n')
fig4h(data, tbounds, alignTo, 'z-score');
fprintf('Figure 4i:\n')
fig4i(data, tbounds, alignTo, 'z-score');
fprintf('Figure 4j:\n')
fig4j(data, tbounds, alignTo, 'z-score');
fprintf('Figure 4k:\n')
fig4k(data);
fprintf('Figure 4l:\n')
fig4l(data, 'z-score');
close all

% figure 5
fprintf('Figure 5:\n')
fprintf('Figure 5b:\n')
fig5b(animals, data_versions, kstates)
fprintf('Figure 5c:\n')
fig5c(data, k, data_version, ssd_version, psychver, animals)
fprintf('Figure 5d:\n')
fig5d(data, k, data_version, ssd_version, psychver, animals)
fprintf('Figure 5e:\n')
fig5g(data, k, data_version, ssd_version, psychver, animals)
fprintf('Figure 5f:\n')
fig5h(data, k, data_version, ssd_version, psychver, animals)
close all

% figure 6 
fprintf('Figure 6:\n')
fprintf('Figure 6a:\n')
fig6a(data, k, data_version, ssd_version, psychver, animals)
fprintf('Figure 6b:\n')
fig6b(data, k, data_version, ssd_version, psychver, animals)
fprintf('Figure 6c:\n')
fig6c(data, k, data_version, ssd_version, psychver, animals)
close all

% figure 7
%% s1
fprintf('Figure 7:\n')
fprintf('Figure 7a:\n')
fig7a(data, k, data_version, ssd_version, psychver, animals)
fprintf('Figure 7b:\n')
fig7b(data, k, data_version, ssd_version, psychver, animals)
fprintf('Figure 7c:\n')
fig7c(data, k, data_version, ssd_version, psychver, animals)
%% s2 
fprintf('Figure 7d:\n')
fig7d(data, k, data_version, ssd_version, psychver, animals)
fprintf('Figure 7e:\n')
fig7e(data, k, data_version, ssd_version, psychver, animals)
fprintf('Figure 7f:\n')
fig7f(data, k, data_version, ssd_version, psychver, animals)
close all

% figure 8 
fprintf('Figure 8:\n')
fprintf('Figure 8a:\n')
fig8a(data, k, data_version, ssd_version, psychver, animals, shuff_xcor)
fprintf('Figure 8b:\n')
fig8b(data, k, data_version, ssd_version, psychver, animals, shuff_xcor)
% fig8c(data, k, data_version, ssd_version, psychver, animals, shuff_ppfc)
% fig8e(data, k, data_version, ssd_version, psychver, animals, shuff_ps1)
close all

diary off 