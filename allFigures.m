% load and preprocess data 
diary ssd_stats.txt
addpath(genpath('./'))
Datastore = load('Combined-Datastore_created_14-Jan-2024.mat');
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
    'spontaneous_s1_stim', ...
    'spontaneous_mpfc_stim', ...
     };
data_version = 'spontaneous_pupil_stim_v2';
k = 4;
psychver = 'byanimal';

% basic session analysis 
session_ids = unique(data.session_id);
trials = zeros(length(session_ids),1);
durations = zeros(length(session_ids),1);
for s = 1:length(session_ids)
    session_id = session_ids{s};
    tmp = data(strcmp(data.session_id, session_id),:);
    trials(s) = size(tmp,1);
    durations(s) = tmp.stimulus_time(end) + 6;
end
fprintf(sprintf('Trials per session: %d +/- %d\n', mean(trials), ste(trials)))
fprintf(sprintf('Session duration (min): %d +/- %d\n', mean(durations ./ 60), ste(durations ./ 60)))

% Figure 1. Experimental setup and behavioral task. 
% A) Experimental set up. The illustration was created with biorender.com.
% B) Diagram of the tactile detection task.
% C) Response time for each stimulus. Gray lines indicate individual animals. 
% Dark line indicate the average across all session in this figure.
% D) Top: raster plot of the animal’s response around the presentation of tactile stimuli in an example session. 
% Bottom: histgram of licking response within the window of opportunity.
% E) Response probablity for each tactile stimulus.
% F) Perceptual sensitivity associated with tactile stimuli with different intensities.
fprintf('Figure 1:\n')
fprintf('Figure 1c:\n')
fig1c(data);
fprintf('Figure 1e:\n')
fig1e(data);
fprintf('Figure 1f:\n')
fig1f(data);
close all

% figure 2
% Figure 2. Pupil size dependent behavior. 
% A) Example segmentation of mouse pupil contour by DLC (top) and the histogram of pupil fluctuations (bottom).
% B) Pupil dilation evoked by the presentation of different tactile stimuli.
% C) Pupil dynamics around stimulus presentation for four different behavioral outcomes.
% D) Pupil dilation with different baseline pupil size.
% E) Scatter plot showing negative correlation between baseline pupil size and pupil dilation for an example session.
% F) Pearson’s correlation coefficients between baseline pupil size and pupil dilation for different behavioral outcomes.
% G-H) Quantification of baseline pupil size and dilation for different behavioral outcomes.
% I) Response time during low, medium, and high pupil-linked arousal levels.
% J-K) Response probablity and perceptual sensitivity during low, medium, and high pupil-linked arousal levels
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

% Figure 3. NE dynamics in S1 and mPFC during the tactile detection task. 
% A) IHC confirmation of successful expression of GRAB_NE in the Barrel cortex (S1) and
% medial prefrontal cortex (mPFC).
% B) Cross-correlation between NE dynamics in S1 and PFC.
% C) Cross-correlation between pre-stimulus NE dynamics in S1 and PFC in 
% hit, miss, correct rejection, and false alarm trials.
% D) Correlation coefficient at 0 s lag for different behavioral outcomes.
fprintf('Figure 3:\n')
fprintf('Figure 3b:\n')
shuff_xcor = fig3b(data, 'z-score');
fprintf('Figure 3c:\n')
fig3c(data, 'z-score', shuff_xcor);
fprintf('Figure 3d:\n')
fig3d(data, 'z-score', 'atzero', shuff_xcor);
close all

% Figure 4. NE dynamics in S1 and mPFC during the tactile detection task. 
% A) NE dynamics in S1 evoked by the presentation of different tactile stimuli.
% B) Task evokded NE dynamics in S1 in hit, miss, correct rejection and miss trials.
% C) Baseline NE level in S1 in hit, miss, correct rejection and miss trials.
% D) Mean increase in NE level in S1 in hit, miss, correct rejection and miss trials.
% E) Reaction times during the high, medium, and low terciles of baseline NE levels in S1.
% F) Pychometric curves during the high, medium, and low terciles of baseline NE levels in S1.
% G) NE dynamics in mPFC evoked by the presentation of different tactile stimuli.
% H) Task evokded NE dynamics in mPFC in hit, miss, correct rejection and miss trials.
% I) Baseline NE level in mPFC in hit, miss, correct rejection and miss trials.
% J) Mean increase in NE level in mPFC in hit, miss, correct rejection and miss trials.
% K) Reaction times during the high, medium, and low terciles of baseline NE levels in mPFC.
% L) Pychometric curves during the high, medium, and low terciles of baseline NE levels in mPFC
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

% figure 5 - grab NE signals for different baseline pupil area levels
fprintf('Figure 5:\n')
fprintf('Figure 5a and 5b:\n')
fig5ab(data, tbounds, alignTo, 'z-score');
close all

% figure 6 - summary of GLM-HMM modeling
fig6()
close all

% Figures 7 and 8 
dynamicsByState();
corrByState(shuff_xcor);

% Supplemental Figures 
suppFig1(data, tbounds, alignTo);
suppFig2(data);

diary off 