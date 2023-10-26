function [session_names] = retrieve_session_list(animal_name,paths,data_type)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

% Find all behavior sessions for the provided animal
if strcmp(data_type,"raw")
    behavior_data_dir = dir(fullfile(paths.raw_behavior_data,strcat('*',string(animal_name))+'*.*'));
elseif strcmp(data_type,"processed")
    behavior_data_dir = dir(fullfile(paths.processed_behavior_data,strcat('*',string(animal_name))+'*.*'));
end

session_names = {behavior_data_dir.name}';

% Find name and date details for each session
if strcmp(paths.data_source,"Project_Neurodynamic-Control") || strcmp(paths.data_source,"Project_Somatosensory-Signal-Detection")
    for i = 1:height(session_names)
    
        dividers = strfind(session_names{i,1},'_');
        name_divide = strfind(session_names{i,1},'-');
    
        session_names{i,2} = string(session_names{i,1}(1:end-4));
        session_names{i,3} = string(session_names{i,1}(1:dividers(1)-1));
        session_names{i,4} = string(session_names{i,1}(1:name_divide(1)-1));
        session_names{i,5} = string(session_names{i,1}(dividers(1)+1:dividers(2)-1));
        session_names{i,6} = string(session_names{i,1}(dividers(2)+1:dividers(3)-1));
        session_names{i,7} = string(session_names{i,1}(dividers(3)+1:end-4));
    end
elseif strcmp(paths.data_source,"Project_Thalamic-Pupil-Synchronization")
    for i = 1:height(session_names)
    
        dividers = strfind(session_names{i,1},'_');
        name_divide = strfind(session_names{i,1},'-');
    
        session_names{i,2} = string(session_names{i,1}(1:end-4)); % full file name without extension
        session_names{i,3} = string(session_names{i,1}(dividers(3)+1:end)); % full file name without date
        session_names{i,4} = string(session_names{i,1}(dividers(3)+1:name_divide(1)-1)); % animal number
        session_names{i,5} = string(session_names{i,1}(1:dividers(1)-1)); % year
        session_names{i,6} = string(session_names{i,1}(dividers(1)+1:dividers(2)-1)); % month
        session_names{i,7} = string(session_names{i,1}(dividers(2)+1:dividers(3)-1)); % day
    end
end

