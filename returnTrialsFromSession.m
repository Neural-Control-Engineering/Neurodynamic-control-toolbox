function [animal_summary_of_sessions] = returnTrialsFromSession(params,paths,session_names,behavior_data,pupil_data,whisker_data,photometry_data)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

[paradigm_params] = setParadigmSpecificParameters(behavior_data.paradigm);

% Set fs for data types
pupil_fs = behavior_data.meta_data.pupil.pupil_fs;
whisker_fs = behavior_data.meta_data.whisker.whisker_fs;
photometry_fs = 120; % Right now this is hard set because photometry processing script will downsample 1200 to 120

per5_channel1 = [];
per95_channel1 = [];
per5_channel2 = [];
per95_channel2 = [];
per5_pupil = [];
per95_pupil = [];
outcome_prop = [];
strength_prop = [];
go_prop = [];
prop = [];
time_sync_lag = [];

% Load all NI data for the session and precompute the time alignment
npxl_exist = dir(fullfile(paths.processed_neuropixel_data,strcat(behavior_data.session_id,'_kilosort.mat')));

if ~isempty(npxl_exist)

    load(fullfile(paths.processed_neuropixel_data,strcat(behavior_data.session_id,'_kilosort')));
    load(fullfile(paths.processed_neuropixel_data,strcat(behavior_data.session_id,'_metrics')));

    load(fullfile(paths.processed_neuropixel_data,strcat(behavior_data.session_id,'_LFP')));

    if strcmp(paths.data_source,"Project_Thalamic-Pupil-Synchronization")
    
        rise = diff(LF_data(:,end))>0;
        [idcs,~] = find(rise==1);
        add_onset_LF = idcs(1);
        delete_tail = idcs(end);
        LF_data = LF_data(add_onset_LF:delete_tail,:);
        
        time_sync_lag = length(LF_data)/(ks.raw_dataset.fsLF/5)-(behavior_data.video_details.pupil(3)/behavior_data.meta_data.pupil.pupil_fs);
        display(strcat("The total session lag between xPC and NI times was: ", string(time_sync_lag * 1000)," ms"));

    elseif strcmp(paths.data_source,"Project_Neurotransmitter-Exploration")
        
        path = fullfile(paths.raw_neuropixel_data,strcat(session_names{2},'*'));
        meta_data_to_load = dir(fullfile(path,strcat('*',session_names{2},'*.bin')));
        sglx_data_NI = ReadSGLXData(meta_data_to_load.name, meta_data_to_load.folder,1:5);
        niSampRate = str2num(sglx_data_NI.meta.niSampRate);
        rise = diff(sglx_data_NI.dataArray(3,:))>3;
        [~,idcs] = find(rise==1);
        add_onset_LF = round(((idcs(1)) / niSampRate) * (ks.raw_dataset.fsLF/5));
        delete_tail = round((idcs(end) / niSampRate) * (ks.raw_dataset.fsLF/5));
        LF_data = LF_data(add_onset_LF:delete_tail,:);

        time_sync_lag = length(LF_data)/(ks.raw_dataset.fsLF/5)-(behavior_data.video_details.pupil(3)/behavior_data.meta_data.pupil.pupil_fs);
        display(strcat("The total session lag between xPC and NI times was: ", string(time_sync_lag * 1000)," ms"));

    end

end

if ~strcmp(behavior_data.training_phase,"Phase 0") && pupil_fs == 10
    % Create empty cell array to house trial summaries for this session
    animal_summary_of_sessions = cell(height(behavior_data.stim_times)-1,params.num_of_properties);
    
    % Precalculate for the session pupil data
    if ~isempty(photometry_data)
        per5_pupil = prctile(photometry_data{:,2},5);   
        per95_pupil = prctile(photometry_data{:,2},95);
    end
    
    % Precalculate for the session photometry data
    if ~isempty(photometry_data)
        
        per5_channel1 = prctile(photometry_data{:,2},5);   
        per95_channel1 = prctile(photometry_data{:,2},95);
        
        if width(photometry_data) > 3
            per5_channel2 = prctile(photometry_data{:,3},5);
            per95_channel2 = prctile(photometry_data{:,3},95);
        end
    end
    
    for trial_num = 1:height(behavior_data.stim_times)-1 % skip last trial since many of the metrics cannot be calculated
    
        prop = 1;
    
        % Define stimulus time as a reference point
        stim_time = behavior_data.stim_times(trial_num);
        stim_time_next = behavior_data.stim_times(trial_num + 1);
        % Define the onset time of the next trial (or end of session) for
        % subsequent calculations
        if trial_num < length(behavior_data.trial_onset_tone) - 1
            % changed the logic of finding next trial onset tone
            onset_tone_next = behavior_data.trial_onset_tone(behavior_data.trial_onset_tone > stim_time);
            onset_tone_next = onset_tone_next(1);
        else
            onset_tone_next = behavior_data.wheel_displacement(end,1);
        end
    
        % 1: animal name
        animal_summary_of_sessions{trial_num,prop} = session_names{:,2}; prop = prop+1;
        % 2: date
        animal_summary_of_sessions{trial_num,prop} = datetime(strcat(session_names{:,5},'_',session_names{:,6},'_',session_names{:,7}),'InputFormat','uuuu_MM_dd'); prop = prop+1;
        % 3: paradigm
        animal_summary_of_sessions{trial_num,prop} = behavior_data.paradigm; prop = prop+1;
        % 4: phase
        animal_summary_of_sessions{trial_num,prop} = behavior_data.training_phase; prop = prop+1;
        % 5: session number
        animal_summary_of_sessions{trial_num,prop} = behavior_data.session_count; prop = prop+1;
        % 6: trial number
        animal_summary_of_sessions{trial_num,prop} = trial_num; prop = prop+1;
        % 7: Inter-stimulus interval
        if trial_num ~= 1 && trial_num ~= height(behavior_data.stim_times)
            animal_summary_of_sessions{trial_num,prop} = behavior_data.stim_times(trial_num+1) - behavior_data.stim_times(trial_num);
        end
        prop = prop+1;
        % 8: trial onset time
        onset_prop = prop;
        temp = behavior_data.trial_onset_tone(behavior_data.trial_onset_tone<stim_time);
        animal_summary_of_sessions{trial_num,prop} = temp(end); prop = prop+1;
        % 9 stimulus time
        stim_prop = prop;
        animal_summary_of_sessions{trial_num,prop} = behavior_data.stim_times(trial_num);  prop = prop+1;
        % 10 stimulus strength
        strength_prop = prop;
        animal_summary_of_sessions{trial_num,prop} = behavior_data.stim_strength(trial_num); prop = prop+1;
        % 11: licks
        licks_prop = prop;
        if trial_num + 1 <= height(behavior_data.stim_times) - 1
            next_trial_start_idx = find(behavior_data.trial_onset_tone == animal_summary_of_sessions{trial_num,onset_prop})+1;
            animal_summary_of_sessions{trial_num,prop} = behavior_data.lick_times(behavior_data.lick_times>=animal_summary_of_sessions{trial_num,onset_prop} & behavior_data.lick_times<behavior_data.trial_onset_tone(next_trial_start_idx));
        end
        prop = prop+1;
        % 12: response time
        first_lick = [];
        if ~isempty(animal_summary_of_sessions{trial_num,licks_prop})
            temp = animal_summary_of_sessions{trial_num,licks_prop} ;
            temp = temp(temp > stim_time);
            if ~isempty(temp); first_lick = temp(1);
                animal_summary_of_sessions{trial_num,prop} = first_lick-animal_summary_of_sessions{trial_num,stim_prop};
            else
                animal_summary_of_sessions{trial_num,prop} = nan;
            end
        else
            animal_summary_of_sessions{trial_num,prop} = nan;
        end
        prop = prop+1;
        % 13 go / no-go
        go_prop = prop;
        if ~isempty(behavior_data.lick_times)
            animal_summary_of_sessions{trial_num,prop} =  ~isempty(behavior_data.lick_times(behavior_data.lick_times(:,1)>=behavior_data.stim_times(trial_num) & behavior_data.lick_times(:,1)<(behavior_data.stim_times(trial_num)+paradigm_params.response_window),:));
        else
            animal_summary_of_sessions{trial_num,prop} = false;
        end
        prop = prop+1;
        % 14 delayed response (near hit), 2x response window
        near_hit_prop = prop;
        if ~isempty(first_lick)    
            animal_summary_of_sessions{trial_num,prop} = first_lick>behavior_data.stim_times(trial_num)+paradigm_params.response_window & first_lick<=(behavior_data.stim_times(trial_num)+paradigm_params.response_window*2);
        else
            animal_summary_of_sessions{trial_num,prop} = false;
        end
        prop = prop+1;
        % 15: outcome
        outcome_prop=prop;
        response = zeros(1,2);
        if ~isempty(animal_summary_of_sessions{trial_num,go_prop})
            response(:,1) = animal_summary_of_sessions{trial_num,go_prop};
            response(:,2) = animal_summary_of_sessions{trial_num,near_hit_prop};
        end
        animal_summary_of_sessions{trial_num,prop} = determineTrialOutcome(animal_summary_of_sessions{trial_num,strength_prop},response); 
        prop = prop+1;
        % 16: previous outcome
        if trial_num ~= 1
            animal_summary_of_sessions{trial_num,prop} = animal_summary_of_sessions{trial_num-1,outcome_prop};
        end
        prop = prop+1;
        % 17: previous outcome
        animal_summary_of_sessions{trial_num,prop} = animal_summary_of_sessions{trial_num,stim_prop} - animal_summary_of_sessions{trial_num,onset_prop};
        prop = prop+1;
        % 18: Time of distractor puffs
        local_distractor_times = behavior_data.distractor_times(behavior_data.distractor_times >= animal_summary_of_sessions{trial_num,onset_prop} & behavior_data.distractor_times < onset_tone_next);
        if ~isempty(local_distractor_times)
            animal_summary_of_sessions{trial_num,prop} = local_distractor_times;
        end
        prop = prop+1;
        % 19: Photometry - Channel 1 region
        animal_summary_of_sessions{trial_num,prop} = behavior_data.meta_data.photometry.channel_1_region;
        prop = prop+1;
        % 20: Channel 1 - 5th percentile value
        animal_summary_of_sessions{trial_num,prop} = per5_channel1;
        prop = prop+1;
        % 21: Channel 1 - 95th percentile value
        animal_summary_of_sessions{trial_num,prop} = per95_channel1;
        prop = prop+1;
        % 22: Photometry - Channel 2 region
        animal_summary_of_sessions{trial_num,prop} = behavior_data.meta_data.photometry.channel_2_region;
        prop = prop+1;
        % 23: Channel 2 - 5th percentile value
        animal_summary_of_sessions{trial_num,prop} = per5_channel2;
        prop = prop+1;
        % 24: Channel 2 - 95th percentile value
        animal_summary_of_sessions{trial_num,prop} = per95_channel2;
        prop = prop+1;
        % 25: Optogenetic manipulation
        animal_summary_of_sessions{trial_num,prop} = behavior_data.meta_data.manipulation.optogenetic_manipulation;
        opto_prop = prop;
        prop = prop+1;
        % 26: Chemogenetic/pharmacological manipulation
        animal_summary_of_sessions{trial_num,prop} = behavior_data.meta_data.manipulation.chemogenetic_manipulation;
        prop = prop+1;
        % 27: Chemogenetic/pharmacological dosage
        animal_summary_of_sessions{trial_num,prop} = behavior_data.meta_data.manipulation.chemogenetic_dose;
        prop = prop+1;
    
        % Combined pupil
        if ~isempty(pupil_data)
            [~,onset_idx] = min(abs(pupil_data{:,1}/pupil_fs-animal_summary_of_sessions{trial_num,onset_prop}));
            [~,stim_idx] = min(abs(pupil_data{:,1}/pupil_fs-stim_time));
            [~,onset_idx_next] = min(abs(pupil_data{:,1}/pupil_fs-onset_tone_next));
            %___________________________
            pupil_baseline_window = 0.5;
            % 28: Window for baseline calculation
            animal_summary_of_sessions{trial_num,prop} = pupil_baseline_window;
            prop = prop+1;
            % 29: Pupil baseline before onset tone
            start_idx = onset_idx - (pupil_baseline_window * pupil_fs);
            if start_idx > 0
                baseline_pupil = mean(pupil_data{start_idx:onset_idx,2});
                animal_summary_of_sessions{trial_num,prop} = baseline_pupil;
            end
            prop = prop+1;
            % 30: Pupil baseline before stimulus
            start_idx = stim_idx - (pupil_baseline_window * pupil_fs);
            if start_idx > 0
                baseline_pupil = mean(pupil_data{start_idx:stim_idx,2});
                animal_summary_of_sessions{trial_num,prop} = baseline_pupil;
            end
            prop = prop+1;
            % 31: pupil area (z-scored) 2s before trial start to trial end w/ time in first column
            start_idx = onset_idx - (2 * pupil_fs);
            if start_idx > 0
                pupil = pupil_data{start_idx:onset_idx_next,1:2};
                pupil(:,1) = pupil(:,1)/pupil_fs;
                animal_summary_of_sessions{trial_num,prop} = pupil;
            end
            prop = prop+1;
            % 32: pupil - 5th percentile value from session
            animal_summary_of_sessions{trial_num,prop} = per5_pupil;
            prop = prop+1;
            % 33: pupil - 95th percentile value from session
            animal_summary_of_sessions{trial_num,prop} = per95_pupil;
            prop = prop+1;
        else
            prop = prop+6;
        end
        % Combined photometry
        if ~isempty(photometry_data)
            [~,onset_idx] = min(abs(photometry_data{:,1}-animal_summary_of_sessions{trial_num,onset_prop}));
            [~,stim_idx] = min(abs(photometry_data{:,1}-stim_time));
            [~,onset_idx_next] = min(abs(photometry_data{:,1}-onset_tone_next)); 
            %___________________________
            photometry_baseline_window = 0.5;
            % 34: Window for baseline calculation
            animal_summary_of_sessions{trial_num,prop} = photometry_baseline_window;
            prop = prop+1;
            % 35: Channel 1 baseline before onset tone
            start_idx = onset_idx - (photometry_baseline_window * photometry_fs);
            if start_idx > 0
                baseline_photometry = mean(photometry_data{start_idx:onset_idx,2});
                animal_summary_of_sessions{trial_num,prop} = baseline_photometry;
            end
            prop = prop+1;
            % 36: Channel 1 baseline before stimulus
            start_idx = stim_idx - (photometry_baseline_window * photometry_fs);
            if start_idx > 0
                baseline_photometry = mean(photometry_data{start_idx:stim_idx,2});
                animal_summary_of_sessions{trial_num,prop} = baseline_photometry;
            end
            prop = prop+1;
            % 37: Channel 1 photometry (z-score)
            start_idx = onset_idx - (2 * photometry_fs);
            if start_idx > 0
                photometry = photometry_data{start_idx:onset_idx_next,1:2};
                animal_summary_of_sessions{trial_num,prop} = photometry;
            end
            prop = prop+1;

            % 38: Channel 1 photometry (LP + z-score)
            start_idx = onset_idx - (2 * photometry_fs);
            if start_idx > 0
                photometry = photometry_data{start_idx:onset_idx_next,[1,5]};
                animal_summary_of_sessions{trial_num,prop} = photometry;
            end
            prop = prop+1;

            if width(photometry_data) > 3 % for old, single channel photometry data
                % 39: Channel 2 baseline before onset tone
                start_idx = onset_idx - (photometry_baseline_window * photometry_fs);
                if start_idx > 0
                    baseline_photometry = mean(photometry_data{start_idx:onset_idx,3});
                    animal_summary_of_sessions{trial_num,prop} = baseline_photometry;
                end
                prop = prop+1;
                % 40: Channel 2 baseline before stimulus
                start_idx = stim_idx - (photometry_baseline_window * photometry_fs);
                if start_idx > 0
                    baseline_photometry = mean(photometry_data{start_idx:stim_idx,3});
                    animal_summary_of_sessions{trial_num,prop} = baseline_photometry;
                end
                prop = prop+1;
                % 41: Channel 2 photometry (z-score)
                start_idx = onset_idx - (2 * photometry_fs);
                if start_idx > 0
                    photometry = photometry_data{start_idx:onset_idx_next,[1 3]};
                    animal_summary_of_sessions{trial_num,prop} = photometry;
                end
                prop = prop+1;      
                start_idx = onset_idx - (2 * photometry_fs);
                % 42: Channel 2 photometry (LP + zscore)
                if start_idx > 0
                    photometry = photometry_data{start_idx:onset_idx_next,[1,6]};
                    animal_summary_of_sessions{trial_num,prop} = photometry;
                end
                prop = prop+1;
            else
                prop = prop +4;
            end
        else
            prop = prop+7;
        end
        % Combined whisker
        if ~isempty(whisker_data)
            [~,onset_idx] = min(abs(whisker_data{:,1}-animal_summary_of_sessions{trial_num,onset_prop}));
            [~,onset_idx_next] = min(abs(whisker_data{:,1}-onset_tone_next)); 
            % 41. Whisker (rad) from 2 second before trial to end of trial
            start_idx = onset_idx - (2 * whisker_fs);
            if start_idx > 0
                whisker = whisker_data{start_idx:onset_idx_next,1:2};
                animal_summary_of_sessions{trial_num,prop} = whisker;
            end
            prop = prop+1; 
        else
            prop = prop+1; 
        end
        % 42: Wheel displacement
        [~,onset_idx] = min(abs(behavior_data.wheel_displacement(:,1) - animal_summary_of_sessions{trial_num,onset_prop}));
        [~,onset_idx_next] = min(abs(behavior_data.wheel_displacement(:,1)-onset_tone_next)); 
        start_idx = onset_idx - (2 * 100);    
        if start_idx > 0
            trials_movement = abs(zscore(behavior_data.wheel_displacement(start_idx:onset_idx_next,1:2) - behavior_data.wheel_displacement(start_idx,2)));
            animal_summary_of_sessions{trial_num,prop} = trials_movement;
        end
        prop = prop+1;
        % 43: Optogenetic stimulation pulse times
        if isfield(behavior_data.pulse, 'rise_times')
            animal_summary_of_sessions{trial_num,prop} = behavior_data.pulse.rise_times(behavior_data.pulse.rise_times > cell2mat(animal_summary_of_sessions(trial_num,onset_prop)) & behavior_data.pulse.rise_times < onset_tone_next);
        else
            animal_summary_of_sessions{trial_num,prop} = [];
        end
        prop = prop+1;
        % 44: Optogenetic stimulation start time
        if ~isempty(animal_summary_of_sessions{trial_num,prop-1})
            opto = animal_summary_of_sessions{trial_num,opto_prop};
            opto_split = split(opto,' ');
            freq = animal_summary_of_sessions{trial_num,prop-1};
            freq = height(freq)/(freq(end) - freq(1));
            temp = [str2double(opto_split{1}),freq];
            animal_summary_of_sessions{trial_num,prop} = temp;
        else
            animal_summary_of_sessions{trial_num,prop} = [];
        end
        prop = prop+1;
    
    %         % 30: correlation coefficient between pupil and mPFC
    %     if ~isempty(pupil_area) && ~isempty(photometry_data)
    %         [~,stim_idx_pupil] = min(abs(pupil_area(:,1)-stim_time));
    %         start_idx_pupil = stim_idx_pupil - (corr_window * pupil_fs - 1);
    %         pupil_vec = pupil_area(start_idx_pupil:stim_idx_pupil,2);
    %         [~,stim_idx_photo] = min(abs(processed_photometry_data(:,1)-stim_time));
    %         start_idx_photo = stim_idx_photo - (corr_window * photometry_fs - 1);
    %         mPFC_vec = processed_photometry_data(start_idx_photo:stim_idx_photo,2);
    %         corr = corrcoef(pupil_vec,downsample(mPFC_vec,12));
    %         animal_summary_of_sessions{trial_num,prop} = corr(2);
    %         prop = prop+1;
    %     
    %         % 31: correlation coefficient between pupil and S1
    %         S1_vec = processed_photometry_data(start_idx_photo:stim_idx_photo,3);
    %         corr = corrcoef(pupil_vec,downsample(S1_vec,12));
    %         animal_summary_of_sessions{trial_num,prop} = corr(2);
    %         prop=prop+1;
    % 
    %         % 32: correlation coefficient between mPFC and S1
    %         corr = corrcoef(downsample(mPFC_vec,12),downsample(S1_vec,12));
    %         animal_summary_of_sessions{trial_num,prop} = corr(2);
    %         prop=prop+1;
    % 
    %         % 36 (for now): CC between pupil and mPFC
    %         corr_window_x = 4;
    %         start_idx_pupil = stim_idx_pupil - (corr_window_x * pupil_fs - 1);
    %         pupil_vec = pupil_area(start_idx_pupil:stim_idx_pupil,2);
    %         [~,stim_idx_photo] = min(abs(processed_photometry_data(:,1)-stim_time));
    %         start_idx_photo = stim_idx_photo - (corr_window_x * photometry_fs - 1);
    %         mPFC_vec = processed_photometry_data(start_idx_photo:stim_idx_photo,2);
    %         [CC,~] = xcorr(pupil_vec,downsample(mPFC_vec,12));
    %         animal_summary_of_sessions{trial_num,36} = CC;
    % 
    %         % 37 (for now): CC between pupil and S1
    %         S1_vec = processed_photometry_data(start_idx_photo:stim_idx_photo,3);
    %         [CC,~] = xcorr(pupil_vec,downsample(S1_vec,12));
    %         animal_summary_of_sessions{trial_num,37} = CC;
    % 
    %         % 38 (for now): correlation coefficient between mPFC and S1
    %         CC = xcorr(downsample(mPFC_vec,12),downsample(S1_vec,12));
    %         animal_summary_of_sessions{trial_num,38} = CC;
    % 
    %         % 39 (for now): CC between diff(pupil) and mPFC
    %         corr_window_x = 4;
    %         start_idx_pupil = stim_idx_pupil - (corr_window_x * pupil_fs - 1);
    %         pupil_vec = diff(pupil_area(start_idx_pupil:stim_idx_pupil,2));
    %         [~,stim_idx_photo] = min(abs(processed_photometry_data(:,1)-stim_time));
    %         start_idx_photo = stim_idx_photo - (corr_window_x * photometry_fs - 1);
    %         mPFC_vec = processed_photometry_data(start_idx_photo:stim_idx_photo,2);
    %         [CC,~] = xcorr(pupil_vec,downsample(mPFC_vec,12));
    %         animal_summary_of_sessions{trial_num,39} = CC;
    % 
    %         % 40 (for now): CC between diff(pupil) and S1
    %         S1_vec = processed_photometry_data(start_idx_photo:stim_idx_photo,3);
    %         [CC,~] = xcorr(pupil_vec,downsample(S1_vec,12));
    %         animal_summary_of_sessions{trial_num,40} = CC;
    % 
    %         % 41 (for now): CC between pupil and diff(mPFC)
    %         corr_window_x = 4;
    %         start_idx_pupil = stim_idx_pupil - (corr_window_x * pupil_fs - 1);
    %         pupil_vec = pupil_area(start_idx_pupil:stim_idx_pupil,2);
    %         [~,stim_idx_photo] = min(abs(processed_photometry_data(:,1)-stim_time));
    %         start_idx_photo = stim_idx_photo - (corr_window_x * photometry_fs - 1);
    %         mPFC_vec = diff(processed_photometry_data(start_idx_photo:stim_idx_photo,2));
    %         [CC,~] = xcorr(pupil_vec,downsample(mPFC_vec,12));
    %         animal_summary_of_sessions{trial_num,41} = CC;
    % 
    %         % 42 (for now): CC between pupil and diff(S1)
    %         S1_vec = diff(processed_photometry_data(start_idx_photo:stim_idx_photo,3));
    %         [CC,~] = xcorr(pupil_vec,downsample(S1_vec,12));
    %         animal_summary_of_sessions{trial_num,42} = CC;
    % 
    %         % 43 (for now): correlation coefficient between diff(mPFC) and S1
    %         mPFC_vec = diff(processed_photometry_data(start_idx_photo:stim_idx_photo,2));
    %         S1_vec = processed_photometry_data(start_idx_photo:stim_idx_photo,3);
    %         CC = xcorr(downsample(mPFC_vec,12),downsample(S1_vec,12));
    %         animal_summary_of_sessions{trial_num,43} = CC;
    % 
    %         % 44 (for now): correlation coefficient between mPFC and diff(S1)
    %         mPFC_vec = processed_photometry_data(start_idx_photo:stim_idx_photo,2);
    %         S1_vec = diff(processed_photometry_data(start_idx_photo:stim_idx_photo,3));
    %         CC = xcorr(downsample(mPFC_vec,12),downsample(S1_vec,12));
    %         animal_summary_of_sessions{trial_num,44} = CC;
    % 
    %         % 45 (for now): correlation coefficient between diff(mPFC) and diff(S1)
    %         mPFC_vec = diff(processed_photometry_data(start_idx_photo:stim_idx_photo,2));
    %         S1_vec = diff(processed_photometry_data(start_idx_photo:stim_idx_photo,3));
    %         CC = xcorr(downsample(mPFC_vec,12),downsample(S1_vec,12));
    %         animal_summary_of_sessions{trial_num,45} = CC;
    % 
    % 
    % 
    %     else
    %         prop = prop+3;
    %     end
        
        if ~isempty(npxl_exist)
            % Document AP and LF fs here to recover times downstream
            % 45: AP sampling rate
            animal_summary_of_sessions{trial_num,prop} = ks.fsAP;
            prop = prop+1;
    
            % 46: LF sampling rate
            animal_summary_of_sessions{trial_num,prop} = ks.raw_dataset.fsLF/5;
            prop = prop+1;
       
            time_trial_start = animal_summary_of_sessions{trial_num,onset_prop};
    
            % 47: LFP data between set indices for LFP
            if params.process_LFP          
                start_idx = round(time_trial_start * ks.raw_dataset.fsLF/5 + params.drop_buffer_start * ks.raw_dataset.fsLF/5);
                stop_idx = round(onset_tone_next * ks.raw_dataset.fsLF/5 + params.drop_buffer_start * ks.raw_dataset.fsLF/5)-1;
                %animal_summary_of_sessions{trial_num,prop} = sglx_data_IM_LF.dataArray(ks.raw_dataset.goodChannelInds,start_idx:stop_idx);
                animal_summary_of_sessions{trial_num,prop} = LF_data(start_idx:stop_idx,ks.raw_dataset.goodChannelInds)';            
            else
                animal_summary_of_sessions{trial_num,prop} = [];
            end
    
            prop = prop+1;
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Set indices for AP
            start_idx = round(time_trial_start * ks.fsAP + params.drop_buffer_start * ks.fsAP);
            stop_idx = round(onset_tone_next * ks.fsAP + params.drop_buffer_start * ks.fsAP)-1;
    
            temp_cluster = []; temp_spike_times = []; temp_amplitude = []; good_clusters = [];
            temp_cluster = ks.spike_clusters(ismember(ks.spike_clusters,ks.clusters_good));
            temp_spike_times = ks.spike_times(ismember(ks.spike_clusters,ks.clusters_good)) - add_onset_LF/(ks.raw_dataset.fsLF/5)*ks.fsAP; % use the LF data that has info about extra recording time at beginning of session
            temp_amplitude = metrics.spike_amplitude(ismember(ks.spike_clusters,ks.clusters_good));
            good_clusters(:,1) = ks.cluster_ids;
            good_clusters(:,2) = ks.cluster_groups;
            good_clusters = good_clusters(good_clusters(:,2)==2,:);
            
            
            seg_spike_times = temp_spike_times(temp_spike_times >= start_idx & temp_spike_times <= stop_idx);
            seg_cluster = temp_cluster(temp_spike_times >= start_idx & temp_spike_times < stop_idx);
            seg_amplitude = temp_amplitude(temp_spike_times >= start_idx & temp_spike_times < stop_idx);
            good_clusters(:,3) = ismember(good_clusters(:,1),unique(seg_cluster));
            seg_centroid = metrics.cluster_centroid(logical(good_clusters(:,3)),:);
            seg_waveform = metrics.cluster_waveform(logical(good_clusters(:,3)),:);
    
            % 48: segment spike times
            spike_time_prop = prop;
            animal_summary_of_sessions{trial_num,prop} = seg_spike_times - params.drop_buffer_start*ks.fsAP;
            prop = prop+1;
            
            % 49: segment cluster labels
            animal_summary_of_sessions{trial_num,prop} = seg_cluster;
            prop = prop+1;
            
            % 50: segment cluster amplitudes
            animal_summary_of_sessions{trial_num,prop} = seg_amplitude;
            prop = prop+1;
            
            % 51: segment cluster centroids
            animal_summary_of_sessions{trial_num,prop} = seg_centroid;
            prop = prop+1;
            
            % 52: segment waveform
            animal_summary_of_sessions{trial_num,prop} = seg_waveform;
            prop = prop+1;
    
            % 53: kilosort onset index
            temp = minus(animal_summary_of_sessions{trial_num,spike_time_prop}, animal_summary_of_sessions{trial_num,stim_prop}*ks.fsAP);
            temp2 = temp(temp>0);
            [idx,~] = find(temp == temp2(1));
            animal_summary_of_sessions{trial_num,prop} = idx;
            prop = prop+1;   
    
            % 54: LF onset index
            animal_summary_of_sessions{trial_num,prop} = (animal_summary_of_sessions{trial_num,stim_prop}-animal_summary_of_sessions{trial_num,onset_prop})*ks.raw_dataset.fsLF/5;
            prop = prop+1;   
    
            % 55: Time descrepency between xPC and NI for the entire session
            animal_summary_of_sessions{trial_num,prop} = time_sync_lag;
            prop = prop+1;   
    
        else
            prop = prop + 11;
        end


    end
        
    % Session behavior metrics
    [psychometric_performance] = calculatePsychometricCurves([animal_summary_of_sessions{:,strength_prop}]',[animal_summary_of_sessions{:,go_prop}]',behavior_data.training_phase,behavior_data.session_stimuli);
    Hit_rate = psychometric_performance(2,2:end);
    
    Hit_rate(Hit_rate == 0) = 0.01;
    Hit_rate(Hit_rate == 1) = 0.99;
    
    FA_rate = psychometric_performance(2,1); 
    if FA_rate == 0
        FA_rate = 0.01;
    elseif FA_rate == 1
        FA_rate = 0.99;
    end
    [dprime,criterion] = dprime_simple(Hit_rate,FA_rate);
    
    for i = 1:height(animal_summary_of_sessions)
        % 58: psychometric curve for session
        animal_summary_of_sessions{i,prop} = psychometric_performance; 
        % 59: dprime
        animal_summary_of_sessions{i,prop+1} = dprime;
        % 60: criterion
        animal_summary_of_sessions{i,prop+2} = criterion;
    end
    %prop = prop+3;
    %######################################################################
elseif pupil_fs == 10 % CODE FOR PHASE 0 (SPONTANEOUS) DATA
    animal_summary_of_sessions = cell(1,params.num_of_properties);
    
    % Precalculate for the session pupil data
    if ~isempty(photometry_data)
        per5_pupil = prctile(photometry_data{:,2},5);   
        per95_pupil = prctile(photometry_data{:,2},95);
    end
    
    % Precalculate for the session photometry data
    if ~isempty(photometry_data)
        per5_channel1 = prctile(photometry_data{:,2},5);   
        per95_channel1 = prctile(photometry_data{:,2},95);
        
        per5_channel2 = prctile(photometry_data{:,3},5);
        per95_channel2 = prctile(photometry_data{:,3},95);
    end
    
    for trial_num = 1 % Just calculate for the entire session for metrics that can be computed
    
        prop = 1;
    
        % 1: animal name
        animal_summary_of_sessions{trial_num,prop} = session_names{:,2}; prop = prop+1;
        % 2: date
        animal_summary_of_sessions{trial_num,prop} = datetime(strcat(session_names{:,5},'_',session_names{:,6},'_',session_names{:,7}),'InputFormat','uuuu_MM_dd'); prop = prop+1;
        % 3: paradigm
        animal_summary_of_sessions{trial_num,prop} = behavior_data.paradigm; prop = prop+1;
        % 4: phase
        animal_summary_of_sessions{trial_num,prop} = behavior_data.training_phase; prop = prop+1;
        % 5: session number
        animal_summary_of_sessions{trial_num,prop} = behavior_data.session_count; prop = prop+1;
        % 6: trial number
        animal_summary_of_sessions{trial_num,prop} = NaN; prop = prop+1;
        % 7: Inter-stimulus interval
        animal_summary_of_sessions{trial_num,prop} = NaN; prop = prop+1;
        % 8: trial onset time
        animal_summary_of_sessions{trial_num,prop} = 0; prop = prop+1;
        % 9 stimulus time
        animal_summary_of_sessions{trial_num,prop} = NaN;  prop = prop+1;
        % 10 stimulus strength
        animal_summary_of_sessions{trial_num,prop} = NaN; prop = prop+1;
        % 11: licks
        animal_summary_of_sessions{trial_num,prop} = behavior_data.lick_times; prop = prop+1;
        % 12: response time
        animal_summary_of_sessions{trial_num,prop} = NaN; prop = prop+1;
        % 13 go / no-go
        animal_summary_of_sessions{trial_num,prop} = NaN; prop = prop+1;
        % 14 delayed response (near hit), 2x response window
        animal_summary_of_sessions{trial_num,prop} = NaN; prop = prop+1;
        % 15: outcome
        animal_summary_of_sessions{trial_num,prop} = NaN; prop = prop+1;
        % 16: previous outcome
        animal_summary_of_sessions{trial_num,prop} = NaN; prop = prop+1;
        % 17: Time between onset tone and stim
        animal_summary_of_sessions{trial_num,prop} = NaN; prop = prop+1;
        % 18: Time of distractor puffs
        animal_summary_of_sessions{trial_num,prop} = NaN; prop = prop+1;
        % 19: Photometry - Channel 1 region
        animal_summary_of_sessions{trial_num,prop} = behavior_data.meta_data.photometry.channel_1_region;
        prop = prop+1;
        % 20: Channel 1 - 5th percentile value
        animal_summary_of_sessions{trial_num,prop} = per5_channel1;
        prop = prop+1;
        % 21: Channel 1 - 95th percentile value
        animal_summary_of_sessions{trial_num,prop} = per95_channel1;
        prop = prop+1;
        % 22: Photometry - Channel 2 region
        animal_summary_of_sessions{trial_num,prop} = behavior_data.meta_data.photometry.channel_2_region;
        prop = prop+1;
        % 23: Channel 2 - 5th percentile value
        animal_summary_of_sessions{trial_num,prop} = per5_channel2;
        prop = prop+1;
        % 24: Channel 2 - 95th percentile value
        animal_summary_of_sessions{trial_num,prop} = per95_channel2;
        prop = prop+1;
        % 25: Optogenetic manipulation
        animal_summary_of_sessions{trial_num,prop} = behavior_data.meta_data.manipulation.optogenetic_manipulation;
        opto_prop = prop;
        prop = prop+1;
        % 26: Chemogenetic/pharmacological manipulation
        animal_summary_of_sessions{trial_num,prop} = behavior_data.meta_data.manipulation.chemogenetic_manipulation;
        prop = prop+1;
        % 27: Chemogenetic/pharmacological dosage
        animal_summary_of_sessions{trial_num,prop} = behavior_data.meta_data.manipulation.chemogenetic_dose;
        prop = prop+1;
    
        % Combined pupil
        if ~isempty(pupil_data)
            onset_idx = 1;
            
            onset_idx_next = height(pupil_data);
            %___________________________
           
            % 28: Window for baseline calculation
            animal_summary_of_sessions{trial_num,prop} = height(pupil_data)/pupil_fs;
            prop = prop+1;
            % 29: Pupil baseline before onset tone
            baseline_pupil = mean(pupil_data{:,2});
            animal_summary_of_sessions{trial_num,prop} = baseline_pupil;
            prop = prop+1;
            % 30: Pupil baseline before stimulus
            animal_summary_of_sessions{trial_num,prop} = NaN; prop = prop+1;
            % 31: pupil area (z-scored) 2s before trial start to trial end w/ time in first column
            pupil = pupil_data{:,1:2};
            pupil(:,1) = pupil(:,1)/pupil_fs;
            animal_summary_of_sessions{trial_num,prop} = pupil;
            prop = prop+1;
            % 32: pupil - 5th percentile value from session
            animal_summary_of_sessions{trial_num,prop} = per5_pupil;
            prop = prop+1;
            % 33: pupil - 95th percentile value from session
            animal_summary_of_sessions{trial_num,prop} = per95_pupil;
            prop = prop+1;
        else
            prop = prop+6;
        end
        % Combined photometry
        if ~isempty(photometry_data)
            %___________________________
            % 34: Window for baseline calculation
            animal_summary_of_sessions{trial_num,prop} =  height(photometry_data)/photometry_fs;
            prop = prop+1;
            % 35: Channel 1 baseline before onset tone
            animal_summary_of_sessions{trial_num,prop} = mean(photometry_data{:,2});
            prop = prop+1;
            % 36: Channel 1 baseline before stimulus
            animal_summary_of_sessions{trial_num,prop} = NaN; prop = prop+1;
            % 37: Channel 1 photometry (z-score)
            animal_summary_of_sessions{trial_num,prop} = photometry_data{start_idx:onset_idx_next,1:2};
            prop = prop+1;        
            % 38: Channel 2 baseline before onset tone
            animal_summary_of_sessions{trial_num,prop} = mean(photometry_data{:,3});
            prop = prop+1;
            % 39: Channel 1 baseline before stimulus
            animal_summary_of_sessions{trial_num,prop} = NaN; prop = prop+1;
            % 40: Channel 2 photometry (z-score)
            animal_summary_of_sessions{trial_num,prop} = photometry_data{:,[1 3]};
            prop = prop+1;        
        else
            prop = prop+7;
        end
        % Combined whisker
        if ~isempty(whisker_data)
            % 41. Whisker (rad) from 2 second before trial to end of trial
            whisker = whisker_data{:,1:2};
            animal_summary_of_sessions{trial_num,prop} = whisker;
            prop = prop+1; 
        else
            prop = prop+1; 
        end
        % 42: Wheel displacement
        animal_summary_of_sessions{trial_num,prop} = NaN; prop = prop+1;
        % 43: Optogenetic stimulation pulse times
        if isfield(behavior_data.pulse, 'rise_times')
            animal_summary_of_sessions{trial_num,prop} = behavior_data.pulse.rise_times(:);
        else
            animal_summary_of_sessions{trial_num,prop} = [];
        end
        prop = prop+1;
        % 44: Optogenetic stimulation start time
        if ~isempty(animal_summary_of_sessions{trial_num,prop-1})
            opto = animal_summary_of_sessions{trial_num,opto_prop};
            opto_split = split(opto,' ');
            freq = animal_summary_of_sessions{trial_num,prop-1};
            freq = height(freq)/(freq(end) - freq(1));
            temp = [str2double(opto_split{1}),freq];
            animal_summary_of_sessions{trial_num,prop} = temp;
        else
            animal_summary_of_sessions{trial_num,prop} = [];
        end
        prop = prop+1;
        
        if ~isempty(npxl_exist)
            % Document AP and LF fs here to recover times downstream
            % 45: AP sampling rate
            animal_summary_of_sessions{trial_num,prop} = ks.fsAP;
            prop = prop+1;
    
            % 46: LF sampling rate
            animal_summary_of_sessions{trial_num,prop} = ks.raw_dataset.fsLF/5;
            prop = prop+1;
    
            % 47: LFP data between set indices for LFP
            process_LFP = params.process_LFP;
            if process_LFP          
                start_idx = round(params.drop_buffer_start * ks.raw_dataset.fsLF/5);
                stop_idx = height(LF_data);
                %animal_summary_of_sessions{trial_num,prop} = sglx_data_IM_LF.dataArray(ks.raw_dataset.goodChannelInds,start_idx:stop_idx);
                animal_summary_of_sessions{trial_num,prop} = LF_data(start_idx:stop_idx,ks.raw_dataset.goodChannelInds)';            
            else
                animal_summary_of_sessions{trial_num,prop} = [];
            end
    
            prop = prop+1;
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Set indices for AP  
            temp_cluster = []; temp_spike_times = []; temp_amplitude = []; good_clusters = [];
            temp_cluster = ks.spike_clusters(ismember(ks.spike_clusters,ks.clusters_good));
            temp_spike_times = ks.spike_times(ismember(ks.spike_clusters,ks.clusters_good)) - add_onset_LF/(ks.raw_dataset.fsLF/5)*ks.fsAP - params.drop_buffer_start*ks.fsAP; % use the LF data that has info about extra recording time at beginning of session
            temp_amplitude = metrics.spike_amplitude(ismember(ks.spike_clusters,ks.clusters_good));
            good_clusters(:,1) = ks.cluster_ids;
            good_clusters(:,2) = ks.cluster_groups;
            good_clusters = good_clusters(good_clusters(:,2)==2,:);
            
            % Correct to drop the starting buffer period
            start_idx = find(temp_spike_times>0,1);
            stop_idx = find(temp_spike_times > ((delete_tail/(ks.raw_dataset.fsLF/5)*ks.fsAP)-(add_onset_LF/(ks.raw_dataset.fsLF/5)*ks.fsAP) - (params.drop_buffer_start*ks.fsAP)),1);

            seg_spike_times = temp_spike_times(start_idx:stop_idx);
            seg_cluster = temp_cluster(start_idx:stop_idx);
            seg_amplitude = temp_amplitude(start_idx:stop_idx);
            good_clusters(:,3) = ismember(good_clusters(:,1),unique(seg_cluster));
            seg_centroid = metrics.cluster_centroid(logical(good_clusters(:,3)),:);
            seg_waveform = metrics.cluster_waveform(logical(good_clusters(:,3)),:);
    
            % 48: segment spike times
            spike_time_prop = prop;
            animal_summary_of_sessions{trial_num,prop} = seg_spike_times;
            prop = prop+1;
            
            % 49: segment cluster labels
            animal_summary_of_sessions{trial_num,prop} = seg_cluster;
            prop = prop+1;
            
            % 50: segment cluster amplitudes
            animal_summary_of_sessions{trial_num,prop} = seg_amplitude;
            prop = prop+1;
            
            % 51: segment cluster centroids
            animal_summary_of_sessions{trial_num,prop} = seg_centroid;
            prop = prop+1;
            
            % 52: segment waveform
            animal_summary_of_sessions{trial_num,prop} = seg_waveform;
            prop = prop+1;
    
            % 53: kilosort onset index
            animal_summary_of_sessions{trial_num,prop} = NaN; prop = prop+1;
    
            % 54: LF onset index
            animal_summary_of_sessions{trial_num,prop} = NaN; prop = prop+1;
    
            % 55: Time descrepency between xPC and NI for the entire session
            animal_summary_of_sessions{trial_num,prop} = NaN; prop = prop+1;
    
        else
            prop = prop + 11;
        end
    
    end
        
    % Session behavior metrics
    
%     for i = 1:height(animal_summary_of_sessions)
%         % 53: psychometric curve for session
%         animal_summary_of_sessions{i,prop} = psychometric_performance; 
%         % 54: dprime
%         animal_summary_of_sessions{i,prop+1} = dprime;
%         % 55: criterion
%         animal_summary_of_sessions{i,prop+2} = criterion;
%     end
else
        animal_summary_of_sessions = cell(0,params.num_of_properties);
end

end