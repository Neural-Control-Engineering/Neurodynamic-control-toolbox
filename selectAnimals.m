function [animals_to_load,analysis_progress,resets,wbar] = selectAnimals(paths)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if strcmp(paths.data_source,"Project_Neurotransmitter-Exploration")
    animals = dir(fullfile(paths.raw_behavior_data,'*-*.mat'));
    temp_animals = strings(length(animals),1);

    for i = 1:length(animals)
        name_split = split(animals(i).name,'_');
        temp_animals(i) = name_split{1};
    end

    animal_list = cellstr(unique(temp_animals));

    [indx, tf] = listdlg('Name','File Selection','PromptString', {'Select at least one animal you',...
        'would like to run analysis on.'}, ...
        'ListString', animal_list);
    switch tf
        case 1
            animals_to_load = animal_list(indx);
        case ''
            return
    end
elseif strcmp(paths.data_source,"Project_Thalamic-Pupil-Synchronization")
    animals = dir(fullfile(paths.raw_behavior_data,'*-*.mat'));
    temp_animals = strings(length(animals),1);

    for i = 1:length(animals)
        name_split = split(animals(i).name,'_');
        temp_animals(i) = name_split{4};
    end

    animal_list = cellstr(unique(temp_animals));

    [indx, tf] = listdlg('Name','File Selection','PromptString', {'Select at least one animal you',...
        'would like to run analysis on.'}, ...
        'ListString', animal_list);
    switch tf
        case 1
            animals_to_load = animal_list(indx);
        case ''
            return
    end
elseif strcmp(paths.data_source,"Project_Somatosensory-Signal-Detection")
    animals = dir(fullfile(paths.raw_behavior_data,'*-*.mat'));
    temp_animals = strings(length(animals),1);

    for i = 1:length(animals)
        name_split = split(animals(i).name,'_');
        temp_animals(i) = name_split{1};
    end

    animal_list = cellstr(unique(temp_animals));

    [indx, tf] = listdlg('Name','File Selection','PromptString', {'Select at least one animal you',...
        'would like to run analysis on.'}, ...
        'ListString', animal_list);
    switch tf
        case 1
            animals_to_load = animal_list(indx);
        case ''
            return
    end
end

answer_reset_behavior = questdlg('Would you like to re-process raw behavior data?', ...
    'Reset Behavior', ...
    'Yes','No','Cancel','Cancel');
% Handle response
switch answer_reset_behavior
    case 'Yes'
        resets.reset_behavior_data_processing = true;
    case 'No'
        resets.reset_behavior_data_processing = false;
    case 'Cancel'
        return
    case ''
        return
end

answer_reset_photometry = questdlg('Would you like to re-process raw photometry data?', ...
    'Reset Photometry', ...
    'Yes','No','Cancel','Cancel');
% Handle response
switch answer_reset_photometry
    case 'Yes'
        resets.reset_photometry_processing = true;
    case 'No'
        resets.reset_photometry_processing = false;
    case 'Cancel'
        return
    case ''
        return
end

answer_reset_pupil = questdlg('Would you like to re-process extracted pupil data?', ...
    'Reset Pupil', ...
    'Yes','No','Cancel','Cancel');
% Handle response
switch answer_reset_pupil
    case 'Yes'
        resets.reset_pupil2AreaConversion = true;
    case 'No'
        resets.reset_pupil2AreaConversion = false;
    case 'Cancel'
        return
    case ''
        return
end

answer_reset_whisker = questdlg('Would you like to re-process extracted whisker data?', ...
    'Reset Whisker', ...
    'Yes','No','Cancel','Cancel');
% Handle response
switch answer_reset_whisker
    case 'Yes'
        resets.reset_whisker2PhaseConversion = true;
    case 'No'
        resets.reset_whisker2PhaseConversion = false;
    case 'Cancel'
        return
    case ''
        return
end

answer_reset_neuropixel = questdlg('Would you like to re-process extracted neuropixel data?', ...
    'Reset Neuropixel', ...
    'Yes','No','Cancel','Cancel');
% Handle response
switch answer_reset_neuropixel
    case 'Yes'
        resets.reset_neuropixel_processing = true;
    case 'No'
        resets.reset_neuropixel_processing = false;
    case 'Cancel'
        return
    case ''
        return
end

wbar = waitbar(0,'Please wait while we check which sessions need to be analyzed');
pause(1.0)
analysis_progress.completed_animals = 0;
analysis_progress.total_animals = length(animals_to_load);

end