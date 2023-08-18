function out = getPhotometryMetrics(data, alignTo, tbounds)
    
    out = zeros(size(data,1), 4);

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
        [p1, ind1] = max(y1);
        [p2, ind2] = max(y2);
        out(trial, :) = [p1, t(ind1), p2, t(ind2)];
    end
end

        
