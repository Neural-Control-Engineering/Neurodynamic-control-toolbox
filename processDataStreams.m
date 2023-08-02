function processDataStreams(animal_id,paths,params,resets)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Find how many unique sessions a single animal has
[session_names] = retrieve_session_list(animal_id,paths,"raw");

% ################ NEUROPIXEL #####################
% Find neuropixel data for given session and convert it to the
% processed form if it is not already.
if params.process_neuropixel
    addpath(paths.neuropixel.kilosort_params);
    
    if ~isempty(dir(fullfile(paths.raw_neuropixel_data,'*Npxl*'))) && contains(animal_id, 'Npxl')
        [neuropixel_to_process] = fetchNeuropixel2Extract(animal_id,session_names,paths,resets.reset_neuropixel_processing);
    
        if ~isempty(neuropixel_to_process)
    
            for session = 1:length(neuropixel_to_process)
                %try
                ks = [];
                metrics = [];
                imec = [];
                % Find neuropixel data for given session
                div = strfind(neuropixel_to_process{session},'_');
    
                exp_template = neuropixel_to_process{session}(1:div(4)-1);
                neuropixel_dir = dir(fullfile(paths.raw_neuropixel_data,strcat(exp_template,'*'),strcat(exp_template,'*'),strcat(exp_template,'*')));
                paths.neuropixel.to_sort = neuropixel_dir(1).folder;
    
                imec = Neuropixel.ImecDataset(paths.neuropixel.to_sort);
    
                if ~isfile(fullfile(paths.neuropixel.to_sort,"params.py"))
                    Neuropixel.runKilosort3(imec,paths,exp_template,workingdir=paths.neuropixel.workingdir);
                end
    
                % Save as kilosort object
                ks = Neuropixel.KilosortDataset(paths.neuropixel.to_sort);
                ks.load('loadFeatures',false);
                stats = ks.computeBasicStats();
                ks.printBasicStats();
    
                % Compute metrics
                metrics = ks.computeMetrics();

                % Waveforms plots
                figure; metrics.plotClusterWaveformAtCentroid();
                saveas(gca,fullfile(paths.raw_neuropixel_data,"plot-waveforms",exp_template),'fig');
    
    
                load(fullfile(paths.raw_neuropixel_data,"neuropixel_extraction_log.mat"));
    
                % Update neuropixel extraction log and saved processed data
                %save(fullfile(paths.processed_neuropixel_data,strcat(exp_template,'_imec')), 'imec');
                save(fullfile(paths.processed_neuropixel_data,strcat(exp_template,'_kilosort')), 'ks');
                save(fullfile(paths.processed_neuropixel_data,strcat(exp_template,'_metrics')), 'metrics');
                neuropixel_extraction_log(contains(neuropixel_extraction_log.Name,neuropixel_to_process{session,1}),:).Processed = true;
                display(strcat("Raw neuropixel data was processed for ",neuropixel_to_process{session,1}));
    
                save(fullfile(paths.raw_neuropixel_data,'neuropixel_extraction_log.mat'),'neuropixel_extraction_log');
                %catch
                %display(strcat("Error processiing neuropixel data for ",neuropixel_to_process{session,1}))
                %end
            end
        end
    end
end

% ################ BEHAVIOR #####################
% Process any unprocessed behavior data for this animal
[behavior_to_process] = fetchBehavior2Extract(animal_id,session_names,paths,resets.reset_behavior_data_processing);

for session = 1:height(behavior_to_process)

    % Find behavior data for given session
    session_behavior_data = load(fullfile(paths.raw_behavior_data,behavior_to_process{session}));
    div = strfind(behavior_to_process{session},'_');
    meta_data_to_load = dir(fullfile(paths.behavior_meta_data,strcat('*',behavior_to_process{session}(1:div(4)),'*')));

    if ~isempty(meta_data_to_load)
        session_meta_data = load(fullfile(paths.behavior_meta_data,meta_data_to_load.name));
        session_meta_data = session_meta_data.experimental_details;
    else
        session_meta_data = [];
        display(strcat(behavior_to_process{session},' does not have any session meta data on file. Please double check data integrity.'));
    end

    % Correct to standard pupil fs if not recorded properly
    if ischar(session_meta_data.pupil.pupil_fs)
        session_meta_data.pupil.pupil_fs = 10;
    end
    % Correct to standard whisker fs if not recorded properly
    if ischar(session_meta_data.whisker.whisker_fs)
        session_meta_data.whisker.whisker_fs = 50;
    end

    % Fetch behavior related data for the session
    [training_phase, paradigm, behavior_data] = fetch_behavior(session_behavior_data,params);

    behavior_data.session_stimuli = unique(behavior_data.stim_strength);
    behavior_data.meta_data = session_meta_data;
    behavior_data.session_id = behavior_to_process{session}(1:div(4)-1);
    behavior_data.paradigm = paradigm;
    behavior_data.training_phase = training_phase;
    behavior_data.pulse.power = session_meta_data.manipulation.optogenetic_manipulation;

    % Calculate frame count and start/end frame values for the session
    [video_details] = setSessionParameters(session_behavior_data,params,session_meta_data);

    behavior_data.video_details = video_details;

    % For each animal record for each session the sequential session number
    % in a given phase
    load(fullfile(paths.raw_behavior_data,"behavior_extraction_log.mat"));
    behavior_data.session_count = behavior_extraction_log(contains(behavior_extraction_log.Name,behavior_to_process{session,1}),:).Sequential_Session_Number;

    if contains(behavior_to_process{session},'Npxl') && params.process_neuropixel
        % Locate AP and LFP files and return corresponding metadata and
        % experiment data
        div = strfind(behavior_to_process{session},'_');

        % which channels to grab LFP data from
        chan_imec = [1:385];

        path = fullfile(paths.raw_neuropixel_data,strcat(behavior_to_process{session}(1:div(4)-1),'*'),strcat(behavior_to_process{session}(1:div(4)-1),'*'));
    
        to_load = dir(fullfile(path,strcat(behavior_to_process{session}(1:div(4)-1),'*lf.bin')));
        load(fullfile(paths.processed_neuropixel_data,strcat(behavior_to_process{session}(1:div(4)-1),'_kilosort')))
        sglx_data_IM_LF = ReadSGLXData(to_load.name, to_load.folder, chan_imec);

        LF_data = downsample(sglx_data_IM_LF.dataArray',5);

        save(fullfile(paths.processed_neuropixel_data,strcat(behavior_to_process{session}(1:div(4)-1),'_LFP')), 'LF_data','-v7.3');
    end

    % Update behavior extraction log and saved processed data
    save(fullfile(paths.processed_behavior_data,meta_data_to_load.name(1:div(4)-1)), 'behavior_data');
    behavior_extraction_log(contains(behavior_extraction_log.Name,behavior_to_process{session,1}),:).Processed = true;
    display(strcat("Raw behavior data was processed for ",behavior_to_process{session,1}));

    save(fullfile(paths.raw_behavior_data,'behavior_extraction_log.mat'),'behavior_extraction_log');
end

% ################ PHOTOMETRY #####################
% Find photometry data for given session and convert it to the
% processed from if it is not already.
if isfolder(paths.raw_photometry_data)
    [photometry_to_process] = fetchPhotometry2Extract(animal_id,session_names,paths,resets.reset_photometry_processing);

    for session = 1:length(photometry_to_process)

        % Find photometry data for given session
        div = strfind(photometry_to_process{session},'_');
        find_behavior_data = dir(fullfile(paths.processed_behavior_data,strcat('*',photometry_to_process{session}(1:div(4)-1),'*')));
        load(fullfile(find_behavior_data.folder,find_behavior_data.name),'behavior_data');

        % Fetch photometry related data for the session (corrected with moving
        % median
        [~,processed_photometry] = processRawPhotometry(behavior_data,paths,params);

        load(fullfile(paths.raw_photometry_data,"photometry_extraction_log.mat"));

        % Update photometry extraction log and saved processed data
        writematrix(processed_photometry,strcat(fullfile(paths.processed_photometry_data,behavior_data.session_id),'.csv'));
        photometry_extraction_log(contains(photometry_extraction_log.Name,photometry_to_process{session,1}),:).Processed = true;
        display(strcat("Raw photometry data was processed for ",photometry_to_process{session,1}));

        save(fullfile(paths.raw_photometry_data,'photometry_extraction_log.mat'),'photometry_extraction_log');
    end
end
end