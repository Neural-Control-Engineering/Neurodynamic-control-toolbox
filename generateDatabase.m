function [Datastore] = generateDatabase(paths,params,animals_to_load,mode)
%GENERATEDATABASE Pool data in standard format
%   Detailed explanation goes here

Datastore = cell(0,params.num_of_properties);

for animal_number = 1:length(animals_to_load)

    % Find how many unique sessions a single animal has
    [session_names] = retrieve_session_list(animals_to_load{animal_number},paths,"processed");

    for session = 1:height(session_names)
        try
            % Define empty matrices for data
            pupil_data = [];
            photometry_data = [];
            whisker_data = [];
            
            tic

            % retrieve behavior_data
            behavior_data = load(fullfile(paths.processed_behavior_data,session_names{session,1}),'behavior_data');
            behavior_data = behavior_data.behavior_data;


            if ismember(behavior_data.training_phase,params.phase_selection)
                % retrieve pupil_data
                if strcmp(paths.data_source,"Project_Somatosensory-Signal-Detection")
                    pupil_to_load = dir(fullfile(paths.processed_pupil_data,strcat(session_names{session,3},'-',session_names{session,6},session_names{session,7},session_names{session,5},'*')));                    
                else
                    pupil_to_load = dir(fullfile(paths.processed_pupil_data,strcat(session_names{session,2},'*')));
                end

                if ~isempty(pupil_to_load)
                    pupil_data = readtable(fullfile(pupil_to_load(end).folder,pupil_to_load(end).name));
                end
    
                % retrieve whisker_data
                whisker_to_load = dir(fullfile(paths.processed_whisker_data,strcat(session_names{session,2},'*')));
                if ~isempty(whisker_to_load)
                    whisker_data = readtable(fullfile(whisker_to_load(end).folder,whisker_to_load(end).name));
                end
    
                % retrieve photometry_data
                photometry_to_load = dir(fullfile(paths.processed_photometry_data,strcat(session_names{session,2},'*')));
                if ~isempty(photometry_to_load)
                    photometry_data = readtable(fullfile(photometry_to_load(end).folder,photometry_to_load(end).name));
                end
    
                % For a given animal, create a cell array with relevant info for each session
                [animal_summary_of_sessions] = returnTrialsFromSession(params,paths,session_names(session,:),behavior_data,pupil_data,whisker_data,photometry_data);
                disp(strcat('Finished processing: ', session_names{session}(1:end-4)));
            
                Datastore = vertcat(Datastore,animal_summary_of_sessions);
                display(session_names(session) + " was successfully added to datastore in " + toc + " seconds.");  
            end
        catch
            display("There was an error with session: " + session_names(session));
        end                  
    end
end

if ~strcmp(mode,"combined")
    if ~isfolder(fullfile(paths.all_data_path,'Datastores',string(animals_to_load)))
        mkdir(fullfile(paths.all_data_path,'Datastores',string(animals_to_load)))
        save_loc = fullfile(paths.all_data_path,'Datastores',string(animals_to_load));
    else
        save_loc = fullfile(paths.all_data_path,'Datastores',string(animals_to_load));
    end
    
    %Datastore = tall(Datastore);
    Datastore = convertCells2Python(Datastore);
    
    save(fullfile(save_loc,strcat(string([animals_to_load(:)]),"_Datastore_created_",string(datetime("today")),".mat")), 'Datastore','-v7.3');
    
elseif strcmp(mode,"combined")
    save_loc = fullfile(paths.all_data_path,'Datastores');
    Datastore = convertCells2Python(Datastore);
    save(fullfile(save_loc,strcat("Combined-Datastore_created_",string(datetime("today")),".mat")), 'Datastore','-v7.3');
end
disp('Datastore successfully written to project folder.');