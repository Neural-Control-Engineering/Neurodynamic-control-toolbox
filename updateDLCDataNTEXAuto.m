function temp_log = updateDLCDataNTEXAuto(paths)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

% Paths for raw data
paths.raw_behavior_data = '/mnt/g/My Drive/#Projects/Project_Neurotransmitter-Exploration/Raw Behavior Data';
paths.behavior_meta_data = '/mnt/g/My Drive/#Projects/Project_Neurotransmitter-Exploration/Experiment Metadata';
paths.raw_photometry_data = '/mnt/g/My Drive/#Projects/Project_Neurotransmitter-Exploration/Raw Photometry Data';
paths.raw_pupil_data = '/mnt/g/My Drive/#Projects/Project_Neurotransmitter-Exploration/Raw Pupil Data';
paths.raw_whisker_data = '/mnt/g/My Drive/#Projects/Project_Neurotransmitter-Exploration/Raw Whisker Data';
paths.raw_neuropixel_data = '/mnt/g/My Drive/#Projects/Project_Neurotransmitter-Exploration/Raw Neuropixel Data';

% Paths for analyzed data
paths.processed_behavior_data = '/mnt/g/My Drive/#Projects/Project_Neurotransmitter-Exploration/Processed Behavior Data';
paths.processed_photometry_data = '/mnt/g/My Drive/#Projects/Project_Neurotransmitter-Exploration/Processed Photometry Data';
paths.processed_pupil_data = '/mnt/g/My Drive/#Projects/Project_Neurotransmitter-Exploration/Processed Pupil Data';
paths.processed_whisker_data = '/mnt/g/My Drive/#Projects/Project_Neurotransmitter-Exploration/Processed Whisker Data';
paths.processed_neuropixel_data = '/mnt/g/My Drive/#Projects/Project_Neurotransmitter-Exploration/Processed Neuropixel Data';

resets.reset_pupil2AreaConversion = false;
resets.reset_whisker2PhaseConversion = false;

% ################ PUPIL #####################
% Process any unprocessed pupil data for all sessions
display("Please wait. Checking that all pupil data has been updated...");
[temp_log] = convertPupil2Area(paths,resets.reset_pupil2AreaConversion);
%display(temp_log(:))

% ################ WHISKER #####################
% Process any unprocessed whisker data for all sessions
display("Please wait. Checking that all whisker data has been updated...");
[temp_log] = convertWhisker2Phase(paths,resets.reset_whisker2PhaseConversion);
%display(temp_log(:))

fetchOutlierVideos(paths);
end