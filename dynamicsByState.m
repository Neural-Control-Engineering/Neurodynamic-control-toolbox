Datastore = load('Combined-Datastore_created_14-Jan-2024.mat');
data = filterTrials(Datastore.Datastore, 'recording_location', 'mPFC-S1');
animals = fetchAnimals(data);
model = readtable('glmhmm_K3_state_assignments.csv');
model = model(strcmp(model.model, 'New'),:);
model(cellfun(@isempty, data.photometry_ch1),:) = [];
data(cellfun(@isempty, data.photometry_ch1),:) = [];
sessions = unique(data.session_id);
outcomes = {'Hit', 'Miss', 'CR', 'FA'};
alignTo = 'stimulus';
K = 3;
s1_ne = {};
mpfc_ne = {};
pupil = {};
for k = 1:K
    s1_ne{k} = {[], [], [], []};
    mpfc_ne{k} = {[], [], [], []};
    pupil{k} = {[], [], [], []};
end
tbounds = [-0.5, 6];
for s = 1:length(sessions)
    tmp = data(strcmp(data.session_id, sessions{s}),:);
    model_tmp = model(strcmp(model.session, sessions{s}),:);
    for k = 1:K 
        ktmp = tmp(model_tmp.state == (k-1),:);
        for o = 1:length(outcomes)
            otmp = ktmp(strcmp(ktmp.categorical_outcome, outcomes{o}),:);
            if ~isempty(otmp)
                [mpfc, s1, t] = avg_photo_traces(otmp, tbounds, alignTo, 'z-score');
                [p, pt] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
                if size(mpfc,1) > 1
                    s1_ne{k}{o} = [s1_ne{k}{o}; nanmean(s1)];
                    mpfc_ne{k}{o} = [mpfc_ne{k}{o}; nanmean(mpfc)];
                    pupil{k}{o} = [pupil{k}{o}; nanmean(p)];
                else 
                    s1_ne{k}{o} = [s1_ne{k}{o}; s1];
                    mpfc_ne{k}{o} = [mpfc_ne{k}{o}; mpfc];
                    pupil{k}{o} = [pupil{k}{o}; p];
                end 
            end 
        end 
    end 
end

pupil_fig = figure();
tl = tiledlayout(1,4);
axs = zeros(1,4);
cols = distinguishable_colors(K);
outcomes = {'Hit', 'Miss', 'Correct Rejection', 'False Alarm'};
for o = 1:length(outcomes) 
    axs(o) = nexttile; hold on;
    for k = 1:K 
        semshade(s1_ne{k}{o}, 0.3, cols(k,:), cols(k,:), t, 5);
    end 
    xlim(tbounds)
    title(outcomes{o}, 'FontSize', 16)
end
xlabel(tl, 'Time (s)', 'FontSize', 16)
ylabel(tl, 'NE in S1 (z-score)', 'FontSize', 16)
unifyYLimits(pupil_fig);

mpfc_fig = figure();
tl = tiledlayout(1,4);
axs = zeros(1,4);
cols = distinguishable_colors(K);
outcomes = {'Hit', 'Miss', 'Correct Rejection', 'False Alarm'};
for o = 1:length(outcomes) 
    axs(o) = nexttile; hold on;
    for k = 1:K 
        semshade(mpfc_ne{k}{o}, 0.3, cols(k,:), cols(k,:), t, 5);
    end 
    xlim(tbounds)
    title(outcomes{o}, 'FontSize', 16)
end
xlabel(tl, 'Time (s)', 'FontSize', 16)
ylabel(tl, 'NE in mPFC (z-score)', 'FontSize', 16)
unifyYLimits(mpfc_fig);

s1_fig = figure();
tl = tiledlayout(1,4);
axs = zeros(1,4);
cols = distinguishable_colors(K);
outcomes = {'Hit', 'Miss', 'Correct Rejection', 'False Alarm'};
for o = 1:length(outcomes) 
    axs(o) = nexttile; hold on;
    for k = 1:K 
        semshade(pupil{k}{o}, 0.3, cols(k,:), cols(k,:), pt, 5);
    end 
    xlim(tbounds)
    title(outcomes{o}, 'FontSize', 16)
end
xlabel(tl, 'Time (s)', 'FontSize', 16)
ylabel(tl, 'Pupil Area (z-score)', 'FontSize', 16)
unifyYLimits(s1_fig);

pupil_hit_mat = [];
s1_hit_mat = [];
mpfc_hit_mat = [];
state_hit_mat = [];
pupil_miss_mat = [];
s1_miss_mat = [];
mpfc_miss_mat = [];
state_miss_mat = [];
pupil_cr_mat = [];
s1_cr_mat = [];
mpfc_cr_mat = [];
state_cr_mat = [];
pupil_fa_mat = [];
s1_fa_mat = [];
mpfc_fa_mat = [];
state_fa_mat = [];
for k = 1:length(pupil)
    o = 1;
    pupil_hit_mat = [pupil_hit_mat; pupil{k}{o}];
    s1_hit_mat = [s1_hit_mat; s1_ne{k}{o}];
    mpfc_hit_mat = [mpfc_hit_mat; mpfc_ne{k}{o}];
    state_hit_mat = [state_hit_mat; repmat(k,size(pupil{k}{o},1),1)];
    o = 2;
    pupil_miss_mat = [pupil_miss_mat; pupil{k}{o}];
    s1_miss_mat = [s1_miss_mat; s1_ne{k}{o}];
    mpfc_miss_mat = [mpfc_miss_mat; mpfc_ne{k}{o}];
    state_miss_mat = [state_miss_mat; repmat(k,size(pupil{k}{o},1),1)];
    o = 3;
    pupil_cr_mat = [pupil_cr_mat; pupil{k}{o}];
    s1_cr_mat = [s1_cr_mat; s1_ne{k}{o}];
    mpfc_cr_mat = [mpfc_cr_mat; mpfc_ne{k}{o}];
    state_cr_mat = [state_cr_mat; repmat(k,size(pupil{k}{o},1),1)];
    o = 4;
    pupil_fa_mat = [pupil_fa_mat; pupil{k}{o}];
    s1_fa_mat = [s1_fa_mat; s1_ne{k}{o}];
    mpfc_fa_mat = [mpfc_fa_mat; mpfc_ne{k}{o}];
    state_fa_mat = [state_fa_mat; repmat(k,size(pupil{k}{o},1),1)];
end

tbl = table(state_hit_mat, pupil_hit_mat(:,1), 'VariableNames', {'state', 't0'});
for c = 2:size(pupil_hit_mat,2)
    tbl = [tbl, table(pupil_hit_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
end
rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', pt);
fprintf('Pupil Hit:\n')
ranova(rm)

s1_hit_mat = s1_hit_mat(:,t > 0 & t <= 5); 
time = t(t > 0 & t <= 5);
tbl = table(state_hit_mat, s1_hit_mat(:,1), 'VariableNames', {'state', 't0'});
for c = 2:size(s1_hit_mat,2)
    tbl = [tbl, table(s1_hit_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
end
rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', time);
fprintf('S1 Hit:\n')
ranova(rm)

mpfc_hit_mat = mpfc_hit_mat(:,t > 0 & t <= 5); 
time = t(t > 0 & t <= 5);
tbl = table(state_hit_mat, mpfc_hit_mat(:,1), 'VariableNames', {'state', 't0'});
for c = 2:size(mpfc_hit_mat,2)
    tbl = [tbl, table(mpfc_hit_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
end
rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', time);
fprintf('mPFC Hit:\n')
ranova(rm)

tbl = table(state_miss_mat, pupil_miss_mat(:,1), 'VariableNames', {'state', 't0'});
for c = 2:size(pupil_miss_mat,2)
    tbl = [tbl, table(pupil_miss_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
end
rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', pt);
fprintf('Pupil Miss:\n')
ranova(rm)

s1_miss_mat = s1_miss_mat(:,t > 0 & t <= 5); 
time = t(t > 0 & t <= 5);
tbl = table(state_miss_mat, s1_miss_mat(:,1), 'VariableNames', {'state', 't0'});
for c = 2:size(s1_miss_mat,2)
    tbl = [tbl, table(s1_miss_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
end
rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', time);
fprintf('S1 Miss:\n')
ranova(rm)

mpfc_miss_mat = mpfc_miss_mat(:,t > 0 & t <= 5); 
time = t(t > 0 & t <= 5);
tbl = table(state_miss_mat, mpfc_miss_mat(:,1), 'VariableNames', {'state', 't0'});
for c = 2:size(mpfc_miss_mat,2)
    tbl = [tbl, table(mpfc_miss_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
end
rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', time);
fprintf('mPFC Miss:\n')
ranova(rm)

s1_cr_mat = s1_cr_mat(:,t > 0 & t <= 5); 
time = t(t > 0 & t <= 5);
tbl = table(state_cr_mat, s1_cr_mat(:,1), 'VariableNames', {'state', 't0'});
for c = 2:size(s1_cr_mat,2)
    tbl = [tbl, table(s1_cr_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
end
rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', time);
fprintf('S1 CR:\n')
ranova(rm)

mpfc_cr_mat = mpfc_cr_mat(:,t > 0 & t <= 5); 
time = t(t > 0 & t <= 5);
tbl = table(state_cr_mat, mpfc_cr_mat(:,1), 'VariableNames', {'state', 't0'});
for c = 2:size(mpfc_cr_mat,2)
    tbl = [tbl, table(mpfc_cr_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
end
rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', time);
fprintf('mPFC CR:\n')
ranova(rm)

tbl = table(state_fa_mat, pupil_fa_mat(:,1), 'VariableNames', {'state', 't0'});
for c = 2:size(pupil_fa_mat,2)
    tbl = [tbl, table(pupil_fa_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
end
rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', pt);
fprintf('Pupil FA:\n')
ranova(rm)

s1_fa_mat = s1_fa_mat(:,t > 0 & t <= 5); 
time = t(t > 0 & t <= 5);
tbl = table(state_fa_mat, s1_fa_mat(:,1), 'VariableNames', {'state', 't0'});
for c = 2:size(s1_fa_mat,2)
    tbl = [tbl, table(s1_fa_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
end
rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', time);
fprintf('S1 FA:\n')
ranova(rm)

mpfc_fa_mat = mpfc_fa_mat(:,t > 0 & t <= 5); 
time = t(t > 0 & t <= 5);
tbl = table(state_fa_mat, mpfc_fa_mat(:,1), 'VariableNames', {'state', 't0'});
for c = 2:size(mpfc_fa_mat,2)
    tbl = [tbl, table(mpfc_fa_mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
end
rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', time);
fprintf('mPFC FA:\n')
ranova(rm)
