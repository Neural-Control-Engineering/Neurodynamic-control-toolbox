function [behavior_to_process] = fetchBehavior2Extract(animal_id,session_names,paths,reset_behavior_data_processing)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if reset_behavior_data_processing==true
    % Reset the analysis log
    load(fullfile(paths.raw_behavior_data,"behavior_extraction_log.mat"));
    behavior_extraction_log(contains(behavior_extraction_log.Name, animal_id),:) = [];
    
%     % Delete the previously generated processed data files
%     processed_behavior_data = dir(strcat(paths.processed_behavior_data));
%     processed_behavior_data = processed_behavior_data(contains({processed_behavior_data.name},"mat"));
%     to_delete = {processed_behavior_data.name};
% 
%     for i = 1:length(processed_behavior_data)
%         file = strcat(paths.processed_behavior_data,'\',string(to_delete(i)));
%         delete(file);
%     end

    save(fullfile(paths.raw_behavior_data,'behavior_extraction_log.mat'),'behavior_extraction_log');
    
end

% List all behavior files in folder
behavior_list = session_names(:,1);
behavior_list = behavior_list(contains(behavior_list,".mat") & contains(behavior_list,animal_id));
filenames = behavior_list;

%
load(fullfile(paths.raw_behavior_data,"behavior_extraction_log.mat"));

if ~isempty(behavior_extraction_log)
    idx_behavior_to_add =  ~ismember(filenames,behavior_extraction_log.Name);
else
    idx_behavior_to_add = true(1, length(filenames));
end

files_to_add = filenames(idx_behavior_to_add);

if ~isempty(files_to_add)
    for i = 1:length(files_to_add)
        % Add new data files to analysis list and set processed to false
        behavior_extraction_log = [behavior_extraction_log; {files_to_add(i), NaN, false}];
        display(strcat("Added:  ",files_to_add(i),' to the behavior extraction log.'));
    end
end

session_numbers = 1:length(behavior_extraction_log(contains(behavior_extraction_log.Name,animal_id),:).Sequential_Session_Number);

behavior_extraction_log(contains(behavior_extraction_log.Name,animal_id),:).Sequential_Session_Number = session_numbers';

% Return videos that need to be extracted
behavior_to_process = behavior_extraction_log(behavior_extraction_log.Processed == false & contains(behavior_extraction_log.Name,animal_id),:).Name;

if ~isempty(behavior_to_process)
    save(fullfile(paths.raw_behavior_data,'behavior_extraction_log.mat'),'behavior_extraction_log');
else
    display(strcat("There are currently no behavior data files for ",animal_id, ' that need to be processed.'));
end
end