params = analysis_params;
pu_time = linspace(-1*params.before_event, params.after_event, length(pupilData(1, :)));
idxs = pu_time <= 0 & pu_time >= -.5;

uppy = [];
downy = [];
slopes = [];
maxes = [];

plusplus = [];
plusminus = [];
minusplus = [];
minusminus = [];

figure(1); hold on;
for i = 1:length(pupilData)
%     plot(pu_time(idxs), pupilData(i, idxs))
    [p, S] = polyfit(pu_time(idxs), pupilData(i, idxs), 1);
    m = p(1);
    b = p(2);
    f = fit(pu_time(idxs)', pupilData(i, idxs)','exp1');
    m = f.a;
    b = f.b;
%     slopes = [slopes; m];
%     maxes = [maxes; max(pupilData(i, :))];
%     if m > 0
%         uppy = [uppy; pupilData(i, :)];
%         color = 'r-';
%     else
%         downy = [downy; pupilData(i, :)];
%         color = 'b-';
%     end
     if m > 0 && b > 0
         plusplus = [plusplus; pupilData(i, :)];
         color = 'b-';
     elseif m > 0 && b < 0
         plusminus = [plusminus; pupilData(i, :)];
         color = 'g-';
     elseif m < 0 && b > 0
         minusplus = [minusplus; pupilData(i, :)];
         color = 'y-';
     else
         minusminus = [minusminus; pupilData(i, :)];
         color = 'r-';
     end
%     f1 = polyval(p,pu_time(idxs));
%     plot(pu_time(idxs), f1, color)
%     plot(f, color);
end

hold off;
figure(4); hold on;
plot(1:length(slopes), slopes)
plot(1:length(slopes), maxes)
plot(pu_time, mean(plusplus, 1), 'b-')
plot(pu_time, mean(plusminus, 1), 'g-')
plot(pu_time, mean(minusplus, 1), 'y-')
plot(pu_time, mean(minusminus, 1), 'r-')

legend({'m+ b+', 'm+ b-', 'm- b+', 'm- b-'})
hold off;

uppy_mean = mean(uppy, 1);
downy_mean = mean(downy, 1);
uppy_sem = std(uppy, 0, 1) / sqrt(size(uppy, 1));
downy_sem = std(downy, 0, 1) / sqrt(size(downy, 1));

figure(2); hold on;
% plot(pu_time, mean(uppy, 1), 'r-')
% plot(pu_time, mean(downy, 1), 'b-')
shadedErrorBar(pu_time, uppy_mean, uppy_sem, ...
                   'lineprops', '-r', 'transparent', 1);
shadedErrorBar(pu_time, downy_mean, downy_sem, ...
                   'lineprops', '-b', 'transparent', 1);
hold off;

figure(3); hold on;
histogram(slopes, 1000)
