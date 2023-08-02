function [photometry_to_process] = fetchPhotometry2Extract(animal_id,session_names,paths,reset_photometry_processing)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if reset_photometry_processing==true
    % Reset the analysis log
    load(fullfile(paths.raw_photometry_data,"photometry_extraction_log.mat"));
    photometry_extraction_log(contains(photometry_extraction_log.Name, animal_id),:) = [];
    
    save(fullfile(paths.raw_photometry_data,'photometry_extraction_log.mat'),'photometry_extraction_log');
end

% List all photometry files in folder
photometry_list = session_names(:,1);
photometry_list = photometry_list(contains(photometry_list,".mat") & contains(photometry_list,animal_id));
filenames = photometry_list;

%
load(fullfile(paths.raw_photometry_data,"photometry_extraction_log.mat"));

if ~isempty(photometry_extraction_log)
    idx_photometry_to_add =  ~ismember(filenames,photometry_extraction_log.Name);
else
    idx_photometry_to_add = true(1, length(filenames));
end

files_to_add = filenames(idx_photometry_to_add);

if ~isempty(files_to_add)
    for i = 1:length(files_to_add)
        % Add new data files to analysis list and set processed to false
        photometry_extraction_log = [photometry_extraction_log; {files_to_add(i), false}];
        display(strcat("Added:  ",files_to_add(i),' to the photometry extraction log.'));
    end
end

% Return videos that need to be extracted
photometry_to_process = photometry_extraction_log(photometry_extraction_log.Processed == false & contains(photometry_extraction_log.Name,animal_id),:).Name;

if ~isempty(photometry_to_process)
    save(fullfile(paths.raw_photometry_data,'photometry_extraction_log.mat'),'photometry_extraction_log');
else
    display(strcat("There are currently no photometry files for ",animal_id, ' that need to be processed.'));
end
end