% Written by C.L.Slater 2022

% This is the primary script to coordinate analysis of all neurotransmitter
% exploration projects(in Matlab). See each descriptor below for a full explanation of the function
% of each section

% Begin by clearing workspace
clear; clc; close all;

% Set variables here
opt_windows.response_window = 0.5; %seconds
opt_windows.before_event = 2; %seconds
opt_windows.after_event = 6; %seconds
opt_windows.baseline = 0.5; %seconds
opt_windows.drop_buffer_start = 3*60; %seconds
opt_windows.drop_buffer_end = 0;   %seconds
opt_windows.debug_mode = true; 
opt_windows.MA_window = 0.15;

% Define parameter structure
[analysis_params] = setAnalysisParameters(opt_windows);
analysis_params.process_neuropixel = false;

% Determine which computer is running the script and set the various file locations accordingly
[paths] = setPaths("Project_Somatosensory-Signal-Detection");
%[paths] = setPaths("Project_Neurotransmitter-Exploration");
%%
% Create list of animals to select for processing with user input
[animals_to_load,analysis_progress,resets,wbar] = selectAnimals(paths);
%
for animal_number = 1:length(animals_to_load)
    
    waitbar(analysis_progress.completed_animals/analysis_progress.total_animals,wbar,[num2str(analysis_progress.completed_animals) '/' num2str(analysis_progress.total_animals) ' animals completed']);
    
    % Run through all files and find unprocessed data
    processDataStreams(animals_to_load{animal_number},paths,analysis_params,resets);

    analysis_progress.completed_animals = analysis_progress.  completed_animals + 1;
end

% Close wait bar
pause(.5)
close(wbar)

%% Make sure DLC data is up to date before compiling database
updateDLCData(paths,resets,"pupil");
%%
for i = 1:length(animals_to_load)
    analysis_params.phase_selection = {'Phase 0','Phase I','Phase II','Phase III'};
    [Datastore] = generateDatabase(paths,analysis_params,animals_to_load,"combined");
end

%% Generate full DB update
analysis_params.phase_selection = {'Phase II','Phase II with optogenetics'};
[Datastore] = generateDatabase(paths,analysis_params,animals_to_load);

%%
analysis_params.phase_selection = ['Phase 0'];
analysis_params.process_LFP = false;
[Datastore] = generateDatabase(paths,analysis_params,animals_to_load);
%%
analysis_params.phase_selection = ['Phase III'];
analysis_params.process_LFP = false;
[Datastore] = generateDatabase(paths,analysis_params,animals_to_load);
%% Load data
processed_trials_data = load('processed_trials_data.mat');
processed_trials_data = processed_trials_data.processed_trials_data;
%% ANALYSIS
filters.NT = ["NE"];
filters.Phase = ["Phase II","Phase III"];
NE_dstore = Dstore_fetchSubset(Datastore,filters);
save_loc = fullfile(paths.all_data_path,'Datastores');
save(fullfile(save_loc,strcat("NE_dstore_",string(datetime("today")),".mat")), 'NE_dstore','-v7.3');
%%
Dst













%%


state_data = load('state_data.mat');
%%

phases_to_include = "Phase III Cumulative";
NT_to_include = "NE";
exclude_missing_pupil = true;
exclude_missing_photometry = false;
exclude_poor_performance = false;

[cleaned_summary_of_sessions_1] = cleanCombinedData(NE_dstore,phases_to_include,exclude_missing_pupil,exclude_missing_photometry,exclude_poor_performance,NT_to_include);
%%
exclude_poor_performance = false;
[processed_trials_data] = cleanCombinedData(cleaned_summary_of_sessions_1,phases_to_include,exclude_missing_pupil,exclude_missing_photometry,exclude_poor_performance,NT_to_include);

%% Pupil analyses
exclude_missing_pupil = true;
temp_trials_data = cleanCombinedData(processed_trials_data,phases_to_include,exclude_missing_pupil,exclude_missing_photometry,exclude_poor_performance,NT_to_include);

idx_hit = [temp_trials_data{:,14}]' == "Hit";
idx_hit_2 =  [temp_trials_data{:,14}]' == "Hit" & [temp_trials_data{:,9}]' == 0.2;
idx_hit_5 = [temp_trials_data{:,14}]' == "Hit" & [temp_trials_data{:,9}]' == 0.5;
idx_hit_10 = [temp_trials_data{:,14}]' == "Hit" & [temp_trials_data{:,9}]' == 1;
idx_hit_20 = [temp_trials_data{:,14}]' == "Hit" & [temp_trials_data{:,9}]' == 2;
idx_hit_40 = [temp_trials_data{:,14}]' == "Hit" & [temp_trials_data{:,9}]' == 4;
idx_miss = [temp_trials_data{:,14}]' == "Miss";
idx_miss_2 =  [temp_trials_data{:,14}]' == "Miss" & [temp_trials_data{:,9}]' == 0.2;
idx_miss_5 = [temp_trials_data{:,14}]' == "Miss" & [temp_trials_data{:,9}]' == 0.5;
idx_miss_10 = [temp_trials_data{:,14}]' == "Miss" & [temp_trials_data{:,9}]' == 1;
idx_miss_20 = [temp_trials_data{:,14}]' == "Miss" & [temp_trials_data{:,9}]' == 2;
idx_miss_40 = [temp_trials_data{:,14}]' == "Miss" & [temp_trials_data{:,9}]' == 4;
idx_cr = [temp_trials_data{:,14}]' == "CR";
idx_fa = [temp_trials_data{:,14}]' == "FA";
idx_resp = [temp_trials_data{:,12}]' == true;
idx_withheld = [temp_trials_data{:,12}]' == false;
%%
% Lumped pupil baselines histogram
histogram([processed_trials_data{:,18}]',40,'Normalization','probability'); hold on;
xlim([0,100]); xlabel("Pupil baseline (% max)"); ylabel("Fraction of total trials");
%% Lumped PFC NE baselines histogram
histogram([processed_trials_data{:,23}]',40,'Normalization','probability'); hold on;
xlim([0,100]); xlabel("PFC NE baseline (% max)"); ylabel("Fraction of total trials");
%% Lumped PFC S1 baselines histogram
histogram([processed_trials_data{:,26}]',40,'Normalization','probability'); hold on;
xlim([0,100]); xlabel("S1 NE baseline (% max)"); ylabel("Fraction of total trials");
%% Behavioral outcome pupil
subplot_num = 1;
alpha = 0.65; %transparency
colors = ["#CCFFE5","#66FF66","#00FF00","#009900","#006600"];
ylims = [40,72];

x = -1*(time_before_stim-1/pupil_fs):1/pupil_fs:time_after_stim;
% Hit
sliced_data = [temp_trials_data{idx_hit,17}]';
y1 = mean(sliced_data,1);
sem1 = std(sliced_data,1)/sqrt(height(sliced_data));

sliced_data = [temp_trials_data{idx_hit_2,17}]';
y_2 = mean(sliced_data,1);
sem_2 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_trials_data{idx_hit_5,17}]';
y_5 = mean(sliced_data,1);
sem_5 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_trials_data{idx_hit_10,17}]';
y_10 = mean(sliced_data,1);
sem_10 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_trials_data{idx_hit_20,17}]';
y_20 = mean(sliced_data,1);
sem_20 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_trials_data{idx_hit_40,17}]';
y_40 = mean(sliced_data,1);
sem_40 = std(sliced_data,1)/sqrt(height(sliced_data));

labels = categorical({'2 psi','5 psi','10 psi','20 psi','40 psi'});
labels = reordercats(labels,{'2 psi','5 psi','10 psi','20 psi','40 psi'});

y_2_idx = find(y_2 == max(y_2));
y_5_idx = find(y_5 == max(y_5));
y_10_idx = find(y_10 == max(y_10));
y_20_idx = find(y_20 == max(y_20));
y_40_idx = find(y_40 == max(y_40));
pupil_response = [y_2(y_2_idx),y_5(y_5_idx),y_10(y_10_idx),y_20(y_20_idx),y_40(y_40_idx);sem_2(y_2_idx),sem_5(y_5_idx),sem_10(y_10_idx),sem_20(y_20_idx),sem_40(y_40_idx)];

figure;
b1 = bar(labels,pupil_response(1,:));
hold on;
er1 = errorbar(labels,pupil_response(1,:),pupil_response(2,:));
er1.Color = [0 0 0]; er1.LineStyle = 'none';
ylabel("Maximum pupil size following stimulus");
ylim([48,72])

figure
subplot(1,4,subplot_num);
% shadedErrorBar(x,y1,sem1,'transparent',1,'lineprops',{'color','#000000'}); hold on;
shadedErrorBar(x,y_2,sem_2,'transparent',1,'lineprops',{'color','#D81B60'}); hold on;
shadedErrorBar(x,y_5,sem_5,'transparent',1,'lineprops',{'color','#3949AB'}); hold on;
shadedErrorBar(x,y_10,sem_10,'transparent',1,'lineprops',{'color','#00ACC1'}); hold on;
shadedErrorBar(x,y_20,sem_20,'transparent',1,'lineprops',{'color','#00897B'}); hold on;
shadedErrorBar(x,y_40,sem_40,'transparent',1,'lineprops',{'color','#43A047'}); hold on;
ylim(ylims); title('Hit'); ylabel("Pupil area (% session max)");
%legend('aligned by stimulus','aligned by first lick')
subplot_num = subplot_num + 1;

% CR
sliced_data = [temp_trials_data{idx_cr,17}]';
y1 = mean(sliced_data,1);
sem1 = std(sliced_data,1)/sqrt(height(sliced_data));

subplot(1,4,subplot_num);
shadedErrorBar(x,y1,sem1,'transparent',1,'lineprops',{'color','#000000'}); hold on;
ylim(ylims); title('CR'); ylabel("Pupil area (% session max)");
%legend('aligned by stimulus')
subplot_num = subplot_num + 1;
% FA
sliced_data = [temp_trials_data{idx_fa,17}]';
y1 = mean(sliced_data,1);
sem1 = std(sliced_data,1)/sqrt(height(sliced_data));

subplot(1,4,subplot_num);
shadedErrorBar(x,y1,sem1,'transparent',1,'lineprops',{'color','#000000'}); hold on;
ylim(ylims); title('FA'); ylabel("zPupil area (% session max)");
%legend('aligned by stimulus','aligned by first lick')
subplot_num = subplot_num + 1;
% Miss
sliced_data = [temp_trials_data{idx_miss,17}]';
y1 = mean(sliced_data,1);
sem1 = std(sliced_data,1)/sqrt(height(sliced_data));

sliced_data = [temp_trials_data{idx_miss_2,17}]';
y_2 = mean(sliced_data,1);
sem_2 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_trials_data{idx_miss_5,17}]';
y_5 = mean(sliced_data,1);
sem_5 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_trials_data{idx_miss_10,17}]';
y_10 = mean(sliced_data,1);
sem_10 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_trials_data{idx_miss_20,17}]';
y_20 = mean(sliced_data,1);
sem_20 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_trials_data{idx_miss_40,17}]';
y_40 = mean(sliced_data,1);
sem_40 = std(sliced_data,1)/sqrt(height(sliced_data));

subplot(1,4,subplot_num);
%shadedErrorBar(x,y1,sem1,'transparent',1,'lineprops',{'color','#000000'}); hold on;
shadedErrorBar(x,y_2,sem_2,'transparent',1,'lineprops',{'color','#D81B60'}); hold on;
shadedErrorBar(x,y_5,sem_5,'transparent',1,'lineprops',{'color','#3949AB '}); hold on;
shadedErrorBar(x,y_10,sem_10,'transparent',1,'lineprops',{'color','#00ACC1 '}); hold on;
shadedErrorBar(x,y_20,sem_20,'transparent',1,'lineprops',{'color','#00897B'}); hold on;
shadedErrorBar(x,y_40,sem_40,'transparent',1,'lineprops',{'color','#43A047 '}); hold on;
ylim(ylims); title('Miss'); ylabel("Pupil area (% session max)");
%legend('aligned by stimulus')

labels = categorical({'2 psi','5 psi','10 psi','20 psi','40 psi'});
labels = reordercats(labels,{'2 psi','5 psi','10 psi','20 psi','40 psi'});

y_2_idx = find(y_2 == max(y_2));
y_5_idx = find(y_5 == max(y_5));
y_10_idx = find(y_10 == max(y_10));
y_20_idx = find(y_20 == max(y_20));
y_40_idx = find(y_40 == max(y_40));
pupil_response = [y_2(y_2_idx),y_5(y_5_idx),y_10(y_10_idx),y_20(y_20_idx),y_40(y_40_idx);sem_2(y_2_idx),sem_5(y_5_idx),sem_10(y_10_idx),sem_20(y_20_idx),sem_40(y_40_idx)];

figure;
b1 = bar(labels,pupil_response(1,:));
hold on;
er1 = errorbar(labels,pupil_response(1,:),pupil_response(2,:));
er1.Color = [0 0 0]; er1.LineStyle = 'none';
ylabel("Maximum pupil size following stimulus");
ylim([48,72])


%% Behavioral outcome PFC/S1 NE
subplot_num = 1;
alpha = 0.65; %transparency
colors = ["#CCFFE5","#66FF66","#00FF00","#009900","#006600"];

%region = 22; ylims = [41,50];% mPFC
region = 27; ylims = [45,55]; % S1

x = -1*(time_before_stim-1/photometry_fs):1/photometry_fs:time_after_stim;
% Hit
sliced_data = [temp_trials_data{idx_hit,region}]';
y1 = mean(sliced_data,1);
sem1 = std(sliced_data,1)/sqrt(height(sliced_data));

sliced_data = [temp_trials_data{idx_hit_2,region}]';
y_2 = mean(sliced_data,1);
sem_2 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_trials_data{idx_hit_5,region}]';
y_5 = mean(sliced_data,1);
sem_5 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_trials_data{idx_hit_10,region}]';
y_10 = mean(sliced_data,1);
sem_10 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_trials_data{idx_hit_20,region}]';
y_20 = mean(sliced_data,1);
sem_20 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_trials_data{idx_hit_40,region}]';
y_40 = mean(sliced_data,1);
sem_40 = std(sliced_data,1)/sqrt(height(sliced_data));

labels = categorical({'2 psi','5 psi','10 psi','20 psi','40 psi'});
labels = reordercats(labels,{'2 psi','5 psi','10 psi','20 psi','40 psi'});

y_2_idx = find(y_2 == max(y_2(1:2*photometry_fs)));
y_5_idx = find(y_5 == max(y_5(1:2*photometry_fs)));
y_10_idx = find(y_10 == max(y_10(1:2*photometry_fs)));
y_20_idx = find(y_20 == max(y_20(1:2*photometry_fs)));
y_40_idx = find(y_40 == max(y_40(1:2*photometry_fs)));
pupil_response = [y_2(y_2_idx),y_5(y_5_idx),y_10(y_10_idx),y_20(y_20_idx),y_40(y_40_idx);sem_2(y_2_idx),sem_5(y_5_idx),sem_10(y_10_idx),sem_20(y_20_idx),sem_40(y_40_idx)];

figure;
b1 = bar(labels,pupil_response(1,:));
hold on;
er1 = errorbar(labels,pupil_response(1,:),pupil_response(2,:));
er1.Color = [0 0 0]; er1.LineStyle = 'none';
ylabel("Maximum NE following stimulus (% session max)");
ylim(ylims);

figure
subplot(1,4,subplot_num);
shadedErrorBar(x,y1,sem1,'transparent',1,'lineprops',{'color','#000000'}); hold on;
% shadedErrorBar(x,y_2,sem_2,'transparent',1,'lineprops',{'color','#ABEBC6'}); hold on;
% shadedErrorBar(x,y_5,sem_5,'transparent',1,'lineprops',{'color','#A9DFBF'}); hold on;
% shadedErrorBar(x,y_10,sem_10,'transparent',1,'lineprops',{'color','#52BE80'}); hold on;
% shadedErrorBar(x,y_20,sem_20,'transparent',1,'lineprops',{'color','#229954'}); hold on;
% shadedErrorBar(x,y_40,sem_40,'transparent',1,'lineprops',{'color','#145A32'}); hold on;
ylim(ylims); title('Hit'); ylabel("Norepinephrine (% session max)");
subplot_num = subplot_num + 1;
% CR
sliced_data = [temp_trials_data{idx_cr,region}]';
y1 = mean(sliced_data,1);
sem1 = std(sliced_data,1)/sqrt(height(sliced_data));

subplot(1,4,subplot_num);
shadedErrorBar(x,y1,sem1,'transparent',1,'lineprops',{'color','#000000'}); hold on;
ylim(ylims); title('CR'); ylabel("Norepinephrine (% session max)");
%legend('aligned by stimulus')
subplot_num = subplot_num + 1;
% FA
sliced_data = [temp_trials_data{idx_fa,region}]';
y1 = mean(sliced_data,1);
sem1 = std(sliced_data,1)/sqrt(height(sliced_data));

subplot(1,4,subplot_num);
shadedErrorBar(x,y1,sem1,'transparent',1,'lineprops',{'color','#000000'}); hold on;
ylim(ylims); title('FA'); ylabel("Norepinephrine (% session max)");
subplot_num = subplot_num + 1;
% Miss
sliced_data = [temp_trials_data{idx_miss,region}]';
y1 = mean(sliced_data,1);
sem1 = std(sliced_data,1)/sqrt(height(sliced_data));

sliced_data = [temp_trials_data{idx_miss_2,region}]';
y_2 = mean(sliced_data,1);
sem_2 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_trials_data{idx_miss_5,region}]';
y_5 = mean(sliced_data,1);
sem_5 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_trials_data{idx_miss_10,region}]';
y_10 = mean(sliced_data,1);
sem_10 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_trials_data{idx_miss_20,region}]';
y_20 = mean(sliced_data,1);
sem_20 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_trials_data{idx_miss_40,region}]';
y_40 = mean(sliced_data,1);
sem_40 = std(sliced_data,1)/sqrt(height(sliced_data));

subplot(1,4,subplot_num);
shadedErrorBar(x,y1,sem1,'transparent',1,'lineprops',{'color','#000000'}); hold on;
% shadedErrorBar(x,y_2,sem_2,'transparent',1,'lineprops',{'color','#ABEBC6'}); hold on;
% shadedErrorBar(x,y_5,sem_5,'transparent',1,'lineprops',{'color','#A9DFBF'}); hold on;
% shadedErrorBar(x,y_10,sem_10,'transparent',1,'lineprops',{'color','#52BE80'}); hold on;
% shadedErrorBar(x,y_20,sem_20,'transparent',1,'lineprops',{'color','#229954'}); hold on;
% shadedErrorBar(x,y_40,sem_40,'transparent',1,'lineprops',{'color','#145A32'}); hold on;
ylim(ylims); title('Miss'); ylabel("Norepinephrine (% session max)");

labels = categorical({'2 psi','5 psi','10 psi','20 psi','40 psi'});
labels = reordercats(labels,{'2 psi','5 psi','10 psi','20 psi','40 psi'});

y_2_idx = find(y_2 == max(y_2(1:2*photometry_fs)));
y_5_idx = find(y_5 == max(y_5(1:2*photometry_fs)));
y_10_idx = find(y_10 == max(y_10(1:2*photometry_fs)));
y_20_idx = find(y_20 == max(y_20(1:2*photometry_fs)));
y_40_idx = find(y_40 == max(y_40(1:2*photometry_fs)));
pupil_response = [y_2(y_2_idx),y_5(y_5_idx),y_10(y_10_idx),y_20(y_20_idx),y_40(y_40_idx);sem_2(y_2_idx),sem_5(y_5_idx),sem_10(y_10_idx),sem_20(y_20_idx),sem_40(y_40_idx)];

figure;
b1 = bar(labels,pupil_response(1,:));
hold on;
er1 = errorbar(labels,pupil_response(1,:),pupil_response(2,:));
er1.Color = [0 0 0]; er1.LineStyle = 'none';
ylabel("Maximum NE following stimulus (% session max)");
ylim(ylims);

%% Pupil baseline by outcome
FA = mean([temp_trials_data{idx_fa,18}]);
FA_sem = std([temp_trials_data{idx_fa,18}])/sqrt(length([temp_trials_data{idx_fa,18}]));
Hit = mean([temp_trials_data{idx_hit,18}]);
Hit_sem = std([temp_trials_data{idx_hit,18}])/sqrt(length([temp_trials_data{idx_hit,18}]));
Hit_2 = mean([temp_trials_data{idx_hit_2,18}]);
Hit_sem_2 = std([temp_trials_data{idx_hit_2,18}])/sqrt(length([temp_trials_data{idx_hit_2,18}]));
Hit_5 = mean([temp_trials_data{idx_hit_5,18}]);
Hit_sem_5 = std([temp_trials_data{idx_hit_5,18}])/sqrt(length([temp_trials_data{idx_hit_5,18}]));
Hit_10 = mean([temp_trials_data{idx_hit_10,18}]);
Hit_sem_10 = std([temp_trials_data{idx_hit_10,18}])/sqrt(length([temp_trials_data{idx_hit_10,18}]));
Hit_20 = mean([temp_trials_data{idx_hit_20,18}]);
Hit_sem_20 = std([temp_trials_data{idx_hit_20,18}])/sqrt(length([temp_trials_data{idx_hit_20,18}]));
Hit_40 = mean([temp_trials_data{idx_hit_40,18}]);
Hit_sem_40 = std([temp_trials_data{idx_hit_40,18}])/sqrt(length([temp_trials_data{idx_hit_40,18}]));
Miss = mean([temp_trials_data{idx_miss,18}]);
Miss_sem = std([temp_trials_data{idx_miss,18}])/sqrt(length([temp_trials_data{idx_miss,18}]));
Miss_2 = mean([temp_trials_data{idx_miss_2,18}]);
Miss_sem_2 = std([temp_trials_data{idx_miss_2,18}])/sqrt(length([temp_trials_data{idx_miss_2,18}]));
Miss_5 = mean([temp_trials_data{idx_miss_5,18}]);
Miss_sem_5 = std([temp_trials_data{idx_miss_5,18}])/sqrt(length([temp_trials_data{idx_miss_5,18}]));
Miss_10 = mean([temp_trials_data{idx_miss_10,18}]);
Miss_sem_10 = std([temp_trials_data{idx_miss_10,18}])/sqrt(length([temp_trials_data{idx_miss_10,18}]));
Miss_20 = mean([temp_trials_data{idx_miss_20,18}]);
Miss_sem_20 = std([temp_trials_data{idx_miss_20,18}])/sqrt(length([temp_trials_data{idx_miss_20,18}]));
Miss_40 = mean([temp_trials_data{idx_miss_40,18}]);
Miss_sem_40 = std([temp_trials_data{idx_miss_40,18}])/sqrt(length([temp_trials_data{idx_miss_40,18}]));
CR = mean([temp_trials_data{idx_cr,18}]);
CR_sem = std([temp_trials_data{idx_cr,18}])/sqrt(length([temp_trials_data{idx_cr,18}]));
Responded = mean([temp_trials_data{idx_resp,18}]);
Responded_sem = std([temp_trials_data{idx_resp,18}])/sqrt(length([temp_trials_data{idx_resp,18}]));
Withheld = mean([temp_trials_data{idx_withheld,18}]);
Withheld_sem = std([temp_trials_data{idx_withheld,18}])/sqrt(length([temp_trials_data{idx_withheld,18}]));
%
labels = categorical({'FA','Hit','Miss','CR','Responded','Withheld'});
labels = reordercats(labels,{'FA','Hit','Miss','CR','Responded','Withheld'});

baselines = [FA, Hit, Miss, CR, Responded, Withheld; FA_sem, Hit_sem, Miss_sem, CR_sem, Responded_sem, Withheld_sem];

figure
b1 = bar(labels,baselines(1,:));
hold on;
er1 = errorbar(labels,baselines(1,:),baselines(2,:));
er1.Color = [0 0 0]; er1.LineStyle = 'none';
ylabel("Pupil baseline (% max size)");
ylim([44,50])
%
labels = categorical({'2 psi','5 psi','10 psi','20 psi','40 psi'});
labels = reordercats(labels,{'2 psi','5 psi','10 psi','20 psi','40 psi'});

baselines = [Hit_2, Hit_5, Hit_10, Hit_20, Hit_40; Hit_sem_2, Hit_sem_5, Hit_sem_10, Hit_sem_20, Hit_sem_40];

figure
b2 = bar(labels,baselines(1,:));
hold on;
er2 = errorbar(labels,baselines(1,:),baselines(2,:));
er2.Color = [0 0 0]; er2.LineStyle = 'none';
ylabel("Pupil baseline (% max size)");
ylim([44,50])
%
labels = categorical({'2 psi','5 psi','10 psi','20 psi','40 psi'});
labels = reordercats(labels,{'2 psi','5 psi','10 psi','20 psi','40 psi'});

baselines = [Miss_2, Miss_5, Miss_10, Miss_20, Miss_40; Miss_sem_2, Miss_sem_5, Miss_sem_10, Miss_sem_20, Miss_sem_40];

figure
b3 = bar(labels,baselines(1,:));
hold on;
er3 = errorbar(labels,baselines(1,:),baselines(2,:));
er3.Color = [0 0 0]; er3.LineStyle = 'none';
ylabel("Pupil baseline (% max size)");
ylim([44,50])
%% PFC/S1 baseline by outcome
%region = 23; ylims=[41,46]; % PFC
region = 28; ylims=[45,52]; % S1
FA = mean([temp_trials_data{idx_fa,region}]);
FA_sem = std([temp_trials_data{idx_fa,region}])/sqrt(length([temp_trials_data{idx_fa,region}]));
Hit = mean([temp_trials_data{idx_hit,region}]);
Hit_sem = std([temp_trials_data{idx_hit,region}])/sqrt(length([temp_trials_data{idx_hit,region}]));
Hit_2 = mean([temp_trials_data{idx_hit_2,region}]);
Hit_sem_2 = std([temp_trials_data{idx_hit_2,region}])/sqrt(length([temp_trials_data{idx_hit_2,region}]));
Hit_5 = mean([temp_trials_data{idx_hit_5,region}]);
Hit_sem_5 = std([temp_trials_data{idx_hit_5,region}])/sqrt(length([temp_trials_data{idx_hit_5,region}]));
Hit_10 = mean([temp_trials_data{idx_hit_10,region}]);
Hit_sem_10 = std([temp_trials_data{idx_hit_10,region}])/sqrt(length([temp_trials_data{idx_hit_10,region}]));
Hit_20 = mean([temp_trials_data{idx_hit_20,region}]);
Hit_sem_20 = std([temp_trials_data{idx_hit_20,region}])/sqrt(length([temp_trials_data{idx_hit_20,region}]));
Hit_40 = mean([temp_trials_data{idx_hit_40,region}]);
Hit_sem_40 = std([temp_trials_data{idx_hit_40,region}])/sqrt(length([temp_trials_data{idx_hit_40,region}]));
Miss = mean([temp_trials_data{idx_miss,region}]);
Miss_sem = std([temp_trials_data{idx_miss,region}])/sqrt(length([temp_trials_data{idx_miss,region}]));
Miss_2 = mean([temp_trials_data{idx_miss_2,region}]);
Miss_sem_2 = std([temp_trials_data{idx_miss_2,region}])/sqrt(length([temp_trials_data{idx_miss_2,region}]));
Miss_5 = mean([temp_trials_data{idx_miss_5,region}]);
Miss_sem_5 = std([temp_trials_data{idx_miss_5,region}])/sqrt(length([temp_trials_data{idx_miss_5,region}]));
Miss_10 = mean([temp_trials_data{idx_miss_10,region}]);
Miss_sem_10 = std([temp_trials_data{idx_miss_10,region}])/sqrt(length([temp_trials_data{idx_miss_10,region}]));
Miss_20 = mean([temp_trials_data{idx_miss_20,region}]);
Miss_sem_20 = std([temp_trials_data{idx_miss_20,region}])/sqrt(length([temp_trials_data{idx_miss_20,region}]));
Miss_40 = mean([temp_trials_data{idx_miss_40,region}]);
Miss_sem_40 = std([temp_trials_data{idx_miss_40,region}])/sqrt(length([temp_trials_data{idx_miss_40,region}]));
CR = mean([temp_trials_data{idx_cr,region}]);
CR_sem = std([temp_trials_data{idx_cr,region}])/sqrt(length([temp_trials_data{idx_cr,region}]));
Responded = mean([temp_trials_data{idx_resp,region}]);
Responded_sem = std([temp_trials_data{idx_resp,region}])/sqrt(length([temp_trials_data{idx_resp,region}]));
Withheld = mean([temp_trials_data{idx_withheld,region}]);
Withheld_sem = std([temp_trials_data{idx_withheld,region}])/sqrt(length([temp_trials_data{idx_withheld,region}]));

labels = categorical({'FA','Hit','Miss','CR','Responded','Withheld'});
labels = reordercats(labels,{'FA','Hit','Miss','CR','Responded','Withheld'});

baselines = [FA, Hit, Miss, CR, Responded, Withheld; FA_sem, Hit_sem, Miss_sem, CR_sem, Responded_sem, Withheld_sem];

b1 = bar(labels,baselines(1,:));
hold on;
er1 = errorbar(labels,baselines(1,:),baselines(2,:));
er1.Color = [0 0 0]; er1.LineStyle = 'none';
ylabel("NE baseline (% session max)");
ylim(ylims)
%
labels = categorical({'2 psi','5 psi','10 psi','20 psi','40 psi'});
labels = reordercats(labels,{'2 psi','5 psi','10 psi','20 psi','40 psi'});

baselines = [Hit_2, Hit_5, Hit_10, Hit_20, Hit_40; Hit_sem_2, Hit_sem_5, Hit_sem_10, Hit_sem_20, Hit_sem_40];

figure
b2 = bar(labels,baselines(1,:));
hold on;
er2 = errorbar(labels,baselines(1,:),baselines(2,:));
er2.Color = [0 0 0]; er2.LineStyle = 'none';
ylabel("NE baseline (% session max)");
ylim(ylims)
%
labels = categorical({'2 psi','5 psi','10 psi','20 psi','40 psi'});
labels = reordercats(labels,{'2 psi','5 psi','10 psi','20 psi','40 psi'});

baselines = [Miss_2, Miss_5, Miss_10, Miss_20, Miss_40; Miss_sem_2, Miss_sem_5, Miss_sem_10, Miss_sem_20, Miss_sem_40];

figure
b3 = bar(labels,baselines(1,:));
hold on;
er3 = errorbar(labels,baselines(1,:),baselines(2,:));
er3.Color = [0 0 0]; er3.LineStyle = 'none';
ylabel("NE baseline (% session max)");
ylim(ylims)
%% Correlation coefficient by outcome pupil & mPFC
FA = mean([temp_trials_data{idx_fa,30}],'omitnan');
FA_sem = std([temp_trials_data{idx_fa,30}],'omitnan')/sqrt(length([temp_trials_data{idx_fa,30}]));
Hit = mean([temp_trials_data{idx_hit,30}],'omitnan');
Hit_sem = std([temp_trials_data{idx_hit,30}],'omitnan')/sqrt(length([temp_trials_data{idx_hit,30}]));
Miss = mean([temp_trials_data{idx_miss,30}],'omitnan');
Miss_sem = std([temp_trials_data{idx_miss,30}],'omitnan')/sqrt(length([temp_trials_data{idx_miss,30}]));
CR = mean([temp_trials_data{idx_cr,30}],'omitnan');
CR_sem = std([temp_trials_data{idx_cr,30}],'omitnan')/sqrt(length([temp_trials_data{idx_cr,30}]));
Responded = mean([temp_trials_data{idx_resp,30}],'omitnan');
Responded_sem = std([temp_trials_data{idx_resp,30}],'omitnan')/sqrt(length([temp_trials_data{idx_resp,30}]));
Withheld = mean([temp_trials_data{idx_withheld,30}],'omitnan');
Withheld_sem = std([temp_trials_data{idx_withheld,30}],'omitnan')/sqrt(length([temp_trials_data{idx_withheld,30}]));

labels = categorical({'FA','Hit','Miss','CR','Responded','Withheld'});
labels = reordercats(labels,{'FA','Hit','Miss','CR','Responded','Withheld'});

baselines = [FA, Hit, Miss, CR, Responded, Withheld; FA_sem, Hit_sem, Miss_sem, CR_sem, Responded_sem, Withheld_sem];
figure
b2 = bar(labels,baselines(1,:));
hold on;
er2 = errorbar(labels,baselines(1,:),baselines(2,:));
er2.Color = [0 0 0]; er2.LineStyle = 'none';
ylabel("PCC between pupil and mPFC NE (1 second before stim)");
ylim([-.05,.05])
% Correlation coefficient by outcome pupil & S1
FA = mean([temp_trials_data{idx_fa,31}],'omitnan');
FA_sem = std([temp_trials_data{idx_fa,31}],'omitnan')/sqrt(length([temp_trials_data{idx_fa,31}]));
Hit = mean([temp_trials_data{idx_hit,31}],'omitnan');
Hit_sem = std([temp_trials_data{idx_hit,31}],'omitnan')/sqrt(length([temp_trials_data{idx_hit,31}]));
Miss = mean([temp_trials_data{idx_miss,31}],'omitnan');
Miss_sem = std([temp_trials_data{idx_miss,31}],'omitnan')/sqrt(length([temp_trials_data{idx_miss,31}]));
CR = mean([temp_trials_data{idx_cr,31}],'omitnan');
CR_sem = std([temp_trials_data{idx_cr,31}],'omitnan')/sqrt(length([temp_trials_data{idx_cr,31}]));
Responded = mean([temp_trials_data{idx_resp,31}],'omitnan');
Responded_sem = std([temp_trials_data{idx_resp,31}],'omitnan')/sqrt(length([temp_trials_data{idx_resp,31}]));
Withheld = mean([temp_trials_data{idx_withheld,31}],'omitnan');
Withheld_sem = std([temp_trials_data{idx_withheld,31}],'omitnan')/sqrt(length([temp_trials_data{idx_withheld,31}]));

labels = categorical({'FA','Hit','Miss','CR','Responded','Withheld'});
labels = reordercats(labels,{'FA','Hit','Miss','CR','Responded','Withheld'});

baselines = [FA, Hit, Miss, CR, Responded, Withheld; FA_sem, Hit_sem, Miss_sem, CR_sem, Responded_sem, Withheld_sem];
figure
b3 = bar(labels,baselines(1,:));
hold on;
er3 = errorbar(labels,baselines(1,:),baselines(2,:));
er3.Color = [0 0 0]; er3.LineStyle = 'none';
ylabel("PCC between pupil and S1 NE (1 second before stim)");
ylim([-.05,.05])
% Correlation coefficient by outcome mPFC S1
FA = mean([temp_trials_data{idx_fa,32}],'omitnan');
FA_sem = std([temp_trials_data{idx_fa,32}],'omitnan')/sqrt(length([temp_trials_data{idx_fa,32}]));
Hit = mean([temp_trials_data{idx_hit,32}],'omitnan');
Hit_sem = std([temp_trials_data{idx_hit,32}],'omitnan')/sqrt(length([temp_trials_data{idx_hit,32}]));
Miss = mean([temp_trials_data{idx_miss,32}],'omitnan');
Miss_sem = std([temp_trials_data{idx_miss,32}],'omitnan')/sqrt(length([temp_trials_data{idx_miss,32}]));
CR = mean([temp_trials_data{idx_cr,32}],'omitnan');
CR_sem = std([temp_trials_data{idx_cr,32}],'omitnan')/sqrt(length([temp_trials_data{idx_cr,32}]));
Responded = mean([temp_trials_data{idx_resp,32}],'omitnan');
Responded_sem = std([temp_trials_data{idx_resp,32}],'omitnan')/sqrt(length([temp_trials_data{idx_resp,32}]));
Withheld = mean([temp_trials_data{idx_withheld,32}],'omitnan');
Withheld_sem = std([temp_trials_data{idx_withheld,32}],'omitnan')/sqrt(length([temp_trials_data{idx_withheld,32}]));

labels = categorical({'FA','Hit','Miss','CR','Responded','Withheld'});
labels = reordercats(labels,{'FA','Hit','Miss','CR','Responded','Withheld'});

baselines = [FA, Hit, Miss, CR, Responded, Withheld; FA_sem, Hit_sem, Miss_sem, CR_sem, Responded_sem, Withheld_sem];
figure
b4 = bar(labels,baselines(1,:));
hold on;
er4 = errorbar(labels,baselines(1,:),baselines(2,:));
er4.Color = [0 0 0]; er4.LineStyle = 'none';
ylabel("PCC between mPFC NE and S1 NE (1 second before stim)");
%ylim([-.05,.05])
%% Psychometric curve by pupil baseline
training_phase = "Phase III";
percent_20_idx = [temp_trials_data{:,18}]' <= 10;
percent_40_idx = [temp_trials_data{:,18}]' > 10 & [temp_trials_data{:,18}]' <= 40;
percent_60_idx = [temp_trials_data{:,18}]' > 40 & [temp_trials_data{:,18}]' <= 60;
percent_80_idx = [temp_trials_data{:,18}]' > 60 & [temp_trials_data{:,18}]' <= 90;
percent_100_idx = [temp_trials_data{:,18}]' > 90 & [temp_trials_data{:,18}]' <= 100;

% temp = temp_trials_data(percent_20_idx,1:18);
% for i = 1:height(temp)
%     temp_stim = [temp{:,9}]';
%     temp_resp = [temp{:,12}]';
%     temp_reaction_time =  temp(~cellfun(@isempty,temp(:,11)),9:2:11);    
%     [curve_20] = calculatePsychometricCurves(temp_stim,temp_resp,training_phase,puff_values);
% end
% temp = temp_trials_data(percent_40_idx,1:18);
% for i = 1:height(temp)
%     temp_stim = [temp{:,9}]';
%     temp_resp = [temp{:,12}]';
%     temp_reaction_time =  temp(~cellfun(@isempty,temp(:,11)),9:2:11);    
%     [curve_40] = calculatePsychometricCurves(temp_stim,temp_resp,training_phase,puff_values);
% end    
% temp = temp_trials_data(percent_60_idx,1:18);
% for i = 1:height(temp)
%     temp_stim = [temp{:,9}]';
%     temp_resp = [temp{:,12}]';
%     temp_reaction_time =  temp(~cellfun(@isempty,temp(:,11)),9:2:11);    
%     [curve_60] = calculatePsychometricCurves(temp_stim,temp_resp,training_phase,puff_values);
% end
% temp = temp_trials_data(percent_80_idx,1:18);
% for i = 1:height(temp)
%     temp_stim = [temp{:,9}]';
%     temp_resp = [temp{:,12}]';
%     temp_reaction_time =  temp(~cellfun(@isempty,temp(:,11)),9:2:11);    
%     [curve_80] = calculatePsychometricCurves(temp_stim,temp_resp,training_phase,puff_values);
% end
% temp = temp_trials_data(percent_100_idx,1:18);
% for i = 1:height(temp)
%     temp_stim = [temp{:,9}]';
%     temp_resp = [temp{:,12}]';
%     temp_reaction_time =  temp(~cellfun(@isempty,temp(:,11)),9:2:11);    
%     [curve_100] = calculatePsychometricCurves(temp_stim,temp_resp,training_phase,puff_values);
% end
%%
%plot(puff_strengths,curve_20,LineWidth,1.5); hold on;
plot(stimulus_psi,curve_40,'LineWidth',1.5); hold on;
plot(stimulus_psi,curve_60,'LineWidth',1.5); hold on;
plot(stimulus_psi,curve_80,'LineWidth',1.5); hold on;
plot(stimulus_psi,curve_100,'LineWidth',1.5); hold on;
legend('Baseline 20-40% max','Baseline 40-60% max','Baseline 60-80% max','Baseline 80-100% max')
%% Plot psychometric curves for baseline pupil stratifications
unique_animals = unique([temp_trials_data{:,1}]');
curves_20 = zeros(0,length(stimulus_psi)); times_20 = zeros(0,length(stimulus_psi)); 
curves_40 = zeros(0,length(stimulus_psi)); times_40 = zeros(0,length(stimulus_psi));
curves_60 = zeros(0,length(stimulus_psi)); times_60 = zeros(0,length(stimulus_psi)); 
curves_80 = zeros(0,length(stimulus_psi)); times_80 = zeros(0,length(stimulus_psi)); 
curves_100 = zeros(0,length(stimulus_psi)); times_100 = zeros(0,length(stimulus_psi)); 
mPFC_baseline_20 = []; mPFC_baseline_40 = []; mPFC_baseline_60 = []; mPFC_baseline_80 = []; mPFC_baseline_100 = [];
S1_baseline_20 = []; S1_baseline_40 = []; S1_baseline_60 = []; S1_baseline_80 = []; S1_baseline_100 = [];
dprime_20 = []; dprime_40 = []; dprime_60 = []; dprime_80 = []; dprime_100 = [];
criterion_20 = []; criterion_40 = []; criterion_60 = []; criterion_80 = []; criterion_100 = [];

for i = 1:length(unique_animals)
    temp = temp_trials_data(contains([temp_trials_data{:,1}]',unique_animals(i)),:);
    unique_sessions = unique([temp{:,4}]');
    %disp(strcat(unique_animals(i)," has ", string(unique_sessions(end))," total phase III sessions"))
    curves_20_temp = zeros(0,length(stimulus_psi)); curves_40_temp = zeros(0,length(stimulus_psi)); curves_60_temp = zeros(0,length(stimulus_psi)); curves_80_temp = zeros(0,length(stimulus_psi)); curves_100_temp = zeros(0,length(stimulus_psi));
    times_20_temp = zeros(0,length(stimulus_psi)); times_40_temp = zeros(0,length(stimulus_psi)); times_60_temp = zeros(0,length(stimulus_psi)); times_80_temp = zeros(0,length(stimulus_psi)); times_100_temp = zeros(0,length(stimulus_psi));    
    for j = 1:length(unique_sessions)
        temp_2 = temp([temp{:,4}]' == unique_sessions(j),:);
        percent_20_idx = [temp_2{:,18}]' > 0 & [temp_2{:,18}]' <= 5; percent_20_idx_resp = [temp_2{:,18}]' <= 5 & (strcmp([temp_2{:,14}]','Hit') | strcmp([temp_2{:,14}]','FA')) & ~isnan([temp_2{:,11}]');
        percent_40_idx = [temp_2{:,18}]' > 20 & [temp_2{:,18}]' <= 40; percent_40_idx_resp = [temp_2{:,18}]' > 20 & [temp_2{:,18}]' <= 40 & (strcmp([temp_2{:,14}]','Hit') | strcmp([temp_2{:,14}]','FA')) & ~isnan([temp_2{:,11}]');
        percent_60_idx = [temp_2{:,18}]' > 40 & [temp_2{:,18}]' <= 60; percent_60_idx_resp = [temp_2{:,18}]' > 40 & [temp_2{:,18}]' <= 60 & (strcmp([temp_2{:,14}]','Hit') | strcmp([temp_2{:,14}]','FA')) & ~isnan([temp_2{:,11}]');
        percent_80_idx = [temp_2{:,18}]' > 60 & [temp_2{:,18}]' <= 80; percent_80_idx_resp = [temp_2{:,18}]' > 60 & [temp_2{:,18}]' <= 80 & (strcmp([temp_2{:,14}]','Hit') | strcmp([temp_2{:,14}]','FA')) & ~isnan([temp_2{:,11}]');
        percent_100_idx = [temp_2{:,18}]' > 95 & [temp_2{:,18}]' <= 100; percent_100_idx_resp = [temp_2{:,18}]' > 95 & [temp_2{:,18}]' <= 100 & (strcmp([temp_2{:,14}]','Hit') | strcmp([temp_2{:,14}]','FA')) & ~isnan([temp_2{:,11}]');        
        %temp_reaction_time =  temp_2(~cellfun(@isempty,temp_2(percent_20_idx,11)),9:2:11);    
        if ~isempty([temp_2{percent_20_idx,9}])
            curves_20_temp(j,:) = calculatePsychometricCurves([temp_2{percent_20_idx,9}]',[temp_2{percent_20_idx,12}]',training_phase,puff_values);
            times_20_temp(j,:) = calculateChronometricCurves([temp_2{percent_20_idx_resp,14}]',[temp_2{percent_20_idx_resp,11}]',[temp_2{percent_20_idx_resp,9}]',training_phase,puff_values);
        else
            curves_20_temp(j,:) = NaN(1,length(puff_values));
            times_20_temp(j,:) = NaN(1,length(puff_values));
        end
        curves_40_temp(j,:) = calculatePsychometricCurves([temp_2{percent_40_idx,9}]',[temp_2{percent_40_idx,12}]',training_phase,puff_values);
        times_40_temp(j,:) = calculateChronometricCurves([temp_2{percent_40_idx_resp,14}]',[temp_2{percent_40_idx_resp,11}]',[temp_2{percent_40_idx_resp,9}]',training_phase,puff_values);
        curves_60_temp(j,:) = calculatePsychometricCurves([temp_2{percent_60_idx,9}]',[temp_2{percent_60_idx,12}]',training_phase,puff_values);
        times_60_temp(j,:) = calculateChronometricCurves([temp_2{percent_60_idx_resp,14}]',[temp_2{percent_60_idx_resp,11}]',[temp_2{percent_60_idx_resp,9}]',training_phase,puff_values);
        curves_80_temp(j,:) = calculatePsychometricCurves([temp_2{percent_80_idx,9}]',[temp_2{percent_80_idx,12}]',training_phase,puff_values);
        times_80_temp(j,:) = calculateChronometricCurves([temp_2{percent_80_idx_resp,14}]',[temp_2{percent_80_idx_resp,11}]',[temp_2{percent_80_idx_resp,9}]',training_phase,puff_values);
        if ~isempty([temp_2{percent_100_idx,9}])
            curves_100_temp(j,:) = calculatePsychometricCurves([temp_2{percent_100_idx,9}]',[temp_2{percent_100_idx,12}]',training_phase,puff_values);
            times_100_temp(j,:) = calculateChronometricCurves([temp_2{percent_100_idx_resp,14}]',[temp_2{percent_100_idx_resp,11}]',[temp_2{percent_100_idx_resp,9}]',training_phase,puff_values);
        else
            curves_100_temp(j,:) = NaN(1,length(puff_values));
            times_100_temp(j,:) = NaN(1,length(puff_values));
        end
        mPFC_baseline_20 = vertcat(mPFC_baseline_20,[temp_2{percent_20_idx,23}]');
        S1_baseline_20 = vertcat(S1_baseline_20,[temp_2{percent_20_idx,27}]');
        mPFC_baseline_40 = vertcat(mPFC_baseline_40,[temp_2{percent_40_idx,23}]');
        S1_baseline_40 = vertcat(S1_baseline_40,[temp_2{percent_40_idx,27}]');
        mPFC_baseline_60 = vertcat(mPFC_baseline_60,[temp_2{percent_60_idx,23}]');
        S1_baseline_60 = vertcat(S1_baseline_60,[temp_2{percent_60_idx,27}]');
        mPFC_baseline_80 = vertcat(mPFC_baseline_80,[temp_2{percent_80_idx,23}]');
        S1_baseline_80 = vertcat(S1_baseline_80,[temp_2{percent_80_idx,27}]');
        mPFC_baseline_100 = vertcat(mPFC_baseline_100,[temp_2{percent_100_idx,23}]');
        S1_baseline_100 = vertcat(S1_baseline_100,[temp_2{percent_100_idx,27}]');

        seg = percent_20_idx;
        if ~isempty([temp_2{seg,14}])
            Hit_rate = sum([temp_2{seg,14}] == 'Hit')/(sum([temp_2{seg,14}] == 'Hit') + sum([temp_2{seg,14}] == 'Miss'));
            FA_rate = sum([temp_2{seg,14}] == 'FA')/(sum([temp_2{seg,14}] == 'FA') + sum([temp_2{seg,14}] == 'CR'));
        else
            Hit_rate = nan;
            FA_rate = nan;
        end
        if Hit_rate == 0; Hit_rate = 0.01; end; if Hit_rate == 1; Hit_rate = 0.99; end 
        if FA_rate == 0; FA_rate = 0.01; end; if FA_rate == 1; FA_rate = 0.99; end
        [dprime_20t,criterion_20t] = dprime_simple(Hit_rate,FA_rate);
        seg = percent_40_idx;
        Hit_rate = sum([temp_2{seg,14}] == 'Hit')/(sum([temp_2{seg,14}] == 'Hit') + sum([temp_2{seg,14}] == 'Miss'));
        FA_rate = sum([temp_2{seg,14}] == 'FA')/(sum([temp_2{seg,14}] == 'FA') + sum([temp_2{seg,14}] == 'CR'));
        if Hit_rate == 0; Hit_rate = 0.01; end; if Hit_rate == 1; Hit_rate = 0.99; end 
        if FA_rate == 0; FA_rate = 0.01; end; if FA_rate == 1; FA_rate = 0.99; end
        [dprime_40t,criterion_40t] = dprime_simple(Hit_rate,FA_rate);
        seg = percent_60_idx;
        Hit_rate = sum([temp_2{seg,14}] == 'Hit')/(sum([temp_2{seg,14}] == 'Hit') + sum([temp_2{seg,14}] == 'Miss'));
        FA_rate = sum([temp_2{seg,14}] == 'FA')/(sum([temp_2{seg,14}] == 'FA') + sum([temp_2{seg,14}] == 'CR'));
        if Hit_rate == 0; Hit_rate = 0.01; end; if Hit_rate == 1; Hit_rate = 0.99; end 
        if FA_rate == 0; FA_rate = 0.01; end; if FA_rate == 1; FA_rate = 0.99; end
        [dprime_60t,criterion_60t] = dprime_simple(Hit_rate,FA_rate);
        seg = percent_80_idx;
        Hit_rate = sum([temp_2{seg,14}] == 'Hit')/(sum([temp_2{seg,14}] == 'Hit') + sum([temp_2{seg,14}] == 'Miss'));
        FA_rate = sum([temp_2{seg,14}] == 'FA')/(sum([temp_2{seg,14}] == 'FA') + sum([temp_2{seg,14}] == 'CR'));
        if Hit_rate == 0; Hit_rate = 0.01; end; if Hit_rate == 1; Hit_rate = 0.99; end 
        if FA_rate == 0; FA_rate = 0.01; end; if FA_rate == 1; FA_rate = 0.99; end
        [dprime_80t,criterion_80t] = dprime_simple(Hit_rate,FA_rate);
        seg = percent_100_idx;
        if ~isempty([temp_2{seg,14}])
            Hit_rate = sum([temp_2{seg,14}] == 'Hit')/(sum([temp_2{seg,14}] == 'Hit') + sum([temp_2{seg,14}] == 'Miss'));
            FA_rate = sum([temp_2{seg,14}] == 'FA')/(sum([temp_2{seg,14}] == 'FA') + sum([temp_2{seg,14}] == 'CR'));
        end
        if Hit_rate == 0; Hit_rate = 0.01; end; if Hit_rate == 1; Hit_rate = 0.99; end 
        if FA_rate == 0; FA_rate = 0.01; end; if FA_rate == 1; FA_rate = 0.99; end
        [dprime_100t,criterion_100t] = dprime_simple(Hit_rate,FA_rate);

        dprime_20 = vertcat(dprime_20,dprime_20t);
        dprime_40 = vertcat(dprime_40,dprime_40t);
        dprime_60 = vertcat(dprime_60,dprime_60t);
        dprime_80 = vertcat(dprime_80,dprime_80t);
        dprime_100 = vertcat(dprime_100,dprime_100t);
        criterion_20 = vertcat(criterion_20,criterion_20t);
        criterion_40 = vertcat(criterion_40,criterion_40t);
        criterion_60 = vertcat(criterion_60,criterion_60t);
        criterion_80 = vertcat(criterion_80,criterion_80t);
        criterion_100 = vertcat(criterion_100,criterion_100t);
    end
    curves_20 = vertcat(curves_20,curves_20_temp); times_20 = vertcat(times_20,times_20_temp);
    curves_40 = vertcat(curves_40,curves_40_temp); times_40 = vertcat(times_40,times_40_temp);  
    curves_60 = vertcat(curves_60,curves_60_temp); times_60 = vertcat(times_60,times_60_temp);  
    curves_80 = vertcat(curves_80,curves_80_temp); times_80 = vertcat(times_80,times_80_temp);  
    curves_100 = vertcat(curves_100,curves_100_temp); times_100 = vertcat(times_100,times_100_temp);  
end
%
figure
% curve = curves_20;
% plot(puff_strengths,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
% errorbar(puff_strengths,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
curve = curves_40;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
curve = curves_60;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
curve = curves_80;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
% curve = curves_100;
% plot(puff_strengths,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
% errorbar(puff_strengths,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
legend('Pupil baseline 20-40% session max','','Pupil baseline 40-60% session max','','Pupil baseline 60-80% session max','Location','southeast')
ylabel('Response probability');xlabel('Stimulus strength (psi)');xticks([0,2,5,10,20,40])
figure
% curve = times_20;
% plot(puff_strengths,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
% errorbar(puff_strengths,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
curve = times_40;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
curve = times_60;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
curve = times_80;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
% curve = times_100;
% plot(puff_strengths,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
% errorbar(puff_strengths,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
% legend('Baseline 0-20% max','','Baseline 20-40% max','','Baseline 40-60% max','','Baseline 60-80% max','','Baseline 80-100%% max')
% DPrime and criteria plots
x = [10,30,50,70,90];
y = [mean(dprime_20,'omitnan'),mean(dprime_40,'omitnan'),mean(dprime_60,'omitnan'),mean(dprime_80,'omitnan'),mean(dprime_100,'omitnan')];
sem = [std(dprime_20,'omitnan')/length(dprime_20(~isnan(dprime_20))), std(dprime_40,'omitnan')/length(dprime_40(~isnan(dprime_40))), ...
    std(dprime_60,'omitnan')/length(dprime_60(~isnan(dprime_60))),std(dprime_80,'omitnan')/length(dprime_80(~isnan(dprime_80))), ...
    std(dprime_100,'omitnan')/length(dprime_100(~isnan(dprime_100)))];
figure; shadedErrorBar(x,y,sem);  xlabel('Baseline pupil (% session max)')
y = [mean(criterion_20,'omitnan'),mean(criterion_40,'omitnan'),mean(criterion_60,'omitnan'),mean(criterion_80,'omitnan'),mean(criterion_100,'omitnan')];
sem = [std(criterion_20,'omitnan')/length(criterion_20(~isnan(criterion_20))), std(criterion_40,'omitnan')/length(criterion_40(~isnan(criterion_40))), ...
    std(criterion_60,'omitnan')/length(criterion_60(~isnan(criterion_60))),std(criterion_80,'omitnan')/length(criterion_80(~isnan(criterion_80))), ...
    std(criterion_100,'omitnan')/length(criterion_100(~isnan(criterion_100)))];
figure; shadedErrorBar(x,y,sem); xlabel('Baseline pupil (% session max)');
%% PFC NE histograms for pupil baselines
figure
histogram(mPFC_baseline_20,40,'Normalization','probability'); hold on;
%histogram(mPFC_baseline_40,30,'Normalization','probability'); hold on;
%histogram(mPFC_baseline_60,30,'Normalization','probability'); hold on;
%histogram(mPFC_baseline_80,30,'Normalization','probability'); hold on;
histogram(mPFC_baseline_100,40,'Normalization','probability'); hold off;
xlim([0,100]); xlabel("PFC NE baseline (% max)"); ylabel("Fraction of total trials");
legend('Pupil baseline 0-20% max','Pupil baseline 80-100% max')
% PFC NE histograms for pupil baselines
figure
histogram(S1_baseline_20,40,'Normalization','probability'); hold on;
%histogram(S1_baseline_40,30,'Normalization','probability'); hold on;
%histogram(S1_baseline_60,30,'Normalization','probability'); hold on;
%histogram(S1_baseline_80,30,'Normalization','probability'); hold on;
histogram(S1_baseline_100,40,'Normalization','probability'); hold on;
xlim([0,100]); xlabel("S1 NE baseline (% max)"); ylabel("Fraction of total trials");
legend('Pupil baseline 0-20% max','Pupil baseline 80-100% max')
%% Plot psychometric curves for baseline NE stratifications
region = 23; % mPFC
%region = 28; % S1
unique_animals = unique([temp_trials_data{:,1}]');
curves_20 = zeros(0,length(stimulus_psi)); times_20 = zeros(0,length(stimulus_psi)); 
curves_40 = zeros(0,length(stimulus_psi)); times_40 = zeros(0,length(stimulus_psi));
curves_60 = zeros(0,length(stimulus_psi)); times_60 = zeros(0,length(stimulus_psi)); 
curves_80 = zeros(0,length(stimulus_psi)); times_80 = zeros(0,length(stimulus_psi)); 
curves_100 = zeros(0,length(stimulus_psi)); times_100 = zeros(0,length(stimulus_psi)); 
mPFC_baseline_20 = []; mPFC_baseline_40 = []; mPFC_baseline_60 = []; mPFC_baseline_80 = []; mPFC_baseline_100 = [];
S1_baseline_20 = []; S1_baseline_40 = []; S1_baseline_60 = []; S1_baseline_80 = []; S1_baseline_100 = [];
pupil_baseline_20 = []; pupil_baseline_40 = []; pupil_baseline_60 = []; pupil_baseline_80 = []; pupil_baseline_100 = [];
dprime_20 = []; dprime_40 = []; dprime_60 = []; dprime_80 = []; dprime_100 = [];
criterion_20 = []; criterion_40 = []; criterion_60 = []; criterion_80 = []; criterion_100 = [];

for i = 1:length(unique_animals)
    temp = temp_trials_data(contains([temp_trials_data{:,1}]',unique_animals(i)),:);
    unique_sessions = unique([temp{:,4}]');
    %disp(strcat(unique_animals(i)," has ", string(unique_sessions(end))," total phase III sessions"))
    curves_20_temp = zeros(0,length(stimulus_psi)); curves_40_temp = zeros(0,length(stimulus_psi)); curves_60_temp = zeros(0,length(stimulus_psi)); curves_80_temp = zeros(0,length(stimulus_psi)); curves_100_temp = zeros(0,length(stimulus_psi));
    times_20_temp = zeros(0,length(stimulus_psi)); times_40_temp = zeros(0,length(stimulus_psi)); times_60_temp = zeros(0,length(stimulus_psi)); times_80_temp = zeros(0,length(stimulus_psi)); times_100_temp = zeros(0,length(stimulus_psi));    
    for j = 1:length(unique_sessions)
        temp_2 = temp([temp{:,4}]' == unique_sessions(j),:);
        percent_20_idx = [temp_2{:,region}]' > 0 & [temp_2{:,region}]' <= 20; percent_20_idx_resp = [temp_2{:,region}]' <= 20 & (strcmp([temp_2{:,14}]','Hit') | strcmp([temp_2{:,14}]','FA')) & ~isnan([temp_2{:,11}]') & ~isnan([temp_2{:,11}]');
        percent_40_idx = [temp_2{:,region}]' > 20 & [temp_2{:,region}]' <= 40; percent_40_idx_resp = [temp_2{:,region}]' > 20 & [temp_2{:,region}]' <= 40 & (strcmp([temp_2{:,14}]','Hit') | strcmp([temp_2{:,14}]','FA')) & ~isnan([temp_2{:,11}]');
        percent_60_idx = [temp_2{:,region}]' > 40 & [temp_2{:,region}]' <= 60; percent_60_idx_resp = [temp_2{:,region}]' > 40 & [temp_2{:,region}]' <= 60 & (strcmp([temp_2{:,14}]','Hit') | strcmp([temp_2{:,14}]','FA')) & ~isnan([temp_2{:,11}]');
        percent_80_idx = [temp_2{:,region}]' > 60 & [temp_2{:,region}]' <= 80; percent_80_idx_resp = [temp_2{:,region}]' > 60 & [temp_2{:,region}]' <= 80 & (strcmp([temp_2{:,14}]','Hit') | strcmp([temp_2{:,14}]','FA')) & ~isnan([temp_2{:,11}]');
        percent_100_idx = [temp_2{:,region}]' > 80 & [temp_2{:,region}]' <= 100; percent_100_idx_resp = [temp_2{:,region}]' > 80 & [temp_2{:,region}]' <= 100 & (strcmp([temp_2{:,14}]','Hit') | strcmp([temp_2{:,14}]','FA')) & ~isnan([temp_2{:,11}]');        
        %temp_reaction_time =  temp_2(~cellfun(@isempty,temp_2(percent_20_idx,11)),9:2:11);    
        if ~isempty([temp_2{percent_20_idx,9}])
            curves_20_temp(j,:) = calculatePsychometricCurves([temp_2{percent_20_idx,9}]',[temp_2{percent_20_idx,12}]',training_phase,puff_values);
            times_20_temp(j,:) = calculateChronometricCurves([temp_2{percent_20_idx_resp,14}]',[temp_2{percent_20_idx_resp,11}]',[temp_2{percent_20_idx_resp,9}]',training_phase,puff_values);
        else
            curves_20_temp(j,:) = NaN(1,length(puff_values));
            times_20_temp(j,:) = NaN(1,length(puff_values));
        end
        curves_40_temp(j,:) = calculatePsychometricCurves([temp_2{percent_40_idx,9}]',[temp_2{percent_40_idx,12}]',training_phase,puff_values);
        times_40_temp(j,:) = calculateChronometricCurves([temp_2{percent_40_idx_resp,14}]',[temp_2{percent_40_idx_resp,11}]',[temp_2{percent_40_idx_resp,9}]',training_phase,puff_values);
        curves_60_temp(j,:) = calculatePsychometricCurves([temp_2{percent_60_idx,9}]',[temp_2{percent_60_idx,12}]',training_phase,puff_values);
        times_60_temp(j,:) = calculateChronometricCurves([temp_2{percent_60_idx_resp,14}]',[temp_2{percent_60_idx_resp,11}]',[temp_2{percent_60_idx_resp,9}]',training_phase,puff_values);
        if ~isempty([temp_2{percent_80_idx,9}])
            curves_80_temp(j,:) = calculatePsychometricCurves([temp_2{percent_80_idx,9}]',[temp_2{percent_80_idx,12}]',training_phase,puff_values);
            times_80_temp(j,:) = calculateChronometricCurves([temp_2{percent_80_idx_resp,14}]',[temp_2{percent_80_idx_resp,11}]',[temp_2{percent_80_idx_resp,9}]',training_phase,puff_values);
        else
            curves_20_temp(j,:) = NaN(1,length(puff_values));
            times_20_temp(j,:) = NaN(1,length(puff_values));
        end
        if ~isempty([temp_2{percent_100_idx,9}])
            curves_100_temp(j,:) = calculatePsychometricCurves([temp_2{percent_100_idx,9}]',[temp_2{percent_100_idx,12}]',training_phase,puff_values);
            times_100_temp(j,:) = calculateChronometricCurves([temp_2{percent_100_idx_resp,14}]',[temp_2{percent_100_idx_resp,11}]',[temp_2{percent_100_idx_resp,9}]',training_phase,puff_values);
        else
            curves_100_temp(j,:) = NaN(1,length(puff_values));
            times_100_temp(j,:) = NaN(1,length(puff_values));
        end
        pupil_baseline_20 = vertcat(pupil_baseline_20,[temp_2{percent_20_idx,18}]');
        mPFC_baseline_20 = vertcat(mPFC_baseline_20,[temp_2{percent_20_idx,23}]');
        S1_baseline_20 = vertcat(S1_baseline_20,[temp_2{percent_20_idx,27}]');
        pupil_baseline_40 = vertcat(pupil_baseline_40,[temp_2{percent_40_idx,18}]');
        mPFC_baseline_40 = vertcat(mPFC_baseline_40,[temp_2{percent_40_idx,23}]');
        S1_baseline_40 = vertcat(S1_baseline_40,[temp_2{percent_40_idx,27}]');
        pupil_baseline_60 = vertcat(pupil_baseline_60,[temp_2{percent_60_idx,18}]');
        mPFC_baseline_60 = vertcat(mPFC_baseline_60,[temp_2{percent_60_idx,23}]');
        S1_baseline_60 = vertcat(S1_baseline_60,[temp_2{percent_60_idx,27}]');
        pupil_baseline_80 = vertcat(pupil_baseline_80,[temp_2{percent_80_idx,18}]');
        mPFC_baseline_80 = vertcat(mPFC_baseline_80,[temp_2{percent_80_idx,23}]');
        S1_baseline_80 = vertcat(S1_baseline_80,[temp_2{percent_80_idx,27}]');
        pupil_baseline_100 = vertcat(pupil_baseline_100,[temp_2{percent_100_idx,18}]');
        mPFC_baseline_100 = vertcat(mPFC_baseline_100,[temp_2{percent_100_idx,23}]');
        S1_baseline_100 = vertcat(S1_baseline_100,[temp_2{percent_100_idx,27}]');

        seg = percent_20_idx;
        if ~isempty([temp_2{seg,14}])
            Hit_rate = sum([temp_2{seg,14}] == 'Hit')/(sum([temp_2{seg,14}] == 'Hit') + sum([temp_2{seg,14}] == 'Miss'));
            FA_rate = sum([temp_2{seg,14}] == 'FA')/(sum([temp_2{seg,14}] == 'FA') + sum([temp_2{seg,14}] == 'CR'));
        end
        if Hit_rate == 0; Hit_rate = 0.01; end; if Hit_rate == 1; Hit_rate = 0.99; end 
        if FA_rate == 0; FA_rate = 0.01; end; if FA_rate == 1; FA_rate = 0.99; end
        [dprime_20t,criterion_20t] = dprime_simple(Hit_rate,FA_rate);
        seg = percent_40_idx;
        Hit_rate = sum([temp_2{seg,14}] == 'Hit')/(sum([temp_2{seg,14}] == 'Hit') + sum([temp_2{seg,14}] == 'Miss'));
        FA_rate = sum([temp_2{seg,14}] == 'FA')/(sum([temp_2{seg,14}] == 'FA') + sum([temp_2{seg,14}] == 'CR'));
        if Hit_rate == 0; Hit_rate = 0.01; end; if Hit_rate == 1; Hit_rate = 0.99; end 
        if FA_rate == 0; FA_rate = 0.01; end; if FA_rate == 1; FA_rate = 0.99; end
        [dprime_40t,criterion_40t] = dprime_simple(Hit_rate,FA_rate);
        seg = percent_60_idx;
        Hit_rate = sum([temp_2{seg,14}] == 'Hit')/(sum([temp_2{seg,14}] == 'Hit') + sum([temp_2{seg,14}] == 'Miss'));
        FA_rate = sum([temp_2{seg,14}] == 'FA')/(sum([temp_2{seg,14}] == 'FA') + sum([temp_2{seg,14}] == 'CR'));
        if Hit_rate == 0; Hit_rate = 0.01; end; if Hit_rate == 1; Hit_rate = 0.99; end 
        if FA_rate == 0; FA_rate = 0.01; end; if FA_rate == 1; FA_rate = 0.99; end
        [dprime_60t,criterion_60t] = dprime_simple(Hit_rate,FA_rate);
        seg = percent_80_idx;
        if ~isempty([temp_2{seg,14}])
            Hit_rate = sum([temp_2{seg,14}] == 'Hit')/(sum([temp_2{seg,14}] == 'Hit') + sum([temp_2{seg,14}] == 'Miss'));
            FA_rate = sum([temp_2{seg,14}] == 'FA')/(sum([temp_2{seg,14}] == 'FA') + sum([temp_2{seg,14}] == 'CR'));
        end
        if Hit_rate == 0; Hit_rate = 0.01; end; if Hit_rate == 1; Hit_rate = 0.99; end 
        if FA_rate == 0; FA_rate = 0.01; end; if FA_rate == 1; FA_rate = 0.99; end
        [dprime_80t,criterion_80t] = dprime_simple(Hit_rate,FA_rate);
        seg = percent_100_idx;
        if ~isempty([temp_2{seg,14}])
            Hit_rate = sum([temp_2{seg,14}] == 'Hit')/(sum([temp_2{seg,14}] == 'Hit') + sum([temp_2{seg,14}] == 'Miss'));
            FA_rate = sum([temp_2{seg,14}] == 'FA')/(sum([temp_2{seg,14}] == 'FA') + sum([temp_2{seg,14}] == 'CR'));
        end
        if Hit_rate == 0; Hit_rate = 0.01; end; if Hit_rate == 1; Hit_rate = 0.99; end 
        if FA_rate == 0; FA_rate = 0.01; end; if FA_rate == 1; FA_rate = 0.99; end
        [dprime_100t,criterion_100t] = dprime_simple(Hit_rate,FA_rate);

        dprime_20 = vertcat(dprime_20,dprime_20t);
        dprime_40 = vertcat(dprime_40,dprime_40t);
        dprime_60 = vertcat(dprime_60,dprime_60t);
        dprime_80 = vertcat(dprime_80,dprime_80t);
        dprime_100 = vertcat(dprime_100,dprime_100t);
        criterion_20 = vertcat(criterion_20,criterion_20t);
        criterion_40 = vertcat(criterion_40,criterion_40t);
        criterion_60 = vertcat(criterion_60,criterion_60t);
        criterion_80 = vertcat(criterion_80,criterion_80t);
        criterion_100 = vertcat(criterion_100,criterion_100t);
    end
    curves_20 = vertcat(curves_20,curves_20_temp); times_20 = vertcat(times_20,times_20_temp);
    curves_40 = vertcat(curves_40,curves_40_temp); times_40 = vertcat(times_40,times_40_temp);  
    curves_60 = vertcat(curves_60,curves_60_temp); times_60 = vertcat(times_60,times_60_temp);  
    curves_80 = vertcat(curves_80,curves_80_temp); times_80 = vertcat(times_80,times_80_temp);  
    curves_100 = vertcat(curves_100,curves_100_temp); times_100 = vertcat(times_100,times_100_temp);  
end
%
figure
curve = curves_20;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
curve = curves_40;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
curve = curves_60;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
curve = curves_80;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
curve = curves_100;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
legend('Baseline 0-20% max','','Baseline 20-40% max','','Baseline 40-60% max','','Baseline 60-80% max','','Baseline 80-100%% max')
figure
curve = times_20;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
curve = times_40;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
curve = times_60;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
curve = times_80;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
curve = times_100;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
legend('Baseline 0-20% max','','Baseline 20-40% max','','Baseline 40-60% max','','Baseline 60-80% max','','Baseline 80-100%% max')
% PFC S1 NE and pupil histograms for pupil baselines
figure
histogram(mPFC_baseline_20,40,'Normalization','probability'); hold on;
%histogram(mPFC_baseline_40,30,'Normalization','probability'); hold on;
%histogram(mPFC_baseline_60,30,'Normalization','probability'); hold on;
%histogram(mPFC_baseline_80,30,'Normalization','probability'); hold on;
histogram(mPFC_baseline_100,40,'Normalization','probability'); hold off;
xlim([0,100]); xlabel("PFC NE baseline (% max)"); ylabel("Fraction of total trials");
legend('NE baseline 0-20% max','NE baseline 80-100% max')
% PFC NE histograms for pupil baselines
figure
histogram(S1_baseline_20,40,'Normalization','probability'); hold on;
%histogram(S1_baseline_40,30,'Normalization','probability'); hold on;
%histogram(S1_baseline_60,30,'Normalization','probability'); hold on;
%histogram(S1_baseline_80,30,'Normalization','probability'); hold on;
histogram(S1_baseline_100,40,'Normalization','probability'); hold on;
xlim([0,100]); xlabel("S1 NE baseline (% max)"); ylabel("Fraction of total trials");
legend('NE baseline 0-20% max','NE baseline 80-100% max')
figure
histogram(pupil_baseline_20,40,'Normalization','probability'); hold on;
%histogram(S1_baseline_40,30,'Normalization','probability'); hold on;
%histogram(S1_baseline_60,30,'Normalization','probability'); hold on;
%histogram(S1_baseline_80,30,'Normalization','probability'); hold on;
histogram(pupil_baseline_100,40,'Normalization','probability'); hold on;
xlim([0,100]); xlabel("Pupil baseline (% max)"); ylabel("Fraction of total trials");
legend('NE baseline 0-20% max','NE baseline 80-100% max')
% DPrime and criteria plots
x = [10,30,50,70,90];
y = [mean(dprime_20,'omitnan'),mean(dprime_40,'omitnan'),mean(dprime_60,'omitnan'),mean(dprime_80,'omitnan'),mean(dprime_100,'omitnan')];
sem = [std(dprime_20,'omitnan')/length(dprime_20(~isnan(dprime_20))), std(dprime_40,'omitnan')/length(dprime_40(~isnan(dprime_40))), ...
    std(dprime_60,'omitnan')/length(dprime_60(~isnan(dprime_60))),std(dprime_80,'omitnan')/length(dprime_80(~isnan(dprime_80))), ...
    std(dprime_100,'omitnan')/length(dprime_100(~isnan(dprime_100)))];
figure; shadedErrorBar(x,y,sem);  xlabel('Baseline NE (% session max)')
y = [mean(criterion_20,'omitnan'),mean(criterion_40,'omitnan'),mean(criterion_60,'omitnan'),mean(criterion_80,'omitnan'),mean(criterion_100,'omitnan')];
sem = [std(criterion_20,'omitnan')/length(criterion_20(~isnan(criterion_20))), std(criterion_40,'omitnan')/length(criterion_40(~isnan(criterion_40))), ...
    std(criterion_60,'omitnan')/length(criterion_60(~isnan(criterion_60))),std(criterion_80,'omitnan')/length(criterion_80(~isnan(criterion_80))), ...
    std(criterion_100,'omitnan')/length(criterion_100(~isnan(criterion_100)))];
figure; shadedErrorBar(x,y,sem); xlabel('Baseline NE (% session max)');
%% Plot psychometric curves for PCC leading up to stimulus
unique_animals = unique([temp_trials_data{:,1}]');
curves_1 = zeros(0,length(stimulus_psi));
curves_2 = zeros(0,length(stimulus_psi));
curves_3 = zeros(0,length(stimulus_psi));
curves_4 = zeros(0,length(stimulus_psi));
figure
for i = 1:length(unique_animals)
    temp = temp_trials_data(contains([temp_trials_data{:,1}]',unique_animals(i)),:);
    unique_sessions = unique([temp{:,4}]');
    curves_20_temp = zeros(0,length(stimulus_psi)); curves_40_temp = zeros(0,length(stimulus_psi)); curves_60_temp = zeros(0,length(stimulus_psi)); curves_80_temp = zeros(0,length(stimulus_psi)); curves_100_temp = zeros(0,length(stimulus_psi));
    for j = 1:length(unique_sessions)
        temp_2 = temp([temp{:,4}]' == unique_sessions(j),:);
        temp_3 = [temp_2{:,32}]'; %######
        %percent_20_idx = [temp_2{:,region}]' <= 20;
        percent_1_idx = temp_3 < 0;
        percent_2_idx = temp_3 > 0.5;
        percent_3_idx = temp_3 > 0 & temp_3 <= 0.5;
        percent_4_idx = temp_3 > 0.5 & temp_3 <= 1;
        %temp_reaction_time =  temp_2(~cellfun(@isempty,temp_2(percent_20_idx,11)),9:2:11);    
        %curves_20_temp(j,:) = calculatePsychometricCurves([temp_2{percent_20_idx,9}]',[temp_2{percent_20_idx,12}]',training_phase,puff_values);
        if ~isempty([temp_2{percent_1_idx,9}]')
            curves_1_temp(j,:) = calculatePsychometricCurves([temp_2{percent_1_idx,9}]',[temp_2{percent_1_idx,12}]',training_phase,puff_values);
        else
            curves_100_temp(j,:) = NaN(1,length(puff_values));
        end
        curves_2_temp(j,:) = calculatePsychometricCurves([temp_2{percent_2_idx,9}]',[temp_2{percent_2_idx,12}]',training_phase,puff_values);
        curves_3_temp(j,:) = calculatePsychometricCurves([temp_2{percent_3_idx,9}]',[temp_2{percent_3_idx,12}]',training_phase,puff_values);
        curves_4_temp(j,:) = calculatePsychometricCurves([temp_2{percent_4_idx,9}]',[temp_2{percent_4_idx,12}]',training_phase,puff_values);
        
    end
    %curves_20 = vertcat(curves_20,curves_20_temp);
    curves_1 = vertcat(curves_1,curves_1_temp);
    curves_2 = vertcat(curves_2,curves_2_temp);
    curves_3 = vertcat(curves_3,curves_3_temp);
    curves_4 = vertcat(curves_4,curves_4_temp);
end

curve = curves_1;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
curve = curves_2;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
% curve = curves_3;
% plot(puff_strengths,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
% errorbar(puff_strengths,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));
% curve = curves_4;
% plot(puff_strengths,mean(curve,1,'omitnan'),'LineWidth',1.5); hold on;
% errorbar(puff_strengths,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))));

legend('PCC mPFC-S1 < 0','','PCC mPFC-S1 > 0.5')



%% Cross correlation
exclude_missing_pupil = true;
temp_trials_data = cleanCombinedData(processed_trials_data,phases_to_include,exclude_missing_pupil,exclude_missing_photometry,exclude_poor_performance,NT_to_include);
%%
idx_hit = [temp_trials_data{:,14}]' == "Hit";
idx_hit_2 =  [temp_trials_data{:,14}]' == "Hit" & [temp_trials_data{:,9}]' == 0.2;
idx_hit_5 = [temp_trials_data{:,14}]' == "Hit" & [temp_trials_data{:,9}]' == 0.5;
idx_hit_10 = [temp_trials_data{:,14}]' == "Hit" & [temp_trials_data{:,9}]' == 1;
idx_hit_20 = [temp_trials_data{:,14}]' == "Hit" & [temp_trials_data{:,9}]' == 2;
idx_hit_40 = [temp_trials_data{:,14}]' == "Hit" & [temp_trials_data{:,9}]' == 4;
idx_miss = [temp_trials_data{:,14}]' == "Miss";
idx_miss_2 =  [temp_trials_data{:,14}]' == "Miss" & [temp_trials_data{:,9}]' == 0.2;
idx_miss_5 = [temp_trials_data{:,14}]' == "Miss" & [temp_trials_data{:,9}]' == 0.5;
idx_miss_10 = [temp_trials_data{:,14}]' == "Miss" & [temp_trials_data{:,9}]' == 1;
idx_miss_20 = [temp_trials_data{:,14}]' == "Miss" & [temp_trials_data{:,9}]' == 2;
idx_miss_40 = [temp_trials_data{:,14}]' == "Miss" & [temp_trials_data{:,9}]' == 4;
idx_cr = [temp_trials_data{:,14}]' == "CR";
idx_fa = [temp_trials_data{:,14}]' == "FA";
idx_resp = [temp_trials_data{:,12}]' == true;
idx_withheld = [temp_trials_data{:,12}]' == false;

x = -39/pupil_fs:1/pupil_fs:39/pupil_fs;

% all tirals
for i = 36:45
    pupil_PFC_xcor = [temp_trials_data{:,i}]';
    y = mean(pupil_PFC_xcor,1);
    sem = std(pupil_PFC_xcor,1)/sqrt(height(pupil_PFC_xcor));
    pupil_PFC_xcor_hit = [temp_trials_data{idx_hit,i}]';
    y_hit = mean(pupil_PFC_xcor_hit,1);
    sem_hit = std(pupil_PFC_xcor_hit,1)/sqrt(height(pupil_PFC_xcor_hit));

    pupil_PFC_xcor_miss = [temp_trials_data{idx_miss,i}]';
    y_miss = mean(pupil_PFC_xcor_miss,1);
    sem_miss = std(pupil_PFC_xcor_miss,1)/sqrt(height(pupil_PFC_xcor_miss));
  
    pupil_PFC_xcor_fa = [temp_trials_data{idx_fa,i}]';
    y_fa = mean(pupil_PFC_xcor_fa,1);
    sem_fa = std(pupil_PFC_xcor_fa,1)/sqrt(height(pupil_PFC_xcor_fa));

    pupil_PFC_xcor_cr = [temp_trials_data{idx_cr,i}]';
    y_cr = mean(pupil_PFC_xcor_cr,1);
    sem_cr = std(pupil_PFC_xcor_cr,1)/sqrt(height(pupil_PFC_xcor_cr));

    figure; shadedErrorBar(x,y_hit,sem_hit,'transparent',1,'lineprops',{'color','#2E86C1'}); hold on;
    shadedErrorBar(x,y_miss,sem_miss,'transparent',1,'lineprops',{'color','#E74C3C '}); hold on;
    shadedErrorBar(x,y_fa,sem_fa,'transparent',1,'lineprops',{'color','#F8C471'}); hold on;
    shadedErrorBar(x,y_cr,sem_cr,'transparent',1,'lineprops',{'color','#76448A'});
    legend('Hit','Miss','FA','CR')

end
%% Pupil data for HMM states (3 state model)

state_1_idx = state_data.predicted_states_3s == 0;  
state_2_idx = state_data.predicted_states_3s == 1;  
state_3_idx = state_data.predicted_states_3s == 2;  
%%
total_1 = sum(state_1_idx);
total_2 = sum(state_2_idx);
total_3 = sum(state_3_idx);
%%
figure
pie([total_1,total_2,total_3])
%%
append_data = cell(length(processed_trials_data),10);
processed_trials_data = horzcat(processed_trials_data,append_data);
%%
for i = 1:length(processed_trials_data)
    processed_trials_data{i,46} = state_data.predicted_states_3s(i);
end     
%%
temp_trials_data = processed_trials_data;
training_phase = 'Phase III';
unique_animals = unique([temp_trials_data{:,1}]');
curves_1 = zeros(0,length(stimulus_psi)); times_1 = zeros(0,length(stimulus_psi)); 
curves_2 = zeros(0,length(stimulus_psi)); times_2 = zeros(0,length(stimulus_psi));
curves_3 = zeros(0,length(stimulus_psi)); times_3 = zeros(0,length(stimulus_psi)); 
all_curves = zeros(0,length(stimulus_psi)); 
mPFC_baseline_1 = []; mPFC_baseline_2 = []; mPFC_baseline_3 = []; mPFC_baseline_all = [];
S1_baseline_1 = []; S1_baseline_2 = []; S1_baseline_3 = []; S1_baseline_all = [];
pupil_baseline_1 = []; pupil_baseline_2 = []; pupil_baseline_3 = []; pupil_baseline_all = [];
dprime_1 = []; dprime_2 = []; dprime_3 = [];
criterion_1 = []; criterion_2 = []; criterion_3 = [];

for i = 1:length(unique_animals)
    temp = temp_trials_data(contains([temp_trials_data{:,1}]',unique_animals(i)),:);
    unique_sessions = unique([temp{:,4}]');
    %disp(strcat(unique_animals(i)," has ", string(unique_sessions(end))," total phase III sessions"))
    curves_1_temp = zeros(0,length(stimulus_psi)); curves_2_temp = zeros(0,length(stimulus_psi)); curves_3_temp = zeros(0,length(stimulus_psi)); all_curves_temp = zeros(0,length(stimulus_psi));
    for j = 1:length(unique_sessions)
        temp_2 = temp([temp{:,4}]' == unique_sessions(j),:);
        state_1_idx = [temp_2{:,46}]' == 0; %state_1_idx_resp = [temp_2{:,18}]' <= 5 & (strcmp([temp_2{:,14}]','Hit') | strcmp([temp_2{:,14}]','FA')) & ~isnan([temp_2{:,11}]');
        state_2_idx = [temp_2{:,46}]' == 1; %percent_40_idx_resp = [temp_2{:,18}]' > 20 & [temp_2{:,18}]' <= 40 & (strcmp([temp_2{:,14}]','Hit') | strcmp([temp_2{:,14}]','FA')) & ~isnan([temp_2{:,11}]');
        state_3_idx = [temp_2{:,46}]' == 2; %percent_60_idx_resp = [temp_2{:,18}]' > 40 & [temp_2{:,18}]' <= 60 & (strcmp([temp_2{:,14}]','Hit') | strcmp([temp_2{:,14}]','FA')) & ~isnan([temp_2{:,11}]');
        %temp_reaction_time =  temp_2(~cellfun(@isempty,temp_2(percent_20_idx,11)),9:2:11);    
        if ~isempty([temp_2{state_1_idx,9}])
            curves_1_temp(j,:) = calculatePsychometricCurves([temp_2{state_1_idx,9}]',[temp_2{state_1_idx,12}]',training_phase,puff_values);
            %times_20_temp(j,:) = calculateChronometricCurves([temp_2{state_1_idx,14}]',[temp_2{percent_20_idx_resp,11}]',[temp_2{percent_20_idx_resp,9}]',training_phase,puff_values);
        else
            curves_1_temp(j,:) = NaN(1,length(puff_values));
            %times_20_temp(j,:) = NaN(1,length(puff_values));
        end
        if ~isempty([temp_2{state_2_idx,9}])
            curves_2_temp(j,:) = calculatePsychometricCurves([temp_2{state_2_idx,9}]',[temp_2{state_2_idx,12}]',training_phase,puff_values);
            %times_20_temp(j,:) = calculateChronometricCurves([temp_2{state_1_idx,14}]',[temp_2{percent_20_idx_resp,11}]',[temp_2{percent_20_idx_resp,9}]',training_phase,puff_values);
        else
            curves_2_temp(j,:) = NaN(1,length(puff_values));
            %times_20_temp(j,:) = NaN(1,length(puff_values));
        end
        if ~isempty([temp_2{state_3_idx,9}])
            curves_3_temp(j,:) = calculatePsychometricCurves([temp_2{state_3_idx,9}]',[temp_2{state_3_idx,12}]',training_phase,puff_values);
            %times_20_temp(j,:) = calculateChronometricCurves([temp_2{state_1_idx,14}]',[temp_2{percent_20_idx_resp,11}]',[temp_2{percent_20_idx_resp,9}]',training_phase,puff_values);
        else
            curves_3_temp(j,:) = NaN(1,length(puff_values));
            %times_20_temp(j,:) = NaN(1,length(puff_values));
        end
        
        all_curves_temp(j,:) = calculatePsychometricCurves([temp_2{:,9}]',[temp_2{:,12}]',training_phase,puff_values);

        mPFC_baseline_1 = vertcat(mPFC_baseline_1,[temp_2{state_1_idx,23}]');
        S1_baseline_1 = vertcat(S1_baseline_1,[temp_2{state_1_idx,28}]');
        pupil_baseline_1 = vertcat(pupil_baseline_1,[temp_2{state_1_idx,18}]');
        mPFC_baseline_2 = vertcat(mPFC_baseline_2,[temp_2{state_2_idx,23}]');
        S1_baseline_2 = vertcat(S1_baseline_2,[temp_2{state_2_idx,28}]');
        pupil_baseline_2 = vertcat(pupil_baseline_2,[temp_2{state_2_idx,18}]');
        mPFC_baseline_3 = vertcat(mPFC_baseline_3,[temp_2{state_3_idx,23}]');
        S1_baseline_3 = vertcat(S1_baseline_3,[temp_2{state_3_idx,28}]');
        pupil_baseline_3 = vertcat(pupil_baseline_3,[temp_2{state_3_idx,18}]');

        seg = state_1_idx;
        if ~isempty([temp_2{seg,14}])
            Hit_rate = sum([temp_2{seg,14}] == 'Hit')/(sum([temp_2{seg,14}] == 'Hit') + sum([temp_2{seg,14}] == 'Miss'));
            FA_rate = sum([temp_2{seg,14}] == 'FA')/(sum([temp_2{seg,14}] == 'FA') + sum([temp_2{seg,14}] == 'CR'));
        else
            Hit_rate = nan;
            FA_rate = nan;
        end
        if Hit_rate == 0; Hit_rate = 0.01; end; if Hit_rate == 1; Hit_rate = 0.99; end 
        if FA_rate == 0; FA_rate = 0.01; end; if FA_rate == 1; FA_rate = 0.99; end
        [dprime_1t,criterion_1t] = dprime_simple(Hit_rate,FA_rate);
        seg = state_2_idx;
        if ~isempty([temp_2{seg,14}])
            Hit_rate = sum([temp_2{seg,14}] == 'Hit')/(sum([temp_2{seg,14}] == 'Hit') + sum([temp_2{seg,14}] == 'Miss'));
            FA_rate = sum([temp_2{seg,14}] == 'FA')/(sum([temp_2{seg,14}] == 'FA') + sum([temp_2{seg,14}] == 'CR'));
        else
            Hit_rate = nan;
            FA_rate = nan;
        end
        if Hit_rate == 0; Hit_rate = 0.01; end; if Hit_rate == 1; Hit_rate = 0.99; end 
        if FA_rate == 0; FA_rate = 0.01; end; if FA_rate == 1; FA_rate = 0.99; end
        [dprime_2t,criterion_2t] = dprime_simple(Hit_rate,FA_rate);
        seg = state_3_idx;
        if ~isempty([temp_2{seg,14}])        
            Hit_rate = sum([temp_2{seg,14}] == 'Hit')/(sum([temp_2{seg,14}] == 'Hit') + sum([temp_2{seg,14}] == 'Miss'));
            FA_rate = sum([temp_2{seg,14}] == 'FA')/(sum([temp_2{seg,14}] == 'FA') + sum([temp_2{seg,14}] == 'CR'));
        else
            Hit_rate = nan;
            FA_rate = nan;
        end
        if Hit_rate == 0; Hit_rate = 0.01; end; if Hit_rate == 1; Hit_rate = 0.99; end 
        if FA_rate == 0; FA_rate = 0.01; end; if FA_rate == 1; FA_rate = 0.99; end
        [dprime_3t,criterion_3t] = dprime_simple(Hit_rate,FA_rate);

        dprime_1 = vertcat(dprime_1,dprime_1t);
        dprime_2 = vertcat(dprime_2,dprime_2t);
        dprime_3 = vertcat(dprime_3,dprime_3t);
        criterion_1 = vertcat(criterion_1,criterion_1t);
        criterion_2 = vertcat(criterion_2,criterion_2t);
        criterion_3 = vertcat(criterion_3,criterion_3t);
    end
    curves_1 = vertcat(curves_1,curves_1_temp);
    curves_2 = vertcat(curves_2,curves_2_temp); 
    curves_3 = vertcat(curves_3,curves_3_temp);
    all_curves = vertcat(all_curves,all_curves_temp);
end
%
figure
curve = curves_1;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',2,'Color','r'); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))),'Color','r');
curve = curves_2;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',2,'Color','g'); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))),'Color','g');
curve = curves_3;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',2,'Color','b'); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))),'Color','b');
curve = all_curves;
plot(stimulus_psi,mean(curve,1,'omitnan'),'LineWidth',2,'Color','k','LineStyle','--'); hold on;
errorbar(stimulus_psi,mean(curve,1,'omitnan'),(std(curve,1,'omitnan')/sqrt(height(curve))),'Color','k ');
legend('State 1','','State 2','','State 3','','All states','Location','southeast')
xlim([0,10]);
ylabel('Response probability');xlabel('Stimulus strength (psi)');xticks([0,2,5,10,20,40])
% DPrime and criteria plots
x = [1,2,3];
y = [mean(dprime_1,'omitnan'),mean(dprime_2,'omitnan'),mean(dprime_3,'omitnan')];
sem = [std(dprime_1,'omitnan')/length(dprime_1(~isnan(dprime_1))), std(dprime_2,'omitnan')/length(dprime_2(~isnan(dprime_2))), ...
    std(dprime_3,'omitnan')/length(dprime_3(~isnan(dprime_3)))];
figure; shadedErrorBar(x,y,sem);  xlabel('Baseline pupil (% session max)')
y = [mean(criterion_1,'omitnan'),mean(criterion_2,'omitnan'),mean(criterion_3,'omitnan')];
sem = [std(criterion_1,'omitnan')/length(criterion_1(~isnan(criterion_1))), std(criterion_2,'omitnan')/length(criterion_2(~isnan(criterion_2))), ...
    std(criterion_3,'omitnan')/length(criterion_3(~isnan(criterion_3)))];
figure; shadedErrorBar(x,y,sem); xlabel('Baseline pupil (% session max)');
    
%% PFC NE histograms for behavior states
figure
histogram(mPFC_baseline_1,40,'Normalization','probability'); hold on;
histogram(mPFC_baseline_2,40,'Normalization','probability'); hold on;
histogram(mPFC_baseline_3,40,'Normalization','probability'); hold on;
xlim([0,100]); xlabel("PFC NE baseline (% session max)"); ylabel("Fraction of total trials");
legend('State 1','State 2','State 3')
% S1 NE histograms for pupil baselines
figure
histogram(S1_baseline_1,40,'Normalization','probability'); hold on;
histogram(S1_baseline_2,40,'Normalization','probability'); hold on;
histogram(S1_baseline_3,40,'Normalization','probability'); hold on;
xlim([0,100]); xlabel("S1 NE baseline (% session max)"); ylabel("Fraction of total trials");
legend('State 1','State 2','State 3')
% Pupil NE histograms for pupil baselines
figure
histogram(pupil_baseline_1,40,'Normalization','probability'); hold on;
histogram(pupil_baseline_2,40,'Normalization','probability'); hold on;
histogram(pupil_baseline_3,40,'Normalization','probability'); hold on;
xlim([0,100]); xlabel("Pupil baseline (% session max)"); ylabel("Fraction of total trials");
legend('State 1','State 2','State 3')
%
labels = categorical({'State 1','State 2','State 3'});
labels = reordercats(labels,{'State 1','State 2','State 3'});

state_PFC_baselines = [mean(mPFC_baseline_1),mean(mPFC_baseline_2),mean(mPFC_baseline_3);std(mPFC_baseline_1)/sqrt(length(mPFC_baseline_1)),std(mPFC_baseline_2)/sqrt(length(mPFC_baseline_2)),std(mPFC_baseline_3)/sqrt(length(mPFC_baseline_3))];

figure;
b1 = bar(labels,state_PFC_baselines(1,:));
hold on;
er1 = errorbar(labels,state_PFC_baselines(1,:),state_PFC_baselines(2,:));
er1.Color = [0 0 0]; er1.LineStyle = 'none';
ylabel('Baseline PFC NE (% session max');
ylim(ylims);
%
labels = categorical({'State 1','State 2','State 3'});
labels = reordercats(labels,{'State 1','State 2','State 3'});

state_S1_baselines = [mean(S1_baseline_1),mean(S1_baseline_2),mean(S1_baseline_3);std(S1_baseline_1)/sqrt(length(S1_baseline_1)),std(S1_baseline_2)/sqrt(length(S1_baseline_2)),std(S1_baseline_3)/sqrt(length(S1_baseline_3))];

figure;
b1 = bar(labels,state_S1_baselines(1,:));
hold on;
er1 = errorbar(labels,state_S1_baselines(1,:),state_S1_baselines(2,:));
er1.Color = [0 0 0]; er1.LineStyle = 'none';
ylabel('Baseline S1 NE (% session max');
ylim(ylims);
%
labels = categorical({'State 1','State 2','State 3'});
labels = reordercats(labels,{'State 1','State 2','State 3'});

state_pupil_baselines = [mean(pupil_baseline_1),mean(pupil_baseline_2),mean(pupil_baseline_3);std(pupil_baseline_1)/sqrt(length(pupil_baseline_1)),std(pupil_baseline_2)/sqrt(length(pupil_baseline_2)),std(pupil_baseline_3)/sqrt(length(pupil_baseline_3))];

figure;
b1 = bar(labels,state_pupil_baselines(1,:));
hold on;
er1 = errorbar(labels,state_pupil_baselines(1,:),state_pupil_baselines(2,:));
er1.Color = [0 0 0]; er1.LineStyle = 'none';
ylabel('Baseline pupil area (% session max');
ylim(ylims);
%%
subplot_num = 1;
alpha = 0.65; %transparency
colors = ["#CCFFE5","#66FF66","#00FF00","#009900","#006600"];

% region = 22; ylims = [38,60]; fs=photometry_fs;% mPFC
% fig_label = "Peak NE following stimulus (% session max)"; descrip = "Norepinephrine";
% region = 27; ylims = [45,60]; fs=photometry_fs;% S1
% fig_label = "Peak NE following stimulus (% session max)"; descrip = "Norepinephrine";
region = 17; ylims = [44,84]; fs=pupil_fs;% S1
fig_label = "Peak pupil area following stimulus (% session max)"; descrip = "Pupil";
temp_trials_data = processed_trials_data;
state_idx = [temp_trials_data{:,46}]' == 2;
temp_3 = temp_trials_data(state_idx,:);

idx_hit = [temp_3{:,14}]' == "Hit";
idx_hit_2 =  [temp_3{:,14}]' == "Hit" & [temp_3{:,9}]' == 0.2;
idx_hit_5 = [temp_3{:,14}]' == "Hit" & [temp_3{:,9}]' == 0.5;
idx_hit_10 = [temp_3{:,14}]' == "Hit" & [temp_3{:,9}]' == 1;
idx_hit_20 = [temp_3{:,14}]' == "Hit" & [temp_3{:,9}]' == 2;
idx_hit_40 = [temp_3{:,14}]' == "Hit" & [temp_3{:,9}]' == 4;
idx_miss = [temp_3{:,14}]' == "Miss";
idx_miss_2 =  [temp_3{:,14}]' == "Miss" & [temp_3{:,9}]' == 0.2;
idx_miss_5 = [temp_3{:,14}]' == "Miss" & [temp_3{:,9}]' == 0.5;
idx_miss_10 = [temp_3{:,14}]' == "Miss" & [temp_3{:,9}]' == 1;
idx_miss_20 = [temp_3{:,14}]' == "Miss" & [temp_3{:,9}]' == 2;
idx_miss_40 = [temp_3{:,14}]' == "Miss" & [temp_3{:,9}]' == 4;
idx_cr = [temp_3{:,14}]' == "CR";
idx_fa = [temp_3{:,14}]' == "FA";
idx_resp = [temp_3{:,12}]' == true;
idx_withheld = [temp_3{:,12}]' == false;


x = -1*(time_before_stim-1/fs):1/fs:time_after_stim;
% Hit
sliced_data = [temp_3{idx_hit,region}]';
y1 = mean(sliced_data,1);
sem1 = std(sliced_data,1)/sqrt(height(sliced_data));

sliced_data = [temp_3{idx_hit_2,region}]';
y_2 = mean(sliced_data,1);
sem_2 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_3{idx_hit_5,region}]';
y_5 = mean(sliced_data,1);
sem_5 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_3{idx_hit_10,region}]';
y_10 = mean(sliced_data,1);
sem_10 = std(sliced_data,1)/sqrt(height(sliced_data));
% sliced_data = [temp_3{idx_hit_20,region}]';
% y_20 = mean(sliced_data,1);
% sem_20 = std(sliced_data,1)/sqrt(height(sliced_data));
% sliced_data = [temp_3{idx_hit_40,region}]';
% y_40 = mean(sliced_data,1);
% sem_40 = std(sliced_data,1)/sqrt(height(sliced_data));

labels = categorical({'2 psi','5 psi','10 psi'});
labels = reordercats(labels,{'2 psi','5 psi','10 psi'});

y_2_idx = find(y_2 == max(y_2(1:2*fs)));
y_5_idx = find(y_5 == max(y_5(1:2*fs)));
y_10_idx = find(y_10 == max(y_10(1:2*fs)));
% y_20_idx = find(y_20 == max(y_20(1:2*photometry_fs)));
% y_40_idx = find(y_40 == max(y_40(1:2*photometry_fs)));
pupil_response = [y_2(y_2_idx),y_5(y_5_idx),y_10(y_10_idx);sem_2(y_2_idx),sem_5(y_5_idx),sem_10(y_10_idx)];

figure;
b1 = bar(labels,pupil_response(1,:));
hold on;
er1 = errorbar(labels,pupil_response(1,:),pupil_response(2,:));
er1.Color = [0 0 0]; er1.LineStyle = 'none';
ylabel(fig_label);
ylim(ylims);

figure
subplot(1,4,subplot_num);
shadedErrorBar(x,y1,sem1,'transparent',1,'lineprops',{'color','#000000'}); hold on;
% shadedErrorBar(x,y_2,sem_2,'transparent',1,'lineprops',{'color','#ABEBC6'}); hold on;
% shadedErrorBar(x,y_5,sem_5,'transparent',1,'lineprops',{'color','#A9DFBF'}); hold on;
% shadedErrorBar(x,y_10,sem_10,'transparent',1,'lineprops',{'color','#52BE80'}); hold on;
% shadedErrorBar(x,y_20,sem_20,'transparent',1,'lineprops',{'color','#229954'}); hold on;
% shadedErrorBar(x,y_40,sem_40,'transparent',1,'lineprops',{'color','#145A32'}); hold on;
ylim(ylims); title('Hit'); ylabel(strcat(descrip," (% session max)"));
subplot_num = subplot_num + 1;
% CR
sliced_data = [temp_3{idx_cr,region}]';
y1 = mean(sliced_data,1);
sem1 = std(sliced_data,1)/sqrt(height(sliced_data));

subplot(1,4,subplot_num);
shadedErrorBar(x,y1,sem1,'transparent',1,'lineprops',{'color','#000000'}); hold on;
ylim(ylims); title('CR'); ylabel(strcat(string(descrip)," (% session max)"));
%legend('aligned by stimulus')
subplot_num = subplot_num + 1;
% FA
sliced_data = [temp_3{idx_fa,region}]';
y1 = mean(sliced_data,1);
sem1 = std(sliced_data,1)/sqrt(height(sliced_data));

subplot(1,4,subplot_num);
shadedErrorBar(x,y1,sem1,'transparent',1,'lineprops',{'color','#000000'}); hold on;
ylim(ylims); title('FA'); ylabel(strcat(string(descrip)," (% session max)"));
subplot_num = subplot_num + 1;
% Miss
sliced_data = [temp_3{idx_miss,region}]';
y1 = mean(sliced_data,1);
sem1 = std(sliced_data,1)/sqrt(height(sliced_data));

sliced_data = [temp_3{idx_miss_2,region}]';
y_2 = mean(sliced_data,1);
sem_2 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_3{idx_miss_5,region}]';
y_5 = mean(sliced_data,1);
sem_5 = std(sliced_data,1)/sqrt(height(sliced_data));
sliced_data = [temp_3{idx_miss_10,region}]';
y_10 = mean(sliced_data,1);
sem_10 = std(sliced_data,1)/sqrt(height(sliced_data));
% sliced_data = [temp_trials_data{idx_miss_20,region}]';
% y_20 = mean(sliced_data,1);
% sem_20 = std(sliced_data,1)/sqrt(height(sliced_data));
% sliced_data = [temp_trials_data{idx_miss_40,region}]';
% y_40 = mean(sliced_data,1);
% sem_40 = std(sliced_data,1)/sqrt(height(sliced_data));

subplot(1,4,subplot_num);
shadedErrorBar(x,y1,sem1,'transparent',1,'lineprops',{'color','#000000'}); hold on;
% shadedErrorBar(x,y_2,sem_2,'transparent',1,'lineprops',{'color','#ABEBC6'}); hold on;
% shadedErrorBar(x,y_5,sem_5,'transparent',1,'lineprops',{'color','#A9DFBF'}); hold on;
% shadedErrorBar(x,y_10,sem_10,'transparent',1,'lineprops',{'color','#52BE80'}); hold on;
% shadedErrorBar(x,y_20,sem_20,'transparent',1,'lineprops',{'color','#229954'}); hold on;
% shadedErrorBar(x,y_40,sem_40,'transparent',1,'lineprops',{'color','#145A32'}); hold on;
ylim(ylims); title('Miss'); ylabel(strcat(string(descrip)," (% session max)"));

y_2_idx = find(y_2 == max(y_2(1:2*fs)));
if ~isempty(y_5)
    y_5_idx = find(y_5 == max(y_5(1:2*fs)));
else
    y_5_idx = [];
end
if ~isempty(y_10)
    y_10_idx = find(y_10 == max(y_10(1:2*fs)));
else
    y_10_idx = [];
end
% y_20_idx = find(y_20 == max(y_20(1:2*photometry_fs)));
% y_40_idx = find(y_40 == max(y_40(1:2*photometry_fs)));
if ~isempty(y_5_idx) & ~isempty(y_10_idx)
    pupil_response = [y_2(y_2_idx),y_5(y_5_idx),y_10(y_10_idx);sem_2(y_2_idx),sem_5(y_5_idx),sem_10(y_10_idx)];   
    labels = categorical({'2 psi','5 psi','10 psi'});
    labels = reordercats(labels,{'2 psi','5 psi','10 psi'});
else
    pupil_response = [y_2(y_2_idx);sem_2(y_2_idx)];
    labels = categorical({'2 psi'});
    labels = reordercats(labels,{'2 psi'});
end

figure;
b1 = bar(labels,pupil_response(1,:));
hold on;
er1 = errorbar(labels,pupil_response(1,:),pupil_response(2,:));
er1.Color = [0 0 0]; er1.LineStyle = 'none';
ylabel(fig_label);
ylim(ylims);
