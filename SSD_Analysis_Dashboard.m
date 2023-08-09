% Written by C.L.Slater 2022

% This is the primary script to coordinate analysis of all neurotransmitter
% exploration projects(in Matlab). See each descriptor below for a full explanation of the function
% of each section

%% SET SHARED PATHS AND PARAMETERS
% Begin by clearing workspace
clear; clc; close all;

% Set variables here
opt_windows.response_window = 1; %seconds
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

%% PROCESS RAW DATA FROM SOURCE
[animals_to_load,analysis_progress,resets,wbar] = selectAnimals(paths);

for animal_number = 1:length(animals_to_load)

    waitbar(analysis_progress.completed_animals/analysis_progress.total_animals,wbar,[num2str(analysis_progress.completed_animals) '/' num2str(analysis_progress.total_animals) ' animals completed']);

    % Run through all files and find unprocessed data
    processDataStreams(animals_to_load{animal_number},paths,analysis_params,resets);

    analysis_progress.completed_animals = analysis_progress.  completed_animals + 1;
end

% Close wait bar
pause(.5)
close(wbar)

% Make sure DLC data is up to date before compiling database
updateDLCData(paths,resets,"pupil");

%% GENERATE DATASTORE OR LOAD DATASTORE
%[Datastore] = generateDatabase(paths,analysis_params,animals_to_load);
Datastore = load(fullfile(paths.datastore,"NE_dstore_cleaned02-Aug-2023.mat"));

%% PLOT AVERAGED PHOTOMETRY TRACES ALIGNED TO STIMULUS TIME
% just want animals with recordings from both mPFC and S1 
data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
% get list of animals in filtered dataset 
animals = fetchAnimals(data);
% loop through animals, plot averaged trace for each
t0 = -2; % begining of averaged epoch 
t1 = 0; % end of average
for i = 1:length(animals)
    animal = num2str(animals(i));
    avgTracesBy(data, 'animal', animal, 'outcome', t0, t1, fullfile(paths.repo_path,'Analysis/avgTraces/all_stim_strengths/outcome/')); % separate averages by categorical outcome 
    avgTracesBy(data, 'animal', animal, 'response', t0, t1, fullfile(paths.repo_path,'Analysis/avgTraces/all_stim_strengths/response/')); % separate averages by response (go / no go)
end

%% PLOT SLOPES FOR PHOTOMETRY TRACES 0.5 s BEFORE STIMULUS
% just want animals with recordings from both mPFC and S1 
data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
% get list of animals in filtered dataset 
animals = fetchAnimals(data);
t0 = -0.5; % begining of averaged epoch 
t1 = 0; % end of average
for i = 1:length(animals)
    animal = num2str(animals(i));
    tmp = filterTrials(data, 'animal', animal);
    plotSlopes(tmp, 'outcome', t0, t1, fullfile(paths.repo_path,'Analysis/Slopes/all_stim_strength/outcome/'))
    plotSlopes(tmp, 'response', t0, t1, fullfile(paths.repo_path,'Analysis/Slopes/all_stim_strength/response/'))
end

%% PLOT CROSS-CORRELATION BETWEEN PHOTOMETRY CHANNELS IN mFPC AND S1 FOR 2s PRIOR TO STIM
% just want animals with recordings from both mPFC and S1 
data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
% get list of animals in filtered dataset 
animals = fetchAnimals(data);
t0 = -2.0; % begining of averaged epoch 
t1 = 0; % end of average
for i = 1:length(animals)
    animal = num2str(animals(i));
    xcorrBy(data, 'animal', animal, 'response', t0, t1, fullfile(paths.repo_path,'Analysis/Xcorr/all_stim_strength/response/'));
    xcorrBy(data, 'animal', animal, 'outcome', t0, t1, fullfile(paths.repo_path,'Analysis/Xcorr/all_stim_strength/outcome/'));
end

%% PLOT FFTS OF 2S OF PHOTOMETRY DATA PRIOR TO STIM AVERAGED ACROSS TRIALS FOR EACH ANIMAL 
data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
% get list of animals in filtered dataset 
animals = fetchAnimals(data);
t0 = -2.0; % begining of averaged epoch 
t1 = 0; % end of average
for i = 1:length(animals)
    animal = num2str(animals(i));
    avgFftBy(data, 'animal', animal, 'response', t0, t1, fullfile(paths.repo_path, 'Analysis/FFTS/all_stim_strength/response/'));
    avgFftBy(data, 'animal', animal, 'outcome', t0, t1, fullfile(paths.repo_path, 'Analysis/FFTS/all_stim_strength/outcome/'));
end