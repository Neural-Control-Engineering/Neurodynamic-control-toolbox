function out = KStest(x) 
    x = (x - nanmean(x)) - nanstd(x);
    out = kstest(x);
end