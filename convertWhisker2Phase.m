function [log] = convertWhisker2Phase(paths,reset_whisker2PhaseConversion)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if reset_whisker2PhaseConversion==true
    % Reset the analysis log
    load(fullfile(paths.raw_whisker_data,"whisker_extraction_log.mat"));
    whisker_extraction_log.Converted2Phase(:) = false(length(whisker_extraction_log.Converted2Phase),1);
    save(fullfile(paths.raw_whisker_data,"whisker_extraction_log.mat"), 'whisker_extraction_log');
end

processed_whisker_data_path = paths.processed_whisker_data;
DLC_path = fullfile(paths.raw_whisker_data,'DLC_extracted_data');

load(fullfile(paths.raw_whisker_data,"whisker_extraction_log.mat"),"whisker_extraction_log");
videos_to_convert = whisker_extraction_log.Name(whisker_extraction_log.Converted2Phase == false & whisker_extraction_log.DLC_processed == true);

log = strings(length(videos_to_convert),1);

if ~isempty(videos_to_convert)
    for i = 1:length(videos_to_convert)
        % Grab file for conversion
        file = dir(fullfile(DLC_path,strcat(videos_to_convert{i}(1:end-4),'*filtered.csv*')));
        
        if ~isempty(file)

            % Load behabior data to reference trims
            temp = dir(fullfile(paths.processed_behavior_data,strcat(videos_to_convert{i}(1:end-4),'*')));
            if ~isempty(temp)
                behavior_data = load(fullfile(temp.folder,temp.name));
            end

            % Call to whisker conversion script
            [analyzed_whisker] = W_Pos_Ang(fullfile(file.folder,file.name));

            % Trim start/stop times
            analyzed_whisker = analyzed_whisker(analyzed_whisker(:,1) >  behavior_data.behavior_data.video_details.whisker(1)-1 & analyzed_whisker(:,1) <  behavior_data.behavior_data.video_details.whisker(2),:);

            % Convert from frame to time
            analyzed_whisker(:,1) = analyzed_whisker(:,1)/behavior_data.behavior_data.meta_data.whisker.whisker_fs;
            analyzed_whisker(:,1) = analyzed_whisker(:,1) - analyzed_whisker(1,1);
        
            analyzed_whisker(:,2) = filloutliers(analyzed_whisker(:,2),'linear',"movmedian",50);
            whisker_extraction_log.DLCSessionLikelihood(contains(whisker_extraction_log.Name, videos_to_convert{i})) = mean(analyzed_whisker(:,3));
            
            if mean(analyzed_whisker(:,3)) > 0.90
                writematrix(analyzed_whisker, fullfile(processed_whisker_data_path,file.name));
                whisker_extraction_log.Converted2Phase(contains(whisker_extraction_log.Name, videos_to_convert{i})) = true;
                log(i) = strcat(videos_to_convert{i}," was successfully converted to phase!");
            else
                log(i) = strcat(videos_to_convert{i}," did not meet the session minimum for DLC extraction quality (average likelihood < 0.90). Session likelihood was: ",string(mean(analyzed_whisker(:,3))));
                warning(strcat(videos_to_convert{i}," did not meet the session minimum for DLC extraction quality (average likelihood < 0.90). Session likelihood was: ",string(mean(analyzed_whisker(:,3)))));
            end    
        else
            log(i) = strcat(videos_to_convert{i}," failed to be converted to phase!!!!!");
        end
    end
 else
    log = [];
    log = "There are currently no whisker videos that need to be converted to phase.";
end

save(fullfile(paths.raw_whisker_data,"whisker_extraction_log.mat"), 'whisker_extraction_log');

end