Datastore = load('~/Downloads/Combined-Datastore_created_14-Jan-2024.mat');
data = filterTrials(Datastore.Datastore, 'recording_location', 'mPFC-S1');
animals = fetchAnimals(data);
data(cellfun(@isempty, data.photometry_ch1),:) = [];
tbounds = [-0.5, 6.0];
alignTo = 'stimulus';

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
fig3c(data, 'z-score');
fig3d(data, 'z-score', 'atzero');

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
