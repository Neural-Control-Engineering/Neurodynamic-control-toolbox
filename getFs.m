function out = getFs(data, channel)
% returns sampling frequencies for each trial stored in data
% Craig Kelley, NEC Lab, 8/21/23
    out = cellfun(@singleFs, data.(channel));
end

function out = singleFs(mat)
    t = mat(:,1);
    out = 1 / (t(2) - t(1));
end