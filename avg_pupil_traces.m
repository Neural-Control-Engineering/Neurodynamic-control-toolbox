function [pupil, time] = avg_pupil_traces(data, tbounds, alignTo)
    % generates averages of pupil traces    keyboard

    if ~exist('alignTo', 'var')
        starts = data.stimulus_time;
    elseif strcmp(alignTo, 'stimulus')
        starts = data.stimulus_time;
    elseif strcmp(alignTo, 'response')
        starts = data.stimulus_time + data.response_time;
        data(isnan(starts), :) = [];
        starts = starts(~isnan(starts));
    else
        starts = data.stimulus_time;
    end
    % Fs = 1 / (data.pupil_area{1,1}(2,1)-data.pupil_area{1,1}(1,1));
    pupil = nan(size(data,1), length(tbounds(1):0.1:tbounds(2)));
    time = tbounds(1):0.1:tbounds(2);
    pre = -tbounds(1);
    post = tbounds(2);
    xvalues = tbounds(1):0.1:tbounds(2);
    for i = 1:size(data,1)
        stimTime = starts(i);
        pupilTrace = data.pupil_area{i};
        notLarger = (pupilTrace(:,1)-(stimTime-pre))<0;
        validIndices = find(notLarger);
        stimIndex = validIndices(end);
        segIndexStart = stimIndex-(pre*10);
        segIndexStop = stimIndex+(post*10);
            
        try
            pupilTraceSeg = pupilTrace(segIndexStart:segIndexStop,:);
            pupil(i,:) = pupilTraceSeg(:,2);
        catch 
            pupilTraceSeg = pupilTrace(segIndexStart:end,:);
            pupil(i,1:size(pupilTraceSeg,1)) = pupilTraceSeg(:,2);
        end
        
    end
end
