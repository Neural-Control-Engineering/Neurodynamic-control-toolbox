function genHmmGlmData(data, outfile, version)
% function saves input data in a format compatible with glm-hmm.
% user can specify the type of data to save with *version*.
% data is saved to *outfile*.
% Craig Kelley, NEC Lab, 8/21/23
    
    % trial_onset_inds = find(cellfun(@isempty, data.ISI));
    % trial_inds = find(~cellfun(@isempty, data.ISI));

    sessions = unique(data.session_id);
    
    preprocessed_input = cell(length(sessions),1);
    preprocessed_label = cell(length(sessions),1);
    preprocessed_session = cell(length(sessions),1);
    preprocessed_trial_number = cell(length(sessions),1);

    if strcmp(version, 'last_trial_photo')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            photo_metrics = getPhotometryMetrics(tmp, 'stimulus_time', [0,1]);
            stim_strengths = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            preprocessed_input{i,1} = [photo_metrics(1:end-1,:), stim_strengths(2:end)];
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo(2:end));
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number(2:end);
        end
    elseif strcmp(version, 'spon_photo_pupil')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            metrics = getSpontaneousMetrics(tmp, 'stimulus_time', [-0.5,0]);
            stim_strengths = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            preprocessed_input{i,1} = [metrics, stim_strengths];
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo);
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number;
        end
    elseif strcmp(version, 'spon_photo_pupil_v2')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            metrics = getSpontaneousMetrics(tmp, 'stimulus_time', [-0.5,0]);
            metrics = [metrics(:,1), metrics(:,3),metrics(:,5)];
            stim_strengths = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            preprocessed_input{i,1} = [metrics, stim_strengths];
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo);
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number;
        end
    end

    save(outfile,"preprocessed_input","preprocessed_label","preprocessed_session","preprocessed_trial_number")

end



