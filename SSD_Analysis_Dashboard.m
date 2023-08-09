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
%%

%%
