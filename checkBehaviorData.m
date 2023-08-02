function [psychometric_performance, behavior_data] = checkBehaviorData(paths,session_list,params)
%CHECKBEHAVIORDATA Output psychometric curve and dprime
%   To be used to check performance daily or across multiple sessions
if length(session_list) == 1
    % Load corresponding processed behavior data structure
    load(fullfile(paths.processed_behavior_data,session_list));

    % Create a vector with animal response binary within the window of
    % opportunity after a stimulus was delivered

    response = zeros(length(behavior_data.stim_strength),1);

    for i = 1:length(behavior_data.stim_times)
        if ~isempty(behavior_data.lick_times(behavior_data.lick_times > behavior_data.stim_times(i) & behavior_data.lick_times < behavior_data.stim_times(i) + params.response_window,:))
            response(i) = 1;
        end
    end

    % Pass to psychometric calculating function
    [psychometric_performance] = calculatePsychometricCurves(behavior_data.stim_strength,response,behavior_data.training_phase,behavior_data.session_stimuli);

    plot_psychometric_curves(psychometric_performance, pupil_framerate*(params.before_event+params.after_event));
else
    % iterate through all dates
    full_name = char(session_list(1));
    hyf_idx = strfind(full_name, '-');
    animal_name = full_name(1:hyf_idx(1)-1);
    num_seshs = length(session_list);
    performances = zeros(2,num_seshs);
    for numsesh = 1:num_seshs
        load(fullfile(paths.processed_behavior_data,session_list(numsesh)));
    
        response = zeros(length(behavior_data.stim_strength),1);
    
        for i = 1:length(behavior_data.stim_times)
            if ~isempty(behavior_data.lick_times(behavior_data.lick_times > behavior_data.stim_times(i) & behavior_data.lick_times < behavior_data.stim_times(i) + params.response_window,:))
                response(i) = 1;
            end
        end
    
        % Pass to psychometric calculating function
        [psychometric_performance] = calculatePsychometricCurves(behavior_data.stim_strength,response,behavior_data.training_phase,behavior_data.session_stimuli);
        performances(:, numsesh) = psychometric_performance(:, 1);
    end
    %create average perfomances for selected trials
    psych_perf = [mean(performances, 2), psychometric_performance(:,2)];
    plot_psychometric_curves(psych_perf, strcat("Averaged Psychometric Curve for ",animal_name));
end
 
end