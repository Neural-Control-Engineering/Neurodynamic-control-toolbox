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

addpath(genpath('Fig2/'))
Datastore = load('Combined-Datastore_created_14-Jan-2024.mat');
data = filterTrials(Datastore.Datastore, 'recording_location', 'mPFC-S1');
data(cellfun(@isempty, data.photometry_ch1),:) = [];
tbounds = [-0.5, 6];
alignTo = 'stimulus';
ver = 'z-score';
peak_ver = 'atzero';

fig2b(data, tbounds, alignTo);
fig2c(data, tbounds, alignTo);
fig2d(data, tbounds, alignTo);
fig2e(data, tbounds, alignTo);
fig2f(data, tbounds, alignTo);
fig2g(data, tbounds, alignTo);
fig2h(data, tbounds, alignTo);
fig2i(data);
fig2jk(data);
