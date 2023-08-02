function [log] = logPupilExtraction(raw_pupil_video_path,file_name)
%processPupilData Return list of videos to extract
%   Log pupil videos that have been DLC extracted
% @written by CS 2022

%
load(fullfile(raw_pupil_video_path,"pupil_extraction_log.mat"));
pupil_extraction_log.DLC_processed(strcmp(pupil_extraction_log.Name,file_name)) = true;

save(fullfile(raw_pupil_video_path,"pupil_extraction_log.mat"), 'pupil_extraction_log');

log = strcat("DLC pupil extraction of ",file_name," successfully logged");

end