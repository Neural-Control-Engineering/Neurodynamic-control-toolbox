function [log] = logWhiskerExtraction(raw_whisker_video_path,file_name)
%processPupilData Return list of videos to extract
%   Log pupil videos that have been DLC extracted
% @written by CS 2022

%
load(fullfile(raw_whisker_video_path,"whisker_extraction_log.mat"));
whisker_extraction_log.DLC_processed(strcmp(whisker_extraction_log.Name,file_name)) = true;

save(fullfile(raw_whisker_video_path,"whisker_extraction_log.mat"), 'whisker_extraction_log');

log = strcat("DLC whisker extraction of ",file_name," successfully logged");

end