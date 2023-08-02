function [training_phase, paradigm, behavior_data] = fetch_behavior(session_behavior_data,params)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
start_buffer = params.drop_buffer_start;
end_buffer = params.drop_buffer_end;

paradigm = session_behavior_data.Data.Apps;

if contains(paradigm,'Phase_0')
    training_phase = "Phase 0";
    behavior_data = fetch_phase_0_behavior(session_behavior_data,start_buffer,end_buffer);
elseif contains(paradigm,'Phase_II_Early_Late_10ms1s')
    training_phase = "Phase II with optogenetics";
    behavior_data = fetch_phase_II_behavior_optogenetic(session_behavior_data,start_buffer,end_buffer);
elseif contains(paradigm,'Phase_I_')
    training_phase = "Phase I";
    behavior_data = fetch_phase_I_behavior(session_behavior_data,start_buffer,end_buffer);
elseif contains(paradigm,'Phase_II_')
    training_phase = "Phase II";
    behavior_data = fetch_phase_II_behavior(session_behavior_data,start_buffer,end_buffer);
elseif contains(paradigm,'Phase_III_')
    training_phase = "Phase III";
    behavior_data = fetch_phase_III_behavior(session_behavior_data,start_buffer,end_buffer);
elseif contains(paradigm,'Phase0_With_Stim')
    training_phase = "Phase 0 with stimulation";
    behavior_data = fetch_phase_0_w_stim_behavior(session_behavior_data,start_buffer,end_buffer);
elseif contains(paradigm,"SSD_Only_Stim")
    training_phase = "Phase III";
    behavior_data = fetch_phase_III_behavior(session_behavior_data,start_buffer,end_buffer);
elseif contains(paradigm,"NTEX_No_Behavior")
    training_phase = "Neural stimulation only";
    behavior_data = fetch_NTEX_No_behavior(session_behavior_data,start_buffer,end_buffer);
else
    training_phase = "Other";
    behavior_data = fetch_phase_II_behavior(session_behavior_data,start_buffer,end_buffer);
end


 