function fig2e(data, tbounds, alignTo)
    stim_strengths = unique(data.stimulus_strength);
    cols = distinguishable_colors(length(stim_strengths)+1);
    tmp = filterTrials(data, 'categorical_outcome', 'Hit');
    dilations = [];
    baselines = [];
    for s = 2:length(stim_strengths)
        stmp = filterTrials(tmp, 'stim_strength', stim_strengths(s));
        [pupil, t] = avg_pupil_traces(stmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
        pupil = pupil(:,2:end-1);
        t = t(2:end-1);
        b =  nanmean(pupil(:,(t > -0.5 & t < 0)),2);
        e = nanmean(pupil(:,(t > 0 & t < 6)),2);
        d = e - b;
        baselines = [baselines; b];
        dilations = [dilations; d];
        % plot(b, e, 'o', 'MarkerFaceColor', cols(s,:), 'MarkerSize', 2.0)
        % hold on
    end
    scatter(baselines, dilations, 'MarkerFaceColor', [0.5,0.5,0.5], 'MarkerEdgeColor', [1,1,1])
    x = baselines;
    y = dilations;
    mdl = fitlm(x, y)
    [FM, S]=polyfit(x(~isnan(x)),y(~isnan(y)),1);
    [FM_vals, delta] = polyval(FM,linspace(min(x),max(x),10), S); 
    hold on; plot(linspace(min(x),max(x),10), FM_vals, 'k--', 'linewidth',2) 
    xlabel('Baseline Pupil Area (z-score)', 'FontSize', 16)
    ylabel('Pupil Dilation (z-score)', 'FontSize', 16)
    xlim([-2.5,5.1])
end