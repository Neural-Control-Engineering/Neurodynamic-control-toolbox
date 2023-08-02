function [log] = convertPupil2Area(paths,reset_pupil2AreaConversion)
%CONVERTPUPIL2AREA Summary of this function goes here
%   Detailed explanation goes here

if reset_pupil2AreaConversion==true
    % Reset the analysis log
    load(fullfile(paths.raw_pupil_data,"pupil_extraction_log.mat"));
    pupil_extraction_log.Converted2Area(:) = false(length(pupil_extraction_log.Converted2Area),1);
    save(fullfile(paths.raw_pupil_data,"pupil_extraction_log.mat"), 'pupil_extraction_log');
end

processed_pupil_data_path = paths.processed_pupil_data;
DLC_path = fullfile(paths.raw_pupil_data,'DLC_extracted_data');

load(fullfile(paths.raw_pupil_data,"pupil_extraction_log.mat"),"pupil_extraction_log");
videos_to_convert = pupil_extraction_log.Name(pupil_extraction_log.Converted2Area == false & pupil_extraction_log.DLC_processed == true);

log = strings(length(videos_to_convert),1);

if ~isempty(videos_to_convert)
    for i = 1:length(videos_to_convert)
    try
        file = dir(fullfile(DLC_path,strcat(videos_to_convert{i}(1:end-4),'*filtered.csv*')));
    
        if ~isempty(file)
            % Use the most recent extracted pupil file
            pupil_data = readtable(fullfile(DLC_path,file(end).name),'NumHeaderLines',3);

            if strcmp(paths.data_source,"Project_Somatosensory-Signal-Detection")
                temp = dir(fullfile(paths.processed_behavior_data,strcat(videos_to_convert{i}(1:end-14),'_',videos_to_convert{i}(end-8:end-5),'_',videos_to_convert{i}(end-12:end-11),'_',videos_to_convert{i}(end-10:end-9),'*')));
            else
                temp = dir(fullfile(paths.processed_behavior_data,strcat(videos_to_convert{i}(1:end-4),'*')));
            end
            
            if ~isempty(temp)
                behavior_data = load(fullfile(temp.folder,temp.name));
            end
            
            analyzed_pupil_size = zeros(length(pupil_data.(1)),6);
        
            for j = 1:length(pupil_data.(1))
        
                x = [pupil_data.(2)(j); pupil_data.(17)(j); pupil_data.(11)(j); pupil_data.(23)(j); pupil_data.(5)(j); pupil_data.(20)(j); pupil_data.(8)(j); pupil_data.(14)(j)];
        
                y = [pupil_data.(3)(j); pupil_data.(18)(j); pupil_data.(12)(j); pupil_data.(24)(j); pupil_data.(6)(j); pupil_data.(21)(j); pupil_data.(9)(j); pupil_data.(15)(j)];

                likelihoods = [pupil_data.(4)(j); pupil_data.(19)(j); pupil_data.(13)(j); pupil_data.(25)(j); pupil_data.(7)(j); pupil_data.(22)(j); pupil_data.(10)(j); pupil_data.(16)(j)];
        
                pupil_fit = fit_ellipse(x,y); 
        
                if ~isempty(pupil_fit)
                    if ~strcmp(pupil_fit.status, "Hyperbola found")
                        pupil_area = pi * (pupil_fit.long_axis/2) * (pupil_fit.short_axis/2);
                        analyzed_pupil_size(j,1) = pupil_data.(1)(j); % time
                        analyzed_pupil_size(j,2) = pupil_area; %#ok<SAGROW>
                        analyzed_pupil_size(j,3) = pupil_fit.X0_in; % center x value
                        analyzed_pupil_size(j,4) = pupil_fit.Y0_in; % center y value
                        analyzed_pupil_size(j,5) = pupil_fit.a;     % subaxis (radius) of X axis
                        analyzed_pupil_size(j,6) = pupil_fit.b;     % subaxis (radius) of Y axis
                        analyzed_pupil_size(j,7) = pupil_fit.phi;   % tilt of the ellipse
                        analyzed_pupil_size(j,8) = mean(likelihoods); 
                    end
                end
            end

            % Trim start/stop times
            analyzed_pupil_size = analyzed_pupil_size(analyzed_pupil_size(:,1) >  behavior_data.behavior_data.video_details.pupil(1)-1 & analyzed_pupil_size(:,1) <  behavior_data.behavior_data.video_details.pupil(2),:);

            % Realign times to match behavior data
            analyzed_pupil_size(:,1) = analyzed_pupil_size(:,1) - analyzed_pupil_size(1,1);

            analyzed_pupil_size(:,2) = filloutliers(analyzed_pupil_size(:,2),'linear',"movmedian",5);
            analyzed_pupil_size(:,2) = zscore(analyzed_pupil_size(:,2));
            pupil_extraction_log.DLCSessionLikelihood(contains(pupil_extraction_log.Name, videos_to_convert{i})) = mean(analyzed_pupil_size(:,8));
        
            if mean(analyzed_pupil_size(:,8)) > 0.95
                writematrix(analyzed_pupil_size, fullfile(processed_pupil_data_path,file(end).name));
                pupil_extraction_log.Converted2Area(contains(pupil_extraction_log.Name, videos_to_convert{i})) = true;
                log(i) = strcat(videos_to_convert{i}," was successfully converted to area!");
            else
                log(i) = strcat(videos_to_convert{i}," did not meet the session minimum for DLC extraction quality (average likelihood < 0.95). Session likelihood was: ",string(mean(analyzed_pupil_size(:,8))));
                warning(strcat(videos_to_convert{i}," did not meet the session minimum for DLC extraction quality (average likelihood < 0.95). Session likelihood was: ",string(mean(analyzed_pupil_size(:,8)))));
            end
        else
            log(i) = strcat(videos_to_convert{i}," failed to be converted to area!!!!!");
        end
        
    catch
        display(strcat("Error with ",videos_to_convert{i}(1:end-4)))
    end
    display(strcat("Converted to pupil: ",videos_to_convert{i}(1:end-4)))
    end
else
    log = [];
    log = "There are currently no pupil videos that need to be converted to area.";
end

save(fullfile(paths.raw_pupil_data,"pupil_extraction_log.mat"), 'pupil_extraction_log');

end