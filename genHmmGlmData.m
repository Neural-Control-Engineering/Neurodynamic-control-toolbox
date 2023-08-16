function genHmmGlmData(data, outfile)
    
    % trial_onset_inds = find(cellfun(@isempty, data.ISI));
    % trial_inds = find(~cellfun(@isempty, data.ISI));

    sessions = unique(data.session_id);
    
    preprocessed_input = cell(length(sessions),1);
    preprocessed_label = cell(length(sessions),1);
    preprocessed_session = cell(length(sessions),1);
    preprocessed_trial_number = cell(length(sessions),1);

    for i = 1:length(sessions)
        tmp = filterTrials(data, 'session_id', sessions{i});
        photo_metrics = getPhotometryMetrics(tmp, 'stimulus_time', [0,1]);
        preprocessed_input{i,1} = photo_metrics(1:end-1,:);
        preprocessed_session{i,1} = sessions{i};
        preprocessed_label{i,1} = tmp.go_nogo(2:end);
        preprocessed_trial_number{i,1} = tmp.sequential_trial_number(2:end);
    end

    % ind = 1;
    % count = 1;
    % while ind <= size(data,1)
    %     if any(trial_onset_inds == ind)
    %         ind = ind + 2;
    %     end
    %     preprocessed_input{count} = photo_metrics(ind-1,:);
    %     preprocessed_session{count} = data.session_id{ind};
    %     preprocessed_label{count} = data.go_nogo(ind);
    %     preprocessed_trial_number{count} = data.sequential_trial_number(ind);
    %     ind = ind + 1;
    %     count = count + 1;
    % end

    save(outfile,"preprocessed_input","preprocessed_label","preprocessed_session","preprocessed_trial_number")

end



