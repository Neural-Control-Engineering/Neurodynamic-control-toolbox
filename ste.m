function out = ste(x)
    out = nanstd(x) ./ sqrt(sum(~isnan(x)));
end