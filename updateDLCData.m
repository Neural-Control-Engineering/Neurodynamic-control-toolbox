function updateDLCData(paths,resets,mode)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here


% ################ PUPIL #####################
% Process any unprocessed pupil data for all sessions
if strcmp(mode,"pupil") || strcmp(mode,"pupil_whisker")
    display("Please wait. Checking that all pupil data has been updated...");
    [temp_log] = convertPupil2Area(paths,resets.reset_pupil2AreaConversion);
    display(temp_log(:))
end

% ################ WHISKER #####################
% Process any unprocessed whisker data for all sessions
if strcmp(mode,"whisker") || strcmp(mode,"pupil_whisker")
    display("Please wait. Checking that all whisker data has been updated...");
    [temp_log] = convertWhisker2Phase(paths,resets.reset_whisker2PhaseConversion);
    display(temp_log(:))
end

fetchOutlierVideos(paths);
end