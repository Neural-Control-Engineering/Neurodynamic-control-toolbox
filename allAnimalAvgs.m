data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
animals = fetchAnimals(data);
data(cellfun(@isempty, data.photometry_ch1),:) = [];
tbounds = [-0.5, 4.0];

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
% % plot avg psychometric curve 
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
psychCurveByPupil(data)

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
            keyboard
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
    if strcmp(alignTo, 'stimulus')
        ylim([-0.2, 0.7])
        plot([0,0], [-0.2, 0.7], 'k:', 'HandleVisibility', 'off')
    else
        ylim([-0.2, 0.7])
        plot([0,0], [-0.2, 0.7], 'k:', 'HandleVisibility', 'off')
    end
    xlim([tbounds(1), tbounds(2)])
    subplot(1,3,2)
    xlabel('Time (s)', 'FontSize', 14)
    ylabel('S1 NE', 'FontSize', 14)
    if strcmp(alignTo, 'stimulus')
        ylim([-0.2, 0.7])
        plot([0,0], [-0.2, 0.7], 'k:', 'HandleVisibility', 'off')
    else
        ylim([-0.2, 0.7])
        plot([0,0], [-0.2, 0.7], 'k:', 'HandleVisibility', 'off')
    end
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
    figure()
    n = size(mat,1);
    semshade(mat(:,2:end), 0.3, 'b', 'b', stim_strengths(2:end) .* 10, 1, sprintf('(n=%i)', i, n));
    xlabel('Stimulus Strength (PSI)', 'FontSize', 14)
    ylabel('Performance', 'FontSize', 14)
end
