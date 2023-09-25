function data = rmDiscrepantTrials(data)
    photo_dif = cellfun(@vecspan, data.photometry_ch1);
    pupil_dif = cellfun(@vecspan, data.pupil_area);
    data((photo_dif-pupil_dif)>1,:) = [];
end

function span = vecspan(vec)
    span = vec(end,1)-vec(1,1);
end