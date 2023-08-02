% clc; clear; clf;

dstor = load("C:\Users\Gabog\Downloads\drive-download-20230605T151012Z-001\240-R-mPFC-S1-NE_Datastore_created_05-Jun-2023.mat");
% Datastore = dstor.alldat;
Datastore = dstor.Datastore;
% Datastore = dstor.combinedTable;

generateAdjacentPairs = @(array) [array(1:end-1).' array(2:end).'];

animal_num = "2458";

bins = [0, .2, .4, .6, .8, 1.]; %must include 0 and 1
bin_spans = generateAdjacentPairs(bins).*100;
bin_spans = string(bin_spans(:, 1)) + "-" + string(bin_spans(:, 2)) + "%";
bin_spans = bin_spans';

sieved_datastore = zeros(1, 3, length(bins)-1);

if isa(Datastore.photometry_5pctl_ch1,'cell')
    valid_ch1 = find(~cellfun(@isempty,Datastore.photometry_5pctl_ch1));
else
    valid_ch1 = 1:length(Datastore.photometry_5pctl_ch1);
end
if isa(Datastore.photometry_5pctl_ch2,'cell')
    valid_ch2 = find(~cellfun(@isempty,Datastore.photometry_5pctl_ch2));
else
    valid_ch2 = 1:length(Datastore.photometry_5pctl_ch2);
end
if isa(Datastore.photometry_5pctl_ch2,'cell')
    valid_pupil = find(~cellfun(@isempty,Datastore.pupil_5pctl));
else
    valid_pupil = 1:length(Datastore.pupil_5pctl);
end
valid_trials = union(valid_ch1, valid_ch2);
valid_trials = intersect(valid_trials, valid_pupil);

Datastore = Datastore(valid_trials, :);

[r, c] = size(Datastore);

if isa(Datastore.photometry_5pctl_ch1,'cell')
    ch1_5 = cell2mat(Datastore.photometry_5pctl_ch1);
    ch1_95 = cell2mat(Datastore.photometry_95pctl_ch1);
else
    ch1_5 = Datastore.photometry_5pctl_ch1;
    ch1_95 = Datastore.photometry_95pctl_ch1;
end
if isa(Datastore.photometry_5pctl_ch2,'cell')
    ch2_5 = cell2mat(Datastore.photometry_5pctl_ch2);
    ch2_95 = cell2mat(Datastore.photometry_95pctl_ch2);
else
    ch2_5 = Datastore.photometry_5pctl_ch2;
    ch2_95 = Datastore.photometry_95pctl_ch2;
end
if isa(Datastore.pupil_5pctl,'cell')
    pupil_5 = cell2mat(Datastore.pupil_5pctl);
    pupil_95 = cell2mat(Datastore.pupil_95pctl);
else
    pupil_5 = Datastore.pupil_5pctl;
    pupil_95 = Datastore.pupil_95pctl;
end

Datastore.ch1_mean_std = [(ch1_5 + ch1_95) / 2, (ch1_5 - ch1_95) / (2*-1.645)];
Datastore.ch2_mean_std = [(ch2_5 + ch2_95) / 2, (ch2_5 - ch2_95) / (2*-1.645)];
Datastore.pupil_mean_std = [(pupil_5 + pupil_95) / 2, (pupil_5 - pupil_95) / (2*-1.645)];

if isa(Datastore.photo_base_before_stim_ch1, 'cell')
    Datastore.ch1_cumprob = normcdf(cell2mat(Datastore.photo_base_before_stim_ch1), Datastore.ch1_mean_std(:, 1), Datastore.ch1_mean_std(:, 2));
    Datastore.ch2_cumprob = normcdf(cell2mat(Datastore.photo_base_before_stim_ch2), Datastore.ch2_mean_std(:, 1), Datastore.ch2_mean_std(:, 2));
else
    Datastore.ch1_cumprob = normcdf(Datastore.photo_base_before_stim_ch1, Datastore.ch1_mean_std(:, 1), Datastore.ch1_mean_std(:, 2));
    Datastore.ch2_cumprob = normcdf(Datastore.photo_base_before_stim_ch2, Datastore.ch2_mean_std(:, 1), Datastore.ch2_mean_std(:, 2));
end

if isa(Datastore.pupil_base_before_stimulus, 'cell')
    Datastore.pupil_cumprob = normcdf(cell2mat(Datastore.pupil_base_before_stimulus), Datastore.pupil_mean_std(:, 1), Datastore.pupil_mean_std(:, 2));
else
    Datastore.pupil_cumprob = normcdf(Datastore.pupil_base_before_stimulus, Datastore.pupil_mean_std(:, 1), Datastore.pupil_mean_std(:, 2));
end

Datastore.ch1_sieve = sieveArrayByBins(Datastore.ch1_cumprob, bins);
Datastore.ch2_sieve = sieveArrayByBins(Datastore.ch2_cumprob, bins);
Datastore.pupil_sieve = sieveArrayByBins(Datastore.pupil_cumprob, bins);

figure(1); hold on;
ttl = strcat("Psychometric Curve for ", animal_num, " via ", Datastore.photometry_region_ch1(1));
title(ttl);
colors = ['r-', 'b-', 'g-', 'c-', 'm-'];
for i = 1:length(unique(Datastore.ch1_sieve))
    idxs = Datastore.ch1_sieve == i;
    stimstrenths = table2array(Datastore(idxs, 10));
    responces = table2array(Datastore(idxs, 13));
%     bruh = cell2mat(table2array(Datastore(idxs, 10)));
    bruh = table2array(Datastore(idxs, 10));
    puffs = unique(bruh(:, 1));
    curve = calculatePsychometricCurvesSEM(stimstrenths, responces, 'Phase III', puffs);
    shadedErrorBar(curve(1, :)*10, curve(2, :), curve(3, :), 'lineprops', colors(i),'patchSaturation',0.075)
end
legend(bin_spans, 'location', "SE");
hold off;

figure(2); hold on;
ttl = strcat("Psychometric Curve for ", animal_num, " via ", Datastore.photometry_region_ch2(1));
title(ttl);

for i = 1:length(unique(Datastore.ch2_sieve))
    idxs = Datastore.ch2_sieve == i;
    stimstrenths = table2array(Datastore(idxs, 10));
    responces = table2array(Datastore(idxs, 13));
    bruh = table2array(Datastore(idxs, 10));
    puffs = unique(bruh(:, 1));
    curve = calculatePsychometricCurvesSEM(stimstrenths, responces, 'Phase III', puffs);
    shadedErrorBar(curve(1, :), curve(2, :), curve(3, :), 'lineprops',colors(i),'patchSaturation',0.075)
end
legend(bin_spans, 'location', "SE");
hold off;

figure(3); hold on;
ttl = strcat("Psychometric Curve for ", animal_num, " via Pupil");
title(ttl);
for i = 1:length(unique(Datastore.pupil_sieve))
    idxs = Datastore.pupil_sieve == i;
    stimstrenths = table2array(Datastore(idxs, 10));
    responces = table2array(Datastore(idxs, 13));
    bruh = table2array(Datastore(idxs, 10));
    puffs = unique(bruh(:, 1));
    curve = calculatePsychometricCurvesSEM(stimstrenths, responces, 'Phase III', puffs);
    shadedErrorBar(curve(1, :), curve(2, :), curve(3, :), 'lineprops',colors(i),'patchSaturation',0.075)
end
legend(bin_spans, 'location', "SE");
hold off;

% figure(1); hold on;
% ttl = strcat("Psychometric Curve for ", animal_num, " via ", Datastore.photometry_region_ch1(1));
% title(ttl);
% for i = 1:length(unique(Datastore.ch1_sieve))
%     idxs = Datastore.ch1_sieve == i;
%     stimstrenths = table2array(Datastore(idxs, 10));
%     responces = table2array(Datastore(idxs, 13));
% %     puffs = unique(table2array(Datastore(idxs, 10)));
%     bruh = cell2mat(table2array(Datastore(idxs, 10)));
%     puffs = unique(bruh(:, 1));
%     curve = calculatePsychometricCurves(cell2mat(stimstrenths), responces, 'Phase III', puffs);
%     plot(curve(1, :), curve(2, :))
% end
% legend(bin_spans, 'location', "SE");
% hold off;
% 
% figure(2); hold on;
% ttl = strcat("Psychometric Curve for ", animal_num, " via ", Datastore.photometry_region_ch2(1));
% title(ttl);
% for i = 1:length(unique(Datastore.ch2_sieve))
%     idxs = Datastore.ch2_sieve == i;
%     stimstrenths = table2array(Datastore(idxs, 10));
%     responces = table2array(Datastore(idxs, 13));
% %     puffs = unique(table2array(Datastore(idxs, 10)));
%     bruh = cell2mat(table2array(Datastore(idxs, 10)));
%     puffs = unique(bruh(:, 1));
%     curve = calculatePsychometricCurves(cell2mat(stimstrenths), responces, 'Phase III', puffs);
%     plot(curve(1, :), curve(2, :))
% end
% legend(bin_spans, 'location', "SE");
% hold off;