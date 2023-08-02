function [log] = scrapeRawData(root_behavior_data,root_metadata,root_pupil_data,root_whisker_data,root_photometry_data,behavior_destination,...
    metadata_destination,pupil_destination,whisker_destination,photometry_destination)
%SRAPERAWDATA Check all root data folders for new data and QC
%   If data passes QC it will be moved into project folder for downstream
%   analysis.

% root_behavior_data = paths.scrape_raw_data.behavior_data;
% root_metadata = paths.scrape_raw_data.behavior_metadata;
% root_pupil_data = paths.scrape_raw_data.pupil_data;
% root_whisker_data = paths.scrape_raw_data.whisker_data;
% root_photometry_data = paths.scrape_raw_data.photometry_data;
% behavior_destination = paths.raw_behavior_data;
% metadata_destination = paths.behavior_meta_data;
% pupil_destination = paths.raw_pupil_data;
% whisker_destination = paths.raw_whisker_data;
% photometry_destination = paths.raw_photometry_data;

% Check for new behavior data:
behavior_to_check = dir(fullfile(root_behavior_data,"*.mat"));

% Set blank log structure to summarize results
log = strings(length(behavior_to_check)*5,1);
log_count = 1;

% Must pass basic QC
if ~isempty(behavior_to_check)
    for session = 1:length(behavior_to_check)
        file_to_check = behavior_to_check(session,:);
        temp_split = strfind(file_to_check.name,'_');
        session_stem = file_to_check.name(1:temp_split(4)-1);
        if file_to_check.bytes > 33000000
            movefile(fullfile(root_behavior_data,file_to_check.name), behavior_destination);
            log(log_count) = strcat(session_stem,": Sourced behavior data file successfully retrieved.");
            log_count = log_count + 1;
        else
            warning(strcat(session_stem,": Sourced behavior data file does not meet minimum QC. Please investigate."))
            log(log_count) = strcat(session_stem,": Sourced behavior data file does not meet minimum QC. Please investigate.");
            log_count = log_count + 1;
        end
    
        % Now check all other data streams
        % Metadata
        metadata_to_check = dir(fullfile(root_metadata,strcat(session_stem,'*.mat')));
        if ~isempty(metadata_to_check)
            if metadata_to_check.bytes > 100
                movefile(fullfile(root_metadata,metadata_to_check.name), metadata_destination);
                log(log_count) = strcat(session_stem,": Sourced metadata file successfully retrieved.");
                log_count = log_count + 1;
            else
                warning(strcat(session_stem,": Sourced metadata file does not meet minimum QC. Please investigate."))
                log(log_count) = strcat(session_stem,": Sourced metadata file does not meet minimum QC. Please investigate.");
                log_count = log_count + 1;
            end
        else
            warning(strcat(session_stem,": Metadata file does not exist. Please investigate."))
            log(log_count) = strcat(session_stem,": Metadata file does not exist. Please investigate.");
            log_count = log_count + 1;
        end
        % Pupil video
        pupil_to_check = dir(fullfile(root_pupil_data,strcat(session_stem,'*.mp4')));
        if ~isempty(pupil_to_check) && length(pupil_to_check) == 1
            if pupil_to_check.bytes > 410000000 && pupil_to_check.bytes < 500000000
                movefile(fullfile(root_pupil_data,pupil_to_check.name), pupil_destination);
                log(log_count) = strcat(session_stem,": Sourced pupil video successfully retrieved.");
                log_count = log_count + 1;
            elseif pupil_to_check.bytes < 500000000
                movefile(fullfile(root_pupil_data,pupil_to_check.name), pupil_destination);
                log(log_count) = strcat(session_stem,": Sourced pupil video successfully retrieved, but quality on video may have been set too high or ROI too large.");
                log_count = log_count + 1;
            else
                warning(strcat(session_stem,": Sourced pupil video does not meet minimum QC. The video might be shorter than expected. Please move manually if ok."))
                log(log_count) = strcat(session_stem,": Sourced pupil video does not meet minimum QC. The video might be shorter than expected. Please move manually if ok.");
                log_count = log_count + 1;
            end
        else
            warning(strcat(session_stem,": Pupil video does not exist or there are multiples. Please investigate and ensure the files are named correctly."))
            log(log_count) = strcat(session_stem,": Pupil video does not exist or there are multiples. Please investigate and ensure the files are named correctly..");
            log_count = log_count + 1;
        end
        % Whisker video
        whisker_to_check = dir(fullfile(root_whisker_data,strcat(session_stem,'*.mp4')));
        if ~isempty(whisker_to_check) && length(whisker_to_check) == 1
            if whisker_to_check.bytes > 600000000 && whisker_to_check.bytes < 1100000000
                movefile(fullfile(root_whisker_data,whisker_to_check.name), whisker_destination);
                log(log_count) = strcat(session_stem,": Sourced whisker video successfully retrieved.");
                log_count = log_count + 1;
            elseif whisker_to_check.bytes < 1100000000
                movefile(fullfile(root_whisker_data,whisker_to_check.name), whisker_destination);
                log(log_count) = strcat(session_stem,": Sourced whisker video successfully retrieved, but quality on video may have been set too high or ROI too large.");
                log_count = log_count + 1;
            else
                warning(strcat(session_stem,": Sourced whisker video does not meet minimum QC. The video might be shorter than expected. Please move manually if ok."))
                log(log_count) = strcat(session_stem,": Sourced whisker video does not meet minimum QC. The video might be shorter than expected. Please move manually if ok.");
                log_count = log_count + 1;
            end
        else
            warning(strcat(session_stem,": Whisker video does not exist or there are multiples. Please investigate and ensure the files are named correctly."))
            log(log_count) = strcat(session_stem,": Whisker video does not exist or there are multiples. Please investigate and ensure the files are named correctly..");
            log_count = log_count + 1;
        end
        % Photometry data
        photometry_to_check = dir(fullfile(root_photometry_data,strcat(session_stem,'*.csv')));
        if ~isempty(photometry_to_check) && length(photometry_to_check) == 1
            if (photometry_to_check.bytes > 400000000 && photometry_to_check.bytes < 650000000) || (photometry_to_check.bytes > 30000000 && photometry_to_check.bytes < 55000000)
                movefile(fullfile(root_photometry_data,photometry_to_check.name), photometry_destination);
                log(log_count) = strcat(session_stem,": Sourced photometry data successfully retrieved.");
                log_count = log_count + 1;
            else
                warning(strcat(session_stem,": Sourced photometry data does not meet minimum QC. Please move manually if ok."))
                log(log_count) = strcat(session_stem,": Sourced photometry data does not meet minimum QC. Please move manually if ok.");
                log_count = log_count + 1;
            end
        else
            warning(strcat(session_stem,": Photometry data does not exist. Please investigate and ensure the files are named correctly."))
            log(log_count) = strcat(session_stem,": Photometry data does not exist. Please investigate and ensure the files are named correctly..");
            log_count = log_count + 1;
        end
    end
else
    log(log_count) = "There is currently no root data that needs to be transferred to the project.";
end