% Figure 3. NE dynamics in S1 and mPFC during the tactile detection task. 
% A) IHC confirmation of successful expression of GRAB_NE in the Barrel cortex (S1) and
% medial prefrontal cortex (mPFC).
% B) Cross-correlation between NE dynamics in S1 and PFC.
% C) Cross-correlation between pre-stimulus NE dynamics in S1 and PFC in 
% hit, miss, correct rejection, and false alarm trials.
% D) Correlation coefficient at 0 s lag for different behavioral outcomes.

addpath(genpath('Fig3/'))
Datastore = load('Combined-Datastore_created_14-Jan-2024.mat');
data = filterTrials(Datastore.Datastore, 'recording_location', 'mPFC-S1');
data(cellfun(@isempty, data.photometry_ch1),:) = [];
tbounds = [-0.5, 6];
alignTo = 'stimulus';
ver = 'z-score';
peak_ver = 'atzero';

fig3b(data, ver);
fig3c(data, ver);
fig3d(data, ver, peak_ver);