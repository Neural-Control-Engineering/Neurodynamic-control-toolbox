function [videos_for_DLC] = fetchPupil2Extract(raw_pupil_video_path,reset_DLC,update_DLC)
%processPupilData Return list of videos to extract
%   Check pupil_extraction_log for list of videos that still need to
%   undergo DLC extraction
% @written by CS 2022

if reset_DLC==true
    % Reset the analysis log
    load(fullfile(raw_pupil_video_path,"pupil_extraction_log.mat"));
    pupil_extraction_log(:,:) = [];
    save(fullfile(raw_pupil_video_path,"pupil_extraction_log.mat"), 'pupil_extraction_log');

    % Delete the previously generated DLC files
    DLC_list = dir(fullfile(raw_pupil_video_path,"DLC_extracted_data"));
    DLC_list = DLC_list(contains({DLC_list.name},"DLC"));
    to_delete = {DLC_list.name};

    for i = 1:length(DLC_list)
        file = fullfile(raw_pupil_video_path,'DLC_extracted_data',string(to_delete(i)));
        delete(file);
    end
    
    if isfolder(fullfile(raw_pupil_video_path,"DLC_extracted_data","plot-poses"))
        rmdir(fullfile(raw_pupil_video_path,"DLC_extracted_data","plot-poses"),'s')
    end
end

if update_DLC==true
    % Reject extractions with average confidence below 93% and try with a
    % (preferrably) upgraded network.
    load(fullfile(raw_pupil_video_path,"pupil_extraction_log.mat"),'pupil_extraction_log');
    pupil_extraction_log(:,2) = pupil_extraction_log(:,3);
    save(fullfile(raw_pupil_video_path,"pupil_extraction_log.mat"), 'pupil_extraction_log');

    % Delete the previously generated DLC files
    DLC_list = dir(fullfile(raw_pupil_video_path,"DLC_extracted_data"));
    DLC_list = DLC_list(contains({DLC_list.name},"DLC"));
    to_delete = {DLC_list.name};

    for i = 1:length(DLC_list)
        file = fullfile(raw_pupil_video_path,'DLC_extracted_data',string(to_delete(i)));
        display(strcat("Deleting ", file));
        delete(file);
    end    
end

% List all videos in raw data folder
video_list = dir(raw_pupil_video_path);
video_list = video_list(contains({video_list.name},".mp4"));
filenames = {video_list.name}';

%
load(fullfile(raw_pupil_video_path,"pupil_extraction_log.mat"));

idx_vid_to_add =  ~ismember(filenames,pupil_extraction_log.Name);

files_to_add = filenames(idx_vid_to_add);

for i = 1:length(files_to_add)
    % Add new videos to analysis list and set analyzed to false
    table_size = length(pupil_extraction_log.Name);
    pupil_extraction_log(table_size + 1,:) = {files_to_add(i), false, false, 0};
end

% Return videos that need to be extracted
videos_for_DLC = pupil_extraction_log.Name(pupil_extraction_log.DLC_processed == false);

save(fullfile(raw_pupil_video_path,"pupil_extraction_log.mat"), 'pupil_extraction_log');

end