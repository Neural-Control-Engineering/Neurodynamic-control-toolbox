function genHmmGlmData(data, outfile)
    
    trial_onset_inds = find(cellfun(@isempty, data.ISI));
    trial_inds = find(~cellfun(@isempty, data.ISI));

    photo_metrics = getPhotometryMetrics(data, 'stimulus_time', [0,1]);
    
    preprocessed_input = cell(length(trial_inds)-2*length(trial_onset_inds),1);
    preprocessed_label = cell(length(trial_inds)-2*length(trial_onset_inds),1);
    preprocessed_session = cell(length(trial_inds)-2*length(trial_onset_inds),1);
    preprocessed_trial_number = cell(length(trial_inds)-2*length(trial_onset_inds),1);

    ind = 1;
    count = 1;
    while ind <= size(data,1)
        if any(trial_onset_inds == ind)
            ind = ind + 2;
        end
        preprocessed_input{count} = photo_metrics(ind-1,:);
        preprocessed_session{count} = data.session_id{ind};
        preprocessed_label{count} = data.go_nogo(ind);
        preprocessed_trial_number{count} = data.sequential_trial_number(ind);
        ind = ind + 1;
        count = count + 1;
    end

    save(outfile,"preprocessed_input","preprocessed_label","preprocessed_session","preprocessed_trial_number")

end



