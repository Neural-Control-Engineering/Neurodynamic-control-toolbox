function genHmmGlmData(data, outfile, version, shuffle, seed)
% function saves input data in a format compatible with glm-hmm.
% user can specify the type of data to save with *version*.
% data is saved to *outfile*.
% Craig Kelley, NEC Lab, 8/21/23
    
    if exist('seed', 'var')
        rng(seed)
    end
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
            metrics = getSpontaneousMetrics(tmp, false);
            stim_strengths = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            preprocessed_input{i,1} = [metrics, stim_strengths];
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo);
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number;
        end
    elseif strcmp(version, 'spontaneous_mpfc_s1_pupil')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            metrics = getSpontaneousMetrics(tmp, false);
            stim_strengths = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            if shuffle
                metrics = [metrics(randperm(size(metrics,1)),1), metrics(randperm(size(metrics,1)),3),metrics(randperm(size(metrics,1)),5)];
                preprocessed_input{i,1} = [metrics, stim_strengths];
            else
                metrics = [metrics(:,1), metrics(:,3),metrics(:,5)];
                preprocessed_input{i,1} = [metrics, stim_strengths];
            end
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo);
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number;
        end
    elseif strcmp(version, 'spontaneous_mpfc_s1_pupil_normalized')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            metrics = getSpontaneousMetrics(tmp, true);
            stim_strengths = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            if shuffle
                metrics = [metrics(randperm(size(metrics,1)),1), ...
                    metrics(randperm(size(metrics,1)),3), ...
                    metrics(randperm(size(metrics,1)),5)];
                preprocessed_input{i,1} = [metrics, stim_strengths];
            else
                metrics = [metrics(:,1), metrics(:,3),metrics(:,5)];
                preprocessed_input{i,1} = [metrics, stim_strengths];
            end
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo);
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number;
        end
    elseif strcmp(version, 'spontaneous_mpfc_stim')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            metrics = getSpontaneousMetrics(tmp, true);
            stim_strengths = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            if shuffle
                metrics = metrics(randperm(size(metrics,1)),3);
                preprocessed_input{i,1} = [metrics, stim_strengths];
            else
                metrics = metrics(:,3);
                preprocessed_input{i,1} = [metrics, stim_strengths];
            end
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo);
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number;
        end
    elseif strcmp(version, 'spontaneous_s1_stim')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            metrics = getSpontaneousMetrics(tmp, true);
            stim_strengths = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            if shuffle
                metrics = metrics(randperm(size(metrics,1)),5);
                preprocessed_input{i,1} = [metrics, stim_strengths];
            else
                metrics = metrics(:,5);
                preprocessed_input{i,1} = [metrics, stim_strengths];
            end
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo);
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number;
        end
    elseif strcmp(version, 'spontaneous_pupil_stim')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            metrics = getSpontaneousMetrics(tmp, true);
            stim_strengths = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            if shuffle
                metrics = metrics(randperm(size(metrics,1)),1);
                preprocessed_input{i,1} = [metrics, stim_strengths];
            else
                metrics = metrics(:,1);
                preprocessed_input{i,1} = [metrics, stim_strengths];
            end
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo);
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number;
        end
    elseif strcmp(version, 'spontaneous_mpfc_s1_pupil_drop_stim')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            metrics = getSpontaneousMetrics(tmp, false);
            if shuffle
                metrics = [metrics(randperm(size(metrics,1)),1), ... 
                    metrics(randperm(size(metrics,1)),3), ...
                    metrics(randperm(size(metrics,1)),5)];
                preprocessed_input{i,1} = [metrics];
            else
                metrics = [metrics(:,1), metrics(:,3),metrics(:,5)];
                preprocessed_input{i,1} = [metrics];
            end
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo);
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number;
        end
    elseif strcmp(version, 'last_trial_behavior_with_bias')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            stim_strengths = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            responses = tmp.go_nogo;
            responses = responses(1:end-1);
            reward_states = cellfun(@getRewardState, tmp.categorical_outcome);
            reward_states = reward_states(1:end-1);
            strength = stim_strengths(2:end);
            if shuffle
                preprocessed_input{i,1} = [strength(randperm(length(strength))), ...
                    responses(randperm(length(responses))), ...
                    reward_states(randperm(length(reward_states))), ... 
                    ones(length(responses),1)];
            else
                preprocessed_input{i,1} = [strength, responses, reward_states, ones(length(responses),1)];
            end
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo(2:end));
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number(2:end);
        end
    elseif strcmp(version, 'last_trial_behavior_no_bias')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            stim_strengths = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            responses = tmp.go_nogo;
            responses = responses(1:end-1);
            reward_states = cellfun(@getRewardState, tmp.categorical_outcome);
            reward_states = reward_states(1:end-1);
            strength = stim_strengths(2:end);
            if shuffle
                preprocessed_input{i,1} = [strength(randperm(length(strength))), ...
                    responses(randperm(length(responses))), ...
                    reward_states(randperm(length(reward_states))), ... 
                    ones(length(responses),1)];
            else
                preprocessed_input{i,1} = [strength, responses, reward_states];
            end
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo(2:end));
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number(2:end);
        end
    elseif strcmp(version, 'last_trial_behavior_drop_stim_with_bias')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            responses = tmp.go_nogo;
            responses = responses(1:end-1);
            reward_states = cellfun(@getRewardState, tmp.categorical_outcome);
            reward_states = reward_states(1:end-1);
            if shuffle
                preprocessed_input{i,1} = [responses(randperm(length(responses))), ...
                    reward_states(randperm(length(reward_states))), ...
                    ones(length(responses),1)];
            else
                preprocessed_input{i,1} = [responses, reward_states, ones(length(responses),1)];
            end
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo(2:end));
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number(2:end);
        end
    elseif strcmp(version, 'last_trial_behavior_drop_stim_no_bias')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            responses = tmp.go_nogo;
            responses = responses(1:end-1);
            reward_states = cellfun(@getRewardState, tmp.categorical_outcome);
            reward_states = reward_states(1:end-1);
            if shuffle
                preprocessed_input{i,1} = [responses(randperm(length(responses))), ...
                    reward_states(randperm(length(reward_states)))];
            else
                preprocessed_input{i,1} = [responses, reward_states];
            end
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo(2:end));
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number(2:end);
        end
    elseif strcmp(version, 'behavior_pupil_mpfc_s1_combo')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            stim_strengths = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            responses = tmp.go_nogo;
            responses = responses(1:end-1);
            reward_states = cellfun(@getRewardState, tmp.categorical_outcome);
            reward_states = reward_states(1:end-1);
            strength = stim_strengths(2:end);
            metrics = getSpontaneousMetrics(tmp, false);
            metrics = [metrics(2:end,1), metrics(2:end,3),metrics(2:end,5)];
            if shuffle
                preprocessed_input{i,1} = [strength(randperm(length(strength))), ... 
                    responses(randperm(length(responses))), ... 
                    reward_states(randperm(length(reward_states))), ... 
                    metrics(randperm(size(metrics,1)),1), ... 
                    metrics(randperm(size(metrics,1)),2), ... 
                    metrics(randperm(size(metrics,1)),3)];
            else
                preprocessed_input{i,1} = [strength, responses, reward_states, metrics];
            end
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo(2:end));
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number(2:end);
        end
    elseif strcmp(version, 'behavior_mpfc_s1_combo')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            stim_strengths = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            responses = tmp.go_nogo;
            responses = responses(1:end-1);
            reward_states = cellfun(@getRewardState, tmp.categorical_outcome);
            reward_states = reward_states(1:end-1);
            strength = stim_strengths(2:end);
            metrics = getSpontaneousMetrics(tmp, false);
            metrics = [metrics(2:end,3), metrics(2:end,5)];
            if shuffle
                preprocessed_input{i,1} = [strength(randperm(length(strength))), ... 
                    responses(randperm(length(responses))), ... 
                    reward_states(randperm(length(reward_states))), ... 
                    metrics(randperm(size(metrics,1)),1), ... 
                    metrics(randperm(size(metrics,1)),2), ... 
                    metrics(randperm(size(metrics,1)),3)];
            else
                preprocessed_input{i,1} = [strength, responses, reward_states, metrics];
            end
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo(2:end));
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number(2:end);
        end
    elseif strcmp(version, 'behavior_pupil_mpfc_combo')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            stim_strengths = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            responses = tmp.go_nogo;
            responses = responses(1:end-1);
            reward_states = cellfun(@getRewardState, tmp.categorical_outcome);
            reward_states = reward_states(1:end-1);
            strength = stim_strengths(2:end);
            metrics = getSpontaneousMetrics(tmp, false);
            metrics = [metrics(2:end,1), metrics(2:end,3)];
            if shuffle
                preprocessed_input{i,1} = [strength(randperm(length(strength))), ... 
                    responses(randperm(length(responses))), ... 
                    reward_states(randperm(length(reward_states))), ...  
                    metrics(randperm(size(metrics,1)),1), ... 
                    metrics(randperm(size(metrics,1)),2)];
            else
                preprocessed_input{i,1} = [strength, responses, reward_states, metrics];
            end
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo(2:end));
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number(2:end);
        end
    elseif strcmp(version, 'behavior_pupil_s1_combo')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            stim_strengths = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            responses = tmp.go_nogo;
            responses = responses(1:end-1);
            reward_states = cellfun(@getRewardState, tmp.categorical_outcome);
            reward_states = reward_states(1:end-1);
            strength = stim_strengths(2:end);
            metrics = getSpontaneousMetrics(tmp, false);
            metrics = [metrics(2:end,1), metrics(2:end,5)];
            if shuffle
                preprocessed_input{i,1} = [strength(randperm(length(strength))), ... 
                    responses(randperm(length(responses))), ... 
                    reward_states(randperm(length(reward_states))), ... 
                    metrics(randperm(size(metrics,1)),1), ... 
                    metrics(randperm(size(metrics,1)),2)];
            else
                preprocessed_input{i,1} = [strength, responses, reward_states, metrics];
            end
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo(2:end));
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number(2:end);
        end
    elseif strcmp(version, 'behavior_mpfc_combo')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            stim_strengths = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            responses = tmp.go_nogo;
            responses = responses(1:end-1);
            reward_states = cellfun(@getRewardState, tmp.categorical_outcome);
            reward_states = reward_states(1:end-1);
            strength = stim_strengths(2:end);
            metrics = getSpontaneousMetrics(tmp, false);
            metrics = metrics(2:end,3);
            if shuffle
                preprocessed_input{i,1} = [strength(randperm(length(strength))), ... 
                    responses(randperm(length(responses))), ... 
                    reward_states(randperm(length(reward_states))), ... 
                    metrics(randperm(length(metrics)))];
            else
                preprocessed_input{i,1} = [strength, responses, reward_states, metrics];
            end
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo(2:end));
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number(2:end);
        end
    elseif strcmp(version, 'behavior_s1_combo')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            stim_strengths = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            responses = tmp.go_nogo;
            responses = responses(1:end-1);
            reward_states = cellfun(@getRewardState, tmp.categorical_outcome);
            reward_states = reward_states(1:end-1);
            strength = stim_strengths(2:end);
            metrics = getSpontaneousMetrics(tmp, false);
            metrics = metrics(2:end,5);
            if shuffle
                preprocessed_input{i,1} = [strength(randperm(length(strength))), ... 
                responses(randperm(length(responses))), ... 
                reward_states(randperm(length(reward_states))), ... 
                metrics(randperm(length(metrics)))];
            else
                preprocessed_input{i,1} = [strength, responses, reward_states, metrics];
            end
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo(2:end));
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number(2:end);
        end
    elseif strcmp(version, 'behavior_pupil_combo')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            stim_strengths = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            responses = tmp.go_nogo;
            
            responses = responses(1:end-1);
            reward_states = cellfun(@getRewardState, tmp.categorical_outcome);
            reward_states = reward_states(1:end-1);
            strength = stim_strengths(2:end);
            metrics = getSpontaneousMetrics(tmp, false);
            metrics = metrics(2:end,1);
            if shuffle
                preprocessed_input{i,1} = [strength(randperm(length(strength))), ... 
                responses(randperm(length(responses))), ... 
                reward_states(randperm(length(reward_states))), ... 
                metrics(randperm(length(metrics)))];
            else
                preprocessed_input{i,1} = [strength, responses, reward_states, metrics];
            end
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo(2:end));
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number(2:end);
        end
    elseif strcmp(version, 'time_series')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            strength = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            responses = tmp.go_nogo;
            [mpfc, s1, pupil] = getSpontaneousTimeSeries(tmp, [-0.5, 0], 'stimulus_time');
            if shuffle
                preprocessed_input{i,1} = [strength(randperm(length(strength))), ... 
                responses(randperm(length(responses))), ... 
                reward_states(randperm(length(reward_states))), ... 
                metrics(randperm(length(metrics)))];
            else
                preprocessed_input{i,1} = [strength, responses, reward_states, metrics];
            end
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo(2:end));
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number(2:end);
        end
    elseif strcmp(version, 'dynamic_state')
        for i = 1:length(sessions)
            tmp = filterTrials(data, 'session_id', sessions{i});
            strength = tmp.stimulus_strength ./ max(tmp.stimulus_strength);
            responses = tmp.go_nogo;
            metrics = getDynamicState(tmp, [-0.5, 0], 'stimulus_time');
            if shuffle
                preprocessed_input{i,1} = [strength(randperm(length(strength))), ... 
                    responses(randperm(length(responses))), ... 
                    metrics(randperm(size(metrics,1)),1), ... 
                    metrics(randperm(size(metrics,1)),2), ... 
                    metrics(randperm(size(metrics,1)),3), ...
                    metrics(randperm(size(metrics,1)),4), ... 
                    metrics(randperm(size(metrics,1)),5), ... 
                    metrics(randperm(size(metrics,1)),6), ...
                    metrics(randperm(size(metrics,1)),7), ... 
                    metrics(randperm(size(metrics,1)),8), ... 
                    metrics(randperm(size(metrics,1)),9)];
            else
                preprocessed_input{i,1} = [strength, responses, metrics];
            end
            preprocessed_session{i,1} = sessions{i};
            preprocessed_label{i,1} = num2cell(tmp.go_nogo);
            preprocessed_trial_number{i,1} = tmp.sequential_trial_number; 
        end
        keyboard
    end

    save(outfile,"preprocessed_input","preprocessed_label","preprocessed_session","preprocessed_trial_number")

end

function out = getRewardState(outcome)
    if strcmp(outcome, 'CR') || strcmp(outcome, 'Hit')
        out = 1;
    else
        out = 0;
    end
end


function [ch1, ch2, pupil] = getSpontaneousTimeSeries(data, tbounds, alignTo)
    
    ne_fs = max(getFs(data, 'photometry_ch1'));
    p_fs = max(getFs(data, 'pupil_area'));
    ne_time = linspace(tbounds(1), tbounds(2), ne_fs * diff(tbounds));
    pupil_time = linspace(tbounds(1), tbounds(2), p_fs * diff(tbounds));
    ch1 = zeros(size(data,1), length(ne_time));
    ch2 = ch1;
    pupil = zeros(size(data,1), length(pupil_time));

    if strcmp(alignTo, 'stimulus_time')
        starts = data.stimulus_time;
    elseif strcmp(alignTo, 'response_time')
        starts = data.stimulus_time + data.response_time;
    end

    for trial = 1:size(data,1)
        t = data.photometry_ch1{trial,1}(:,1) - starts(trial);
        y1 = data.photometry_ch1{trial,1}(:,2);
        y2 = data.photometry_ch2{trial,1}(:,2);
        pt = data.pupil_area{trial,1}(:,1) - starts(trial);
        p = data.pupil_area{trial,1}(:,2);
        y1 = y1(t > tbounds(1) & t < tbounds(2));
        y2 = y2(t > tbounds(1) & t < tbounds(2));
        t = t(t > tbounds(1) & t < tbounds(2));
        p = p(pt > tbounds(1) & pt < tbounds(2));
        pt = pt(pt > tbounds(1) & pt < tboudns(2));
        try
            ch1(trial,:) = y1;
            ch2(trial,:) = y2;
        catch
            ch1(trial,:) = interp1(t, y1,  ne_time);
            ch2(trial,:) = interp1(t, y2, ne_time);
        end
        try
            pupil(trial,:) = p;
        catch
            pupil(trial,:) = interp1(pt, p, pupil_time);
        end
    end
end


function out = getDynamicState(data, tbounds, alignTo)
    out = [];
    % determine alignments 
    if strcmp(alignTo, 'stimulus_time')
        starts = data.stimulus_time;
    elseif strcmp(alignTo, 'response_time')
        starts = data.stimulus_time + data.response_time;
    end
    for trial = 1:size(data,1)
        t = data.photometry_ch1{trial,1}(:,1) - starts(trial);
        y1 = data.photometry_ch1{trial,1}(:,2);
        y2 = data.photometry_ch2{trial,1}(:,2);
        pt = data.pupil_area{trial,1}(:,1) - starts(trial);
        p = data.pupil_area{trial,1}(:,2);
        y1 = y1(t > tbounds(1) & t < tbounds(2));
        y2 = y2(t > tbounds(1) & t < tbounds(2));
        p = p(pt > tbounds(1) & pt < tbounds(2));
        out = [out; data.pupil_base_before_stimulus(trial), ...
            nanmean(diff(p)), ...
            nanmean(diff(diff(p))), ...
            data.photo_base_before_stim_ch1{trial}, ...
            nanmean(diff(y1)), ...
            nanmean(diff(diff(y1))), ...
            data.photo_base_before_stim_ch2{trial}, ...
            nanmean(diff(y2)), ...
            nanmean(diff(diff(y2)))];
    end
end

function out = getSpontaneousMetrics(data, normalize)
    out = zeros(size(data,1), 6);
    for trial = 1:size(data,1)
        if normalize
            try
                out(trial, :) = [data.pupil_base_before_stimulus{trial} / data.pupil_95pctl{trial}, ...
                    data.pupil_base_before_onset{trial} / data.pupil_95pctl{trial}, ...
                    data.photo_base_before_stim_ch1{trial} / data.photometry_95pctl_ch1{trial}, ...
                    data.photo_base_before_onset_ch1{trial} / data.photometry_95pctl_ch1{trial}, ...
                    data.photo_base_before_stim_ch2{trial} / data.photometry_95pctl_ch2{trial}, ...
                    data.photo_base_before_onset_ch2{trial} / data.photometry_95pctl_ch2{trial}];
            catch
                out(trial, :) = [data.pupil_base_before_stimulus(trial), ...
                    data.pupil_base_before_onset{trial}, ...
                    data.photo_base_before_stim_ch1{trial}, ...
                    data.photo_base_before_onset_ch1{trial}, ...
                    data.photo_base_before_stim_ch2{trial}, ...
                    data.photo_base_before_onset_ch2{trial}];
            end
        else
            try
                out(trial, :) = [data.pupil_base_before_stimulus{trial} , ...
                    data.pupil_base_before_onset{trial}, ...
                    data.photo_base_before_stim_ch1{trial}, ...
                    data.photo_base_before_onset_ch1{trial}, ...
                    data.photo_base_before_stim_ch2{trial}, ...
                    data.photo_base_before_onset_ch2{trial}];
            catch
                out(trial, :) = [data.pupil_base_before_stimulus(trial), ...
                    data.pupil_base_before_onset{trial}, ...
                    data.photo_base_before_stim_ch1{trial}, ...
                    data.photo_base_before_onset_ch1{trial}, ...
                    data.photo_base_before_stim_ch2{trial}, ...
                    data.photo_base_before_onset_ch2{trial}];
            end
        end
    end
end

function out = getPhotometryMetrics(data, alignTo, tbounds)
    out = zeros(size(data,1), 4);
    % determine alignments 
    if strcmp(alignTo, 'stimulus_time')
        starts = data.stimulus_time;
    elseif strcmp(alignTo, 'response_time')
        starts = data.stimulus_time + data.response_time;
    end
    % get peak and time to peak for each channel
    for trial = 1:size(data,1)
        t = data.photometry_ch1{trial,1}(:,1) - starts(trial);
        y1 = data.photometry_ch1{trial,1}(:,2);
        y2 = data.photometry_ch2{trial,1}(:,2);
        y1 = y1(t > tbounds(1) & t < tbounds(2));
        y2 = y2(t > tbounds(1) & t < tbounds(2));
        t = t(t > tbounds(1) & t < tbounds(2));
        [p1, ind1] = max(y1);
        [p2, ind2] = max(y2);
        out(trial, :) = [p1, t(ind1), p2, t(ind2)];
    end
end
