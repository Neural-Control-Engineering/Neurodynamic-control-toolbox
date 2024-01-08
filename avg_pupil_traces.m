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
    Fs = 1 / (data.pupil_area{1,1}(2,1)-data.pupil_area{1,1}(1,1));
    pupil = nan(size(data,1), round(Fs*diff(tbounds)));
    time = linspace(tbounds(1), tbounds(2), round(Fs*diff(tbounds)));

    for i = 1:size(data,1)
        t = data.pupil_area{i,1}(:,1) - starts(i);
        p = data.pupil_area{i,1}(:,2);
        p = p(t >= tbounds(1) & t <= tbounds(2));
        t = t(t >= tbounds(1) & t <= tbounds(2));
        try
            pupil(i,:) = p;
        catch
            % again with the sample rate issues
            try
                pupil(i,:) = interp1(t,p,time);
            end
        end
    end
end