% time = linspace(-1*params.before_event, params.after_event, length(alldat(1, :, 1)));

% NTData = alldat;

idxs = time <= 0 & time >= -.5;

chan_1_uppy = [];
chan_2_uppy = [];
chan_1_downy = [];
chan_2_downy = [];
chan_1_meddy = [];
chan_2_meddy = [];

f1s = [];

for i = 1:size(NTData, 1)
    [m1, b1] = polyfit(time(idxs), NTData(i, idxs, 1), 1);
    [m2, b2] = polyfit(time(idxs), NTData(i, idxs, 2), 1);
    f1 = fit(time(idxs)', NTData(i, idxs, 1)','exp1');
    f1s(end+1) = f1.a;
    f2 = fit(time(idxs)', NTData(i, idxs, 2)','exp1');
    if f1.a >= .43
        chan_1_uppy = [chan_1_uppy; NTData(i, :, 1)];
        color = 'r-';
    elseif f1.a <= .43 && f1.a >= -.43
        chan_1_meddy = [chan_1_meddy; NTData(i, :, 1)];
    else
        chan_1_downy = [chan_1_downy; NTData(i, :, 1)];
    end
    if f1.a >= .43
        chan_2_uppy = [chan_2_uppy; NTData(i, :, 2)];
        color = 'r-';
    elseif f1.a <= .43 && f1.a >= -.43
        chan_2_meddy = [chan_2_meddy; NTData(i, :, 2)];
    else
        chan_2_downy = [chan_2_downy; NTData(i, :, 2)];
    end
end
%%

chan_1_uppy_mean = mean(chan_1_uppy, 1);
chan_1_downy_mean = mean(chan_1_downy, 1);
chan_1_uppy_sem = std(chan_1_uppy, 0, 1) / sqrt(size(chan_1_uppy, 1));
chan_1_downy_sem = std(chan_1_downy, 0, 1) / sqrt(size(chan_1_downy, 1));
chan_1_meddy_mean = mean(chan_1_meddy, 1);
chan_1_meddy_sem = std(chan_1_meddy, 0, 1) / sqrt(size(chan_1_meddy, 1));

chan_2_uppy_mean = mean(chan_2_uppy, 1);
chan_2_downy_mean = mean(chan_2_downy, 1);
chan_2_uppy_sem = std(chan_2_uppy, 0, 1) / sqrt(size(chan_2_uppy, 1));
chan_2_downy_sem = std(chan_2_downy, 0, 1) / sqrt(size(chan_2_downy, 1));
chan_2_meddy_mean = mean(chan_2_meddy, 1);
chan_2_meddy_sem = std(chan_2_meddy, 0, 1) / sqrt(size(chan_2_meddy, 1));

figure(1); hold on;
shadedErrorBar(time, chan_1_uppy_mean, chan_1_uppy_sem, ...
                   'lineprops', '-r', 'transparent', 1);
shadedErrorBar(time, chan_1_downy_mean, chan_1_downy_sem, ...
                   'lineprops', '-g', 'transparent', 1);
shadedErrorBar(time, chan_1_meddy_mean, chan_1_meddy_sem, ...
                   'lineprops', '-b', 'transparent', 1);
line([0 0], [-1.5 1.5], 'Color','black','LineStyle','--');
xlabel("Time (s)")
ylabel("TBD")
legend([ "[0.43, inf]","[-inf, -0.43]", "[-0.43, 0.43]"]);
title('NE');
hold off;
figure(2); hold on;
shadedErrorBar(time, chan_2_uppy_mean, chan_2_uppy_sem, ...
                   'lineprops', '-r', 'transparent', 1);
shadedErrorBar(time, chan_2_downy_mean, chan_2_downy_sem, ...
                   'lineprops', '-g', 'transparent', 1);
shadedErrorBar(time, chan_2_meddy_mean, chan_2_meddy_sem, ...
                   'lineprops', '-b', 'transparent', 1)
line([0 0], [-1.5 1.5]);
title('ACh');
hold off;
