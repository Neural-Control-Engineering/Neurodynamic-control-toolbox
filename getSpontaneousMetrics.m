function out = getSpontaneousMetrics(data, alignTo, tbounds)
    
    out = zeros(size(data,1), 6);

    % determine alignments 
    if strcmp(alignTo, 'stimulus_time')
        starts = data.stimulus_time;
    elseif strcmp(alignTo, 'response_time')
        starts = data.stimulus_time + data.response_time;
    end
    
    for trial = 1:size(data,1)
        t = data.photometry_ch1{trial,1}(:,1) - starts(trial);
        y1 = data.photometry_ch1{trial,1}(:,2);
        y2 = data.photometry_ch2{trial,1}(:,2);
        y1 = y1(t > tbounds(1) & t < tbounds(2));
        y2 = y2(t > tbounds(1) & t < tbounds(2));
        t = t(t > tbounds(1) & t < tbounds(2));
        try
            out(trial, :) = [data.pupil_base_before_stimulus{trial}, data.pupil_base_before_onset{trial}, data.photo_base_before_stim_ch1{trial}, data.photo_base_before_onset_ch1{trial}, data.photo_base_before_stim_ch2{trial}, data.photo_base_before_onset_ch2{trial}];
        catch
            out(trial, :) = [data.pupil_base_before_stimulus(trial), data.pupil_base_before_onset{trial}, data.photo_base_before_stim_ch1{trial}, data.photo_base_before_onset_ch1{trial}, data.photo_base_before_stim_ch2{trial}, data.photo_base_before_onset_ch2{trial}];
        end
    end

end