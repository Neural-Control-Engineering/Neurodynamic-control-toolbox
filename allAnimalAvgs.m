data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
animals = fetchAnimals(data);
data(cellfun(@isempty, data.photometry_ch1),:) = [];
tbounds = [-0.5, 6.0];

% % separate by outcome 
% outcome_types = unique(data.categorical_outcome);
% cols = distinguishable_colors(length(outcome_types));
% plotByOutcome(data, outcome_types, tbounds, cols, 'stimulus');
% % % two outcomes
% outcome_types = {'FA', 'Hit'};
% plotByOutcome(data, outcome_types, tbounds, {'r', 'b'}, 'response');
% % plot physiology separated by stim strength
% outcome_types = 'Hit';
% plotByStimStrength(data, tbounds, 'stimulus');
% tmp = filterTrials(data, 'categorical_outcome', outcome_types);
% plotByStimStrength(tmp, tbounds, 'response');
% plot avg psychometric curve 
% avgPsychCurve(data);
% % plot avg phys separated by stim strength and outcome
% outcome_types = {'FA', 'Hit'};
% tmp = filterTrials(data, 'categorical_outcome', outcome_types);
% plotByStimStratByOutcome(data, tbounds, 'stimulus');
% plotByStimStratByOutcome(tmp, tbounds, 'response');
% % plot hit rate vs false alarm rate for all sessions 
% plotFAvsHitRates(data)
% % plot histogram of first licks 
% plotFirstLickHist(data)
% % plot phys based on response time
% plotPhysByResponseTime(data, tbounds, 'stimulus')
% plotPhysByResponseTime(data, tbounds, 'response')
% psychometric curves separated by baseline pupil quintile 
% psychCurveByPupil(data)
% [Sm, Ss, Sp] = baselinesVsReactionTime(data);
% % check for photobleaching 
% checkPhotoBleach(data)
% reactionTimeVsStimStrength(data)

% timeToThreshold(data, 0.3)

figure2(data)

function figure2(data)
    pupilDilationByOutcome(data)
    baslinePupilByOutcome(data)
    avgPsychCurve(data)
    reactionTimeVsStimStrength(data)
    plotFirstLickHist(data)
    tbounds = [-0.5, 6.0];
    pupilByOutcome(data, tbounds, 'stimulus')
    pupilByStimStrength(data, tbounds, 'stimulus')
end

function pupilByOutcome(data, tbounds, alignTo)
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    fig = figure('Visible', 'on', 'WindowState', 'maximized');
    if ~exist('alignTo', 'var')
        alignTo = 'stimulus';
    end
    cols = distinguishable_colors(length(outcomes));
    for o = 1:length(outcomes)
        outcome = outcomes{o};
        otmp = filterTrials(data, 'categorical_outcome', outcome);
        [pupil, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
        subplot(1,length(outcomes),o)
        axis square
        hold on
        n = size(pupil,1);
        try
            semshade(pupil(:,2:end-1), 0.3, 'k', 'k', ...
                t(2:end-1), 1, sprintf('%s (n=%i)', outcome, n));
        catch
            semshade(pupil(:,2:end-1), 0.3, cols{i}, cols{i}, ...
            t(2:end-1), 1, sprintf('%s (n=%i)', outcome, n));
        end
        title(outcome, 'FontSize', 16)
        ylim([-0.5,0.5])
        xlim(tbounds)
    end
    subplot(1,length(outcomes),1)
    ylabel('Pupil Area (z-score)', 'FontSize', 14)
end

function pupilByStimStrength(data, tbounds, alingTo)
    fig = figure('Visible', 'on', 'WindowState', 'maximized');
    if ~exist('alignTo', 'var')
        alignTo = 'stimulus';
    end
    stim_strengths = unique(data.stimulus_strength);
    % outcomes = unique(data.categorical_outcome);
    if length(unique(data.categorical_outcome)) > 2
        outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    else
        % outcomes = unique(data.categorical_outcome);
        outcomes = {'Hit', 'FA'};
    end
    cols = distinguishable_colors(length(stim_strengths)+1);
    % if strcmp(alignTo, 'stimulus')
    %     cols = cols(2:end,:);
    % end
    count = 0;
    for o = 1:length(outcomes)
        outcome = outcomes{o};
        if ~strcmp(outcome,'Delayed FA (CR)') && ~strcmp(outcome, 'Near Hit (Miss)')
            tmp = filterTrials(data, 'categorical_outcome', outcome);
            count = count + 1;
        else
            tmp = [];
        end
        if ~isempty(tmp)
            for i = 1:length(stim_strengths)
                stim = stim_strengths(i);
                l = sprintf('%.2f PSI', stim);
                otmp = filterTrials(tmp, 'stim_strength', stim);
                if ~isempty(otmp)
                    [pupil, t] = avg_pupil_traces(otmp, [-0.5, 6.0], alignTo);
                    subplot(1,length(outcomes),o)
                    axis square
                    hold on
                    n = size(pupil,1);
                    try
                        semshade(pupil(:,2:end-1), 0.3, cols(i,:), cols(i,:), ...
                            t(2:end-1), 1, sprintf('%s (n=%i)', l, n));
                    catch
                        % keyboard
                        semshade(pupil(:,2:end-1), 0.3, cols{i}, cols{i}, ...
                        t(2:end-1), 1, sprintf('%s (n=%i)', l, n));
                    end
                end
                ylim([-0.6, 1.2])
            end
        end
        title(outcome, 'FontSize', 16)
    end
    subplot(1,length(outcomes),1)
    ylabel('Pupil Area (z-score)', 'FontSize', 14)
end

    

function reactionTimeVsStimStrength(data)
    outcomes = 'Hit';
    data = filterTrials(data, 'categorical_outcome', outcomes);
    starts = data.stimulus_time + data.response_time;
    data(isnan(starts),:) = [];
    stim_strengths = unique(data.stimulus_strength);
    avgs = zeros(1,length(stim_strengths));
    stds = zeros(1,length(stim_strengths));
    for i = 1:length(stim_strengths)
        rts = data.response_time(data.stimulus_strength == stim_strengths(i));
        avgs(i) = mean(rts);
        stds(i) = std(rts) ./ length(rts);
    end
    figure()
    errorbar(1:length(avgs), avgs, stds, 'k.')
    hold on
    bar(1:length(avgs), avgs, 'k')
    xticks(1:length(avgs))
    labels = {};
    for i = 1:length(stim_strengths)
        labels{i} = sprintf('%.1f',stim_strengths(i)*10);
    end
    xlabel('Stimulus Strength (PSI)', 'FontSize', 14)
    ylabel('Reaction Time (s)', 'FontSize', 14)
    xticklabels(labels)
end

function timeToThreshold(data, threshold)
    outcome = 'Hit';
    data = filterTrials(data, 'categorical_outcome', outcome);
    starts = data.stimulus_time + data.response_time;
    data(isnan(starts),:) = [];
    [ch1, ch2, t] = avg_photo_traces(data, [-0.5, 0], 'response');
    ch1_thresh = zeros(1,size(ch1,1));
    ch2_thresh = zeros(1,size(ch2,1));
    for trial = 1:size(ch1,1)
        ind = find(smooth(ch1(trial,:),10) > threshold, 1);
        if isempty(ind)
            ch1_thresh(trial) = nan;
        else
            ch1_thresh(trial) = t(ind);
        end
        ind = find(smooth(ch2(trial,:),10) > threshold, 1);
        if isempty(ind)
            ch2_thresh(trial) = nan;
        else
            ch2_thresh(trial) = t(ind);
        end
    end
    figure()
    subplot(1,2,1)
    scatter(data.response_time, ch1_thresh)
    hold on
    [m, S] = polyfit(data.response_time(~isnan(ch1_thresh)), ch1_thresh(~isnan(ch1_thresh)), 1);
    y = polyval(m, linspace(min(data.response_time), max(data.response_time), 10));
    plot(linspace(min(data.response_time), max(data.response_time), 10), y, 'r')
    subplot(1,2,2)
    scatter(data.response_time(~isnan(ch2_thresh)), ch2_thresh(~isnan(ch2_thresh)))
    hold on
    [m, S] = polyfit(data.response_time(~isnan(ch2_thresh)), ch2_thresh(~isnan(ch2_thresh)), 1);
    y = polyval(m, linspace(min(data.response_time), max(data.response_time), 10));
    plot(linspace(min(data.response_time), max(data.response_time), 10), y, 'r')
end

function [Sm, Ss, Sp] = baselinesVsReactionTime(data)
    outcomes = {'Hit', 'FA'};
    cols = distinguishable_colors(5);
    data = filterTrials(data, 'categorical_outcome', outcomes);
    starts = data.stimulus_time + data.response_time;
    data(isnan(starts),:) = [];
    [ch1, ch2, ~] = avg_photo_traces(data, [-0.5, 0], 'stimulus');
    mpfc = nanmean(ch1,2);
    s1 = nanmean(ch2,2);
    [p, ~] = avg_pupil_traces(data, [-0.5, 0], 'stimulus');
    pupil = nanmean(p,2);
    figure()
    subplot(1,3,1)
    hold on
    scatter(mpfc, data.response_time, 'ko')
    [pm, Sm] = polyfit(mpfc, data.response_time, 1);
    ym = polyval(pm, linspace(min(mpfc), max(mpfc), 10));
    plot(linspace(min(mpfc), max(mpfc), 10), ym, 'r')
    mpfc_R_squared = 1 - (Sm.normr/norm(ym - mean(ym)))^2
    xlabel('Baseline mPFC NE', 'FontSize', 14)
    ylabel('Reaction Time (s)', 'FontSize', 14)
    % keyboard
    subplot(1,3,2)
    hold on
    scatter(s1, data.response_time, 'ko')
    [ps, Ss] = polyfit(s1, data.response_time, 1);
    ys = polyval(ps, linspace(min(s1), max(s1), 10));
    s1_R_squared = 1 - (Ss.normr/norm(ys - mean(ys)))^2
    plot(linspace(min(s1), max(s1), 10), ys, 'r')
    xlabel('Baseline S1 NE', 'FontSize', 14)
    ylabel('Reaction Time (s)', 'FontSize', 14)
    subplot(1,3,3)
    hold on
    scatter(pupil, data.response_time, 'ko')    
    [pp, Sp] = polyfit(s1, data.response_time, 1);
    yp = polyval(pp, linspace(min(pupil), max(pupil), 10));
    plot(linspace(min(pupil), max(pupil), 10), yp, 'r')
    pupil_R_squared = 1 - (Sp.normr/norm(yp - mean(yp)))^2
    xlabel('Baseline Pupil', 'FontSize', 14)
    ylabel('Reaction Time (s)', 'FontSize', 14)
end
    
function pupilDilationByOutcome(data)
    % outcomes = unique(data.categorical_outcome);
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    dilations = zeros(2,length(outcomes));
    for o = 1:length(outcomes)
        outcome = outcomes{o};
        tmp = filterTrials(data, 'categorical_outcome', outcome);
        [pupil, ~] = avg_pupil_traces(tmp, [0,6.0], 'stimulus');
        [baseline, ~] = avg_pupil_traces(tmp, [-0.5,0.0], 'stimulus');
        dilations(1,o) = nanmean(nanmean(pupil))-nanmean(nanmean(baseline));
        dilations(2,o) = nanstd(nanmean(pupil,2)-nanmean(pupil,2)) / size(pupil,1);
    end
    figure()
    errorbar(1:size(dilations,2), dilations(1,:), dilations(2,:), 'k.')
    bar(1:size(dilations,2), dilations(1,:), 'k')
    hold on
    action_outcomes = {{'Hit', 'FA'}, {'Miss', 'CR'}};
    action_dilations = zeros(2,length(action_outcomes));
    for ao = 1:length(action_outcomes)
        outcome = action_outcomes{ao};
        tmp = filterTrials(data, 'categorical_outcome', outcome);
        [pupil, ~] = avg_pupil_traces(tmp, [0,6.0], 'stimulus');
        [baseline, ~] = avg_pupil_traces(tmp, [-0.5,0.0], 'stimulus');
        action_dilations(1,ao) = nanmean(nanmean(pupil))-nanmean(nanmean(baseline));
        action_dilations(2,ao) = nanstd(nanmean(pupil,2)-nanmean(pupil,2)) / size(pupil,1);
    end
    x = size(dilations,2)+2:size(dilations,2)+1+size(action_dilations,2);
    errorbar(x, action_dilations(1,:), action_dilations(2,:), 'k.')
    bar(x, action_dilations(1,:), 'k')
    xticks([1:size(dilations,2), x])
    labels = [outcomes, {'Responded', 'Withheld'}]
    xticklabels(labels)
    ylabel('Mean Pupil Dilation (z-score)')
end
        

function baslinePupilByOutcome(data)
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    baselines = zeros(2,length(outcomes));
    for o = 1:length(outcomes)
        outcome = outcomes{o};
        tmp = filterTrials(data, 'categorical_outcome', outcome);
        [baseline, ~] = avg_pupil_traces(tmp, [-0.5,0.0], 'stimulus');
        baselines(1,o) = nanmean(nanmean(baseline));
        baselines(2,o) = nanstd(nanmean(baseline,2)) / size(baseline,1);
    end
    figure()
    errorbar(1:size(baselines,2), baselines(1,:), baselines(2,:), 'k.')
    bar(1:size(baselines,2), baselines(1,:), 'k')
    hold on
    action_outcomes = {{'Hit', 'FA'}, {'Miss', 'CR'}};
    action_baselines = zeros(2,length(action_outcomes));
    for ao = 1:length(action_outcomes)
        outcome = action_outcomes{ao};
        tmp = filterTrials(data, 'categorical_outcome', outcome);
        [baseline, ~] = avg_pupil_traces(tmp, [-0.5,0.0], 'stimulus');
        action_baselines(1,ao) = nanmean(nanmean(baseline));
        action_baselines(2,ao) = nanstd(nanmean(baseline,2)) / size(baseline,1);
    end
    x = size(baselines,2)+2:size(baselines,2)+1+size(action_baselines,2);
    errorbar(x, action_baselines(1,:), action_baselines(2,:), 'k.')
    bar(x, action_baselines(1,:), 'k')
    xticks([1:size(baselines,2), x])
    labels = [outcomes, {'Responded', 'Withheld'}];
    xticklabels(labels)
    ylabel('Mean Baseline Pupil Area (z-score)')
end

function psychCurveByPupil(data)
    ptiles = 20:20:100;
    low = prctile(data.pupil_base_before_stimulus, 0);
    stim_strengths = unique(data.stimulus_strength);
    cols = distinguishable_colors(5);
    fig = figure();
    for i = 1:length(ptiles)
        ptile = ptiles(i);
        high = prctile(data.response_time, ptile);
        x = data.pupil_base_before_stimulus >= low & data.pupil_base_before_stimulus <= high;
        low = high;
        tmp = data(x,:);
        mat = nan(size(tmp,1), length(stim_strengths));
        for trial = 1:size(tmp,1)
            ind = find(stim_strengths == tmp.stimulus_strength(trial));
            if strcmp(tmp.categorical_outcome{trial}, 'Hit') || strcmp(tmp.categorical_outcome{trial}, 'CR')
                mat(trial, ind) = 1;
            else
                mat(trial, ind) = 0;
            end
        end
        switch i 
            case 1  
                l = sprintf('%ist quintile', i);
            case 2
                l = sprintf('%ind quintile', i);
            case 3
                l = sprintf('%ird quintile', i);
            otherwise
                l = sprintf('%ith quintile', i);
        end
        n = size(mat,1);
        semshade(mat(:,2:end), 0.3, cols(i,:), cols(i,:), stim_strengths(2:end) .* 10, 1, sprintf('%s (n=%i)', l, n));
        hold on
    end
    xlabel('Stimulus Strength (PSI)', 'FontSize', 14)
    ylabel('Performance', 'FontSize', 14)
    legend()
end

function plotPhysByResponseTime(data, tbounds, alignTo)
    outcomes = {'Hit', 'FA'};
    cols = distinguishable_colors(5);
    data = filterTrials(data, 'categorical_outcome', outcomes);
    ptiles = 20:20:100;
    low = prctile(data.response_time, 0);
    figure();
    for i = 1:length(ptiles)
        ptile = ptiles(i);
        high = prctile(data.response_time, ptile);
        tmp = filterTrials(data, 'response_time', [low, high]);
        switch i 
            case 1  
                l = sprintf('%ist quintile', i);
            case 2
                l = sprintf('%ind quintile', i);
            case 3
                l = sprintf('%ird quintile', i);
            otherwise
                l = sprintf('%ith quintile', i);
        end
        low = high;
        [ch1, ch2, tp] = avg_photo_traces(tmp, tbounds, alignTo);
        n = size(ch1,1);
        subplot(1,3,1)
        hold on 
        try
            semshade(ch1(:,2:end-1), 0.3, cols(i,:), cols(i,:), ...
                tp(2:end-1), 1, sprintf('%s (n=%i)', l, n));
        catch
            % keyboard
            semshade(ch1(:,2:end-1), 0.3, cols{i}, cols{i}, ...
                tp(2:end-1), 1, sprintf('%s (n=%i)', l, n));
        end
        subplot(1,3,2)
        hold on 
        try
            semshade(ch2(:,2:end-1), 0.3, cols(i,:), cols(i,:), ...
                tp(2:end-1), 1, sprintf('%s (n=%i)', l, n));
        catch
            % keyboard
            semshade(ch2(:,2:end-1), 0.3, cols{i}, cols{i}, ...
                tp(2:end-1), 1, sprintf('%s (n=%i)', l, n));
        end
        [pupil, t] = avg_pupil_traces(tmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
        % keyboard
        subplot(1,3,3)
        hold on
        try
            semshade(pupil(:,2:end-1), 0.3, cols(i, :), cols(i, :), ...
                t(2:end-1), 1, sprintf('%s (n=%i)', l, n));
        catch
            % keyboard
            semshade(pupil(:,2:end-1), 0.3, cols{i}, cols{i}, ...
            t(2:end-1), 1, sprintf('%s (n=%i)', l, n));
        end
    end
    subplot(1,3,1)
    xlabel('Time (s)', 'FontSize', 14)
    ylabel('mPFC NE', 'FontSize', 14)
    % if strcmp(alignTo, 'stimulus')
    %     ylim([-0.2, 0.7])
    %     plot([0,0], [-0.2, 0.7], 'k:', 'HandleVisibility', 'off')
    % else
    %     ylim([-0.2, 0.7])
    %     plot([0,0], [-0.2, 0.7], 'k:', 'HandleVisibility', 'off')
    % end
    ylim([-0.2, 0.7])
    plot([0,0], [-0.2, 0.7], 'k:', 'HandleVisibility', 'off')
    xlim([tbounds(1), tbounds(2)])
    subplot(1,3,2)
    xlabel('Time (s)', 'FontSize', 14)
    ylabel('S1 NE', 'FontSize', 14)
    % if strcmp(alignTo, 'stimulus')
    %     ylim([-0.2, 0.7])
    %     plot([0,0], [-0.2, 0.7], 'k:', 'HandleVisibility', 'off')
    % else
    %     ylim([-0.2, 0.7])
    %     plot([0,0], [-0.2, 0.7], 'k:', 'HandleVisibility', 'off')
    % end
    xlim([tbounds(1), tbounds(2)])
    subplot(1,3,3)
    if strcmp(alignTo, 'stimulus')
        ylim([-0.35, 0.5])
        plot([0,0], [-0.4, 0.3], 'k:', 'HandleVisibility', 'off')
    else
        ylim([-0.4, 0.5])
        plot([0,0], [-0.4, 0.5], 'k:', 'HandleVisibility', 'off')
    end
    xlabel('Time (s)', 'FontSize', 14)
    ylabel('Pupil Area', 'FontSize', 14)
    legend('location', 'southeast')
    xlim([tbounds(1), tbounds(2)])
end


function plotFAvsHitRates(data)
    sessions = unique(data.session_id);
    hr = zeros(1, length(sessions));
    far = zeros(1,length(sessions));
    for s = 1:length(sessions)
        sesh = sessions{s};
        tmp = filterTrials(data, 'session_id', sesh);
        hits = filterTrials(tmp, 'categorical_outcome', 'Hit');
        hr(s) = size(hits,1) / size(tmp,1);
        fas = filterTrials(tmp, 'categorical_outcome', 'FA');
        far(s) = size(fas,1) / size(tmp,1);
    end
    figure()
    scatter(far, hr)
    hold on
    plot([0,1], [0,1], 'k:', 'HandleVisibility', 'off')
    xlabel('False Alarm Rate', 'FontSize', 14)
    ylabel('Hit Rate', 'FontSize', 14)
end

function plotFirstLickHist(data)
    figure()
    outcomes = {'Hit', 'FA'};
    data = filterTrials(data, 'categorical_outcome', outcomes);
    histogram(data.response_time, 20)
    xlabel('Response Time (s)', 'FontSize', 14)
    ylabel('N_{trials}', 'FontSize', 14)
    xlim([0,0.8])
end

function fig = plotByStimStratByOutcome(data, tbounds, alignTo)
    fig = figure('Visible', 'on', 'WindowState', 'maximized');
    if ~exist('alignTo', 'var')
        alignTo = 'stimulus';
    end
    stim_strengths = unique(data.stimulus_strength);
    % outcomes = unique(data.categorical_outcome);
    if length(unique(data.categorical_outcome)) > 2
        outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    else
        % outcomes = unique(data.categorical_outcome);
        outcomes = {'Hit', 'FA'};
    end
    cols = distinguishable_colors(length(stim_strengths)+1);
    % if strcmp(alignTo, 'stimulus')
    %     cols = cols(2:end,:);
    % end
    count = 0;
    for o = 1:length(outcomes)
        outcome = outcomes{o};
        if ~strcmp(outcome,'Delayed FA (CR)') && ~strcmp(outcome, 'Near Hit (Miss)')
            tmp = filterTrials(data, 'categorical_outcome', outcome);
            count = count + 1;
        else
            tmp = [];
        end
        if ~isempty(tmp)
            for i = 1:length(stim_strengths)
                stim = stim_strengths(i);
                l = sprintf('%.2f PSI', stim);
                otmp = filterTrials(tmp, 'stim_strength', stim);
                if ~isempty(otmp)
                    [ch1, ch2, tp] = avg_photo_traces(otmp, tbounds, alignTo);
                    n = size(ch1,1);
                    % subplot(length(outcomes),3,sub2ind([4,3],count,1))
                    subplot(length(outcomes),3,(count*3-3)+1)
                    hold on 
                    try
                        semshade(ch1(:,2:end-1), 0.3, cols(i,:), cols(i,:), ...
                            tp(2:end-1), 1, sprintf('%s (n=%i)', l, n));
                    catch
                        % keyboard
                        % plot(tp, ch1, 'DisplayName', ...
                        %     sprintf('%s (n=%i)', outcome, n))
                        semshade(ch1(:,2:end-1), 0.3, cols{i}, cols{i}, ...
                            tp(2:end-1), 1, sprintf('%s (n=%i)', l, n));
                    end
                    % subplot(length(outcomes),3,sub2ind([4,3],count,2))
                    subplot(length(outcomes),3,(count*3-3)+2)
                    hold on 
                    try
                        semshade(ch2(:,2:end-1), 0.3, cols(i,:), cols(i,:), ...
                            tp(2:end-1), 1, sprintf('%s (n=%i)', l, n));
                    catch
                        % keyboard
                        semshade(ch2(:,2:end-1), 0.3, cols{i}, cols{i}, ...
                            tp(2:end-1), 1, sprintf('%s (n=%i)', l, n));
                    end
                    [pupil, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
                    % keyboard
                    subplot(length(outcomes),3,(count*3-3)+3)
                    hold on
                    try
                        semshade(pupil(:,2:end-1), 0.3, cols(i, :), cols(i, :), ...
                            t(2:end-1), 1, sprintf('%s (n=%i)', l, n));
                    catch
                        % keyboard
                        semshade(pupil(:,2:end-1), 0.3, cols{i}, cols{i}, ...
                        t(2:end-1), 1, sprintf('%s (n=%i)', l, n));
                    end
                end
            end
            subplot(length(outcomes),3,(count*3-3)+1)
            ylabel('mPFC NE', 'FontSize', 14)
            if length(outcomes) > 2
                ylim([-0.4, 0.6])
                plot([0,0], [-0.4, 0.6], 'k:', 'HandleVisibility', 'off')
            else
                ylim([-0.4,0.8])
                plot([0,0], [-0.4, 0.8], 'k:', 'HandleVisibility', 'off')
            end
            xlim([tbounds(1), tbounds(2)])
            subplot(length(outcomes),3,(count*3-3)+2)
            ylabel('S1 NE', 'FontSize', 14)
            title(outcome, 'FontSize', 16, 'FontWeight', 'bold')
            if length(outcomes) > 2
                ylim([-0.4, 0.6])
                plot([0,0], [-0.4, 0.6], 'k:', 'HandleVisibility', 'off')
            else
                ylim([-0.4,0.8])
                plot([0,0], [-0.4, 0.8], 'k:', 'HandleVisibility', 'off')
            end
            xlim([tbounds(1), tbounds(2)])
            subplot(length(outcomes),3,(count*3-3)+3)
            ylabel('Pupil Area', 'FontSize', 14)
            if length(outcomes) > 2
                ylim([-0.5, 1.2])
                plot([0,0], [-0.5, 1.2], 'k:', 'HandleVisibility', 'off')
            else
                ylim([-0.5,0.5])
                plot([0,0], [-0.5, 0.5], 'k:', 'HandleVisibility', 'off')
            end
            legend('location', 'southeast')
            xlim([tbounds(1), tbounds(2)])
        end
        subplot(length(outcomes),3,(count*3-3)+1)
        xlabel('Time (s)', 'FontSize', 14)
        subplot(length(outcomes),3,(count*3-3)+2)
        xlabel('Time (s)', 'FontSize', 14)
        subplot(length(outcomes),3,(count*3-3)+3)
        xlabel('Time (s)', 'FontSize', 14)
    end
end

function fig = plotByStimStrength(data, tbounds, alignTo)
    fig = figure('Visible', 'on', 'WindowState', 'maximized');
    if ~exist('alignTo', 'var')
        alignTo = 'stimulus';
    end
    stim_strengths = unique(data.stimulus_strength);
    cols = distinguishable_colors(length(stim_strengths)+1);
    if strcmp(alignTo, 'response')
        cols = cols(2:end,:);
    end
    if ~isempty(data)
        for i = 1:length(stim_strengths)
            stim = stim_strengths(i);
            l = sprintf('%.2f PSI', stim);
            otmp = filterTrials(data, 'stim_strength', stim);
            [ch1, ch2, tp] = avg_photo_traces(otmp, tbounds, alignTo);
            n = size(ch1,1);
            subplot(1,3,1)
            hold on 
            try
                semshade(ch1(:,2:end-1), 0.3, cols(i,:), cols(i,:), ...
                    tp(2:end-1), 1, sprintf('%s (n=%i)', l, n));
            catch
                % keyboard
                % plot(tp, ch1, 'DisplayName', ...
                %     sprintf('%s (n=%i)', outcome, n))
                semshade(ch1(:,2:end-1), 0.3, cols{i}, cols{i}, ...
                    tp(2:end-1), 1, sprintf('%s (n=%i)', l, n));
            end
            subplot(1,3,2)
            hold on 
            try
                semshade(ch2(:,2:end-1), 0.3, cols(i,:), cols(i,:), ...
                    tp(2:end-1), 1, sprintf('%s (n=%i)', l, n));
            catch
                % keyboard
                semshade(ch2(:,2:end-1), 0.3, cols{i}, cols{i}, ...
                    tp(2:end-1), 1, sprintf('%s (n=%i)', l, n));
            end
            [pupil, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
            % keyboard
            subplot(1,3,3)
            hold on
            try
                semshade(pupil(:,2:end-1), 0.3, cols(i, :), cols(i, :), ...
                    t(2:end-1), 1, sprintf('%s (n=%i)', l, n));
            catch
                % keyboard
                semshade(pupil(:,2:end-1), 0.3, cols{i}, cols{i}, ...
                t(2:end-1), 1, sprintf('%s (n=%i)', l, n));
            end
        end
    end
    subplot(1,3,1)
    ylabel('mPFC NE', 'FontSize', 14)
    xlabel('Time (s)', 'FontSize', 14)
    xlim([tbounds(1), tbounds(2)])
    subplot(1,3,2)
    ylabel('S1 NE', 'FontSize', 14)
    xlabel('Time (s)', 'FontSize', 14)
    xlim([tbounds(1), tbounds(2)])
    subplot(1,3,3)
    ylabel('Pupil Area', 'FontSize', 14)
    xlabel('Time (s)', 'FontSize', 14)
    legend('location', 'southeast')
    xlim([tbounds(1), tbounds(2)])
end


function fig = plotByOutcome(data, outcomes, tbounds, cols, alignTo)
    fig = figure('Visible', 'on', 'WindowState', 'maximized');
    if ~exist('alignTo', 'var')
        alignTo = 'stimulus';
    end
    for i = 1:length(outcomes)
        outcome = outcomes{i};
        if ~strcmp(outcome,'Delayed FA (CR)') && ~strcmp(outcome, 'Near Hit (Miss)')
            otmp = filterTrials(data, 'categorical_outcome', outcome);
        else
            otmp = [];
        end
        if ~isempty(otmp)
            [ch1, ch2, tp] = avg_photo_traces(otmp, tbounds, alignTo);
            n = size(ch1,1);
            subplot(1,3,1)
            hold on 
            try
                semshade(ch1(:,2:end-1), 0.3, cols(i+1,:), cols(i+1,:), ...
                    tp(2:end-1), 1, sprintf('%s (n=%i)', outcome, n));
            catch
                % keyboard
                % plot(tp, ch1, 'DisplayName', ...
                %     sprintf('%s (n=%i)', outcome, n))
                semshade(ch1(:,2:end-1), 0.3, cols{i}, cols{i}, ...
                    tp(2:end-1), 1, sprintf('%s (n=%i)', outcome, n));
            end
            subplot(1,3,2)
            hold on 
            try
                semshade(ch2(:,2:end-1), 0.3, cols(i+1,:), cols(i+1,:), ...
                    tp(2:end-1), 1, sprintf('%s (n=%i)', outcome, n));
            catch
                % keyboard
                semshade(ch2(:,2:end-1), 0.3, cols{i}, cols{i}, ...
                    tp(2:end-1), 1, sprintf('%s (n=%i)', outcome, n));
            end
            [pupil, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
            % keyboard
            subplot(1,3,3)
            hold on
            try
                semshade(pupil(:,2:end-1), 0.3, cols(i+1, :), cols(i+1, :), ...
                    t(2:end-1), 1, sprintf('%s (n=%i)', outcome, n));
            catch
                % keyboard
                semshade(pupil(:,2:end-1), 0.3, cols{i}, cols{i}, ...
                t(2:end-1), 1, sprintf('%s (n=%i)', outcome, n));
            end
        end
    end
    subplot(1,3,1)
    ylabel('mPFC NE', 'FontSize', 14)
    xlabel('Time (s)', 'FontSize', 14)
    xlim([tbounds(1), tbounds(2)])
    subplot(1,3,2)
    ylabel('S1 NE', 'FontSize', 14)
    xlabel('Time (s)', 'FontSize', 14)
    xlim([tbounds(1), tbounds(2)])
    subplot(1,3,3)
    ylabel('Pupil Area', 'FontSize', 14)
    xlabel('Time (s)', 'FontSize', 14)
    legend('location', 'southeast')
    xlim([tbounds(1), tbounds(2)])
end

function [ch1mat, ch2mat, time] = avg_photo_traces(data, tbounds, alignTo)
    % generates averages of photometry traces 
    if ~exist('alignTo', 'var')
        starts = data.stimulus_time;
    elseif strcmp(alignTo, 'stimulus')
        starts = data.stimulus_time;
    elseif strcmp(alignTo, 'response')
        starts = data.stimulus_time + data.response_time;
        data(isnan(starts),:) = [];
        starts = starts(~isnan(starts));
    else
        starts = data.stimulus_time;
    end
    Fss = getFs(data, 'photometry_ch1');
    ch1mat = zeros(size(data,1), round(max(Fss)*diff(tbounds)));
    ch2mat = ch1mat;
    time = linspace(tbounds(1), tbounds(2), round(max(Fss)*diff(tbounds)));

    for i = 1:size(data,1)
        t = data.photometry_ch1{i,1}(:,1) - starts(i);
        ch1 = data.photometry_ch1{i,1}(:,2);
        ch2 = data.photometry_ch2{i,1}(:,2);
        ch1 = ch1(t > tbounds(1) & t < tbounds(2));
        ch2 = ch2(t > tbounds(1) & t < tbounds(2));
        t = t(t > tbounds(1) & t < tbounds(2));
        % using interp1 to avoid issues with differing sample rates
        ch1mat(i,:) = interp1(t, ch1, time);
        ch2mat(i,:) = interp1(t, ch2, time);
    end
end

function [pupil, time] = avg_pupil_traces(data, tbounds, alignTo)
    % generates averages of pupil traces
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
            % again with the sample rate issues
            pupil(i,:) = interp1(t,p,time);
        end
    end
end

function avgPsychCurve(data)
    figure()
    animals = fetchAnimals(data);
    cols = {'b', 'r', 'g', 'm'};
    for a = 1:length(animals)
        animal = animals(a);
        tmp = filterTrials(data, 'animal', num2str(animal));
        stim_strengths = unique(tmp.stimulus_strength);
        mat = nan(size(tmp,1), length(stim_strengths));
        for trial = 1:size(tmp,1)
            ind = find(stim_strengths == tmp.stimulus_strength(trial));
            if strcmp(tmp.categorical_outcome{trial}, 'Hit') || strcmp(tmp.categorical_outcome{trial}, 'CR')
                mat(trial, ind) = 1;
            else
                mat(trial, ind) = 0;
            end
        end
        sessions = unique(tmp.session_id);
        semshade(mat(:,2:end), 0.3, cols{a}, cols{a}, stim_strengths(2:end) .* 10, 1, sprintf('Animal %i (N_{sessions}=%i)', a-1, length(sessions)));
        hold on
    end
    stim_strengths = unique(data.stimulus_strength);
    mat = nan(size(data,1), length(stim_strengths));
    for trial = 1:size(data,1)
        ind = find(stim_strengths == data.stimulus_strength(trial));
        if strcmp(data.categorical_outcome{trial}, 'Hit') || strcmp(data.categorical_outcome{trial}, 'CR')
            mat(trial, ind) = 1;
        else
            mat(trial, ind) = 0;
        end
    end
    % keyboard
    % mat = nansum(mat,1) ./ sum(~isnan(mat),1);
    n = size(mat,1);
    % semshade(mat(:,2:end), 0.3, 'k', 'k', stim_strengths(2:end) .* 10, 1, sprintf('Mean: (N_{animals}=%i)', length(animals)));
    plot(stim_strengths(2:end) .* 10, nanmean(mat(:,2:end)), 'k--', 'LineWidth', 2, 'DisplayName', sprintf('Mean: (N_{animals}=%i)', length(animals)))
    xlabel('Stimulus Strength (PSI)', 'FontSize', 14)
    ylabel('Performance', 'FontSize', 14)
    legend('location', 'southeast')
end

function checkPhotoBleach(data)
    animals = fetchAnimals(data);
    animal = animals(3);
    tmp = filterTrials(data, 'animal', num2str(animal));
    sessions = unique(tmp.session_id);
    for s = 1:length(sessions)
        session = sessions{s};
        stmp = filterTrials(tmp, 'session_id', session);
        figure()
        for t = 1:size(stmp)
            subplot(1,2,1)
            hold on
            plot(data.photometry_ch1{t,1}(:,1), data.photometry_ch1{t,1}(:,2), 'k')
            subplot(1,2,2)
            hold on
            plot(data.photometry_ch2{t,1}(:,1), data.photometry_ch2{t,1}(:,2), 'k')
        end
    end
end

