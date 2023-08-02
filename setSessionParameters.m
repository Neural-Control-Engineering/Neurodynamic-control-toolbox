function [video_details] = setSessionParameters(session_behavior_data,params,session_meta_data)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

if ~isempty(session_meta_data)

    pupil_fs = session_meta_data.pupil.pupil_fs;
    whisker_fs = session_meta_data.whisker.whisker_fs;

    % Find total session duration in seconds
    session_duration = session_behavior_data.Data.Licks.data(end,2);

    % Calculate how many frames of each video should have been recorded in the
    % session
    pupil_frame_count = session_duration * pupil_fs;
    whisker_frame_count = session_duration * whisker_fs;

    % Define a time period for which to ignore at the start/stop of an
    % experiment
    pupil_frame_start = params.drop_buffer_start * pupil_fs;
    pupil_frame_end = pupil_frame_count - (params.drop_buffer_end * pupil_fs);

    whisker_frame_start = params.drop_buffer_start * whisker_fs;
    whisker_frame_end = whisker_frame_count - (params.drop_buffer_end * whisker_fs);

    video_details.pupil(1,1) = pupil_frame_start;
    video_details.pupil(1,2) = pupil_frame_end;
    video_details.pupil(1,3) = pupil_frame_count;
    video_details.whisker(1,1) = whisker_frame_start;
    video_details.whisker(1,2) = whisker_frame_end;
    video_details.whisker(1,3) = whisker_frame_count;
else
    video_details = [];
    display("Please add a metadata file for this session!");
end