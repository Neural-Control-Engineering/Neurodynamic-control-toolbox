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

addpath(genpath('Fig4/'))
Datastore = load('Combined-Datastore_created_14-Jan-2024.mat');
data = filterTrials(Datastore.Datastore, 'recording_location', 'mPFC-S1');
data(cellfun(@isempty, data.photometry_ch1),:) = [];
tbounds = [-0.5, 6];
alignTo = 'stimulus';
ver = 'z-score';

fig4a(data, tbounds, alignTo, ver);
fig4b(data, tbounds, alignTo, ver);
fig4c(data, tbounds, alignTo, ver);
fig4d(data, tbounds, alignTo, ver);
fig4e(data);
fig4f(data, ver);
fig4g(data, tbounds, alignTo, ver);
fig4h(data, tbounds, alignTo, ver);
fig4i(data, tbounds, alignTo, ver);
fig4j(data, tbounds, alignTo, ver);
fig4k(data);
fig4l(data, ver);