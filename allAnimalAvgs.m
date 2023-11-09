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
% justTargetsNE(data)

%% figures
% figure1(data)
% figure2(data)
% figure3(data)

xcorrs(data)

function xcorrs(data)
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    fig = figure('Position', [404,166,1252,766]);
    tl = tiledlayout(3,4,'TileSpacing','Compact');
    axs = zeros(3,4);
    for r  = 1:3
        for c = 1:4
            axs(r,c) = nexttile;
        end
    end
    tbounds = [-5.0, 0.0];
    for o = 1:length(outcomes)
        otmp = filterTrials(data, 'categorical_outcome', outcomes{o});
        [mpfc, s1, tp] = avg_photo_traces(otmp, tbounds, 'stimulus');
        [pupil, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], 'stimulus');
        Fs = getFs(data, 'photometry_ch1');
        Fs = Fs(1);
        cs = zeros(size(otmp,1), round(Fs*2*diff(tbounds)-5));
        lags = zeros(size(otmp,1), round(Fs*2*diff(tbounds)-5));
        mp = zeros(size(otmp,1), 97);
        sp = zeros(size(otmp,1), 97);
        ls = mp;
        for i = 1:size(mpfc,1)
            ch1 = mpfc(i,:);
            ch2 = s1(i,:);
            p = pupil(i,:);
            % mpfc x s1 
            [c, lag] = xcorr(ch1(2:end-1)-nanmean(ch1), ch2(2:end-1)-nanmean(ch2));
            try
                lags(i,:) = lag ./ Fs;
                cs(i,:) = c ./ length(ch1(2:end-1));
            catch
                lags(i,:) = nan(1, size(lags,2));
                cs(i,:) = nan(1,size(cs,2));
            end
            % mpfc x pupil
            x = decimate(mpfc(1,:), 12, 'fir');
            [c, lag] = xcorr(p(3:end-1), x(3:end-1));
            try
                ls(i,:) = lag ./ 12;
                mp(i,:) = c ./ length(p(3:end-1));
            catch
                ls(i,:) = nan(1, size(ls,2));
                mp(i,:) = nan(1,size(mp,2));
            end
            % s1 x pupil 
            x = decimate(s1(1,:), 12, 'fir');
            [c, ~] = xcorr(p(3:end-1), x(3:end-1));
            try
                sp(i,:) = c ./ length(p(3:end-1));
            catch
                sp(i,:) = nan(1,size(mp,2));
            end
        end
        axes(axs(1,o))
        hold on
        semshade(cs, 0.3, 'k', 'k', lags(1,:), 1);
        plot([0,0],[-0.6,0.6], 'k:', 'HandleVisibility','off')
        ylim([-0.06,0.06])
        xlim([-4,4])
        title(outcomes{o}, 'FontSize', 16)
        axes(axs(2,o))
        hold on
        semshade(mp, 0.3, 'k', 'k', ls(1,:), 1);
        plot([0,0],[-0.6,0.6], 'k:', 'HandleVisibility', 'off')
        ylim([-0.06,0.06])
        xlim([-4,4])
        axes(axs(3,o))
        hold on
        semshade(sp, 0.3, 'k', 'k', ls(1,:), 1);
        plot([0,0],[-0.6,0.6], 'k:', 'HandleVisibility', 'off')
        ylim([-0.06,0.06])
        xlim([-4,4])
    end
    axes(axs(1,1))
    ylabel('mPFC x S1', 'FontSize', 16)
    axes(axs(2,1))
    ylabel('mPFC x Pupil Area', 'FontSize', 16)
    axes(axs(3,1))
    ylabel('S1 x Pupil Area', 'FontSize', 16)
    xlabel(tl, 'Lag (s)', 'FontSize', 16)
    for r = 1:3
        for c = 2:4
            axes(axs(r,c))
            yticks([])
        end
    end
    for r = 1:2
        for c = 1:4
            axes(axs(r,c))
            xticks([])
        end
    end
    ylabel(tl, 'Normalized Cross Correlation', 'FontSize', 16)
    % for r = 1:3
    %     axes(axs(r,1))
    %     yticks([-0.5,0,0.5])
    %     yticklabels(['-0.5', '0', '0.5'])
    % end
end


function justTargetsNE(data)
    fig = figure();
    tl = tiledlayout(1,2,'TileSpacing','Compact');
    axs = zeros(1,2);
    otmp = filterTrials(data, 'categorical_outcome', 'Hit');
    mtmp = filterTrials(data, 'categorical_outcome', 'Miss');
    tbounds = [-1, 6.0];
    [ch1, ch2, tp] = avg_photo_traces(otmp, [tbounds(1), tbounds(2)], 'stimulus');
    [mch1, mch2, ~] = avg_photo_traces(mtmp, [tbounds(1), tbounds(2)], 'stimulus');
    axs(1) = nexttile;
    hold on
    try
        semshade(ch1(:,2:end-1), 0.3, 'b', 'b', ...
            tp(2:end-1), 1, 'Hit');
        % semshade(mch1(:,2:end-1), 0.3, 'r', 'r', ...
        %         tp(2:end-1), 1, 'Miss');
    catch
        semshade(ch1(:,2:end-1), 0.3, 'b', 'b', ...
            tp(2:end-1), 1);
    end
    xlim(tbounds)
    plot([0,0], [-0.5,0.6], 'k:', 'HandleVisibility', 'off')
    axs(2) = nexttile;
    hold on
    try
        semshade(ch2(:,2:end-1), 0.3, 'b', 'b', ...
            tp(2:end-1), 1, sprintf('Hits (n=%i)', size(ch2,1)));
        % semshade(mch2(:,2:end-1), 0.3, 'r', 'r', ...
        %     tp(2:end-1), 1, sprintf('Misses (n=%i)', size(mch2,1)));
    catch
        semshade(ch2(:,2:end-1), 0.3, 'b', 'k', ...
            tp(2:end-1), 1);
    end
    xlim(tbounds)
    plot([0,0], [-0.5,0.6], 'k:', 'HandleVisibility', 'off')
    axes(axs(1))
    ylabel('mPFC NE (z-score)', 'FontSize', 14)
    ylim([-0.1,0.6])
    axes(axs(2))
    ylabel('S1 NE (z-score)', 'FontSize', 14)
    ylim([-0.1,0.6])
    xlabel(tl, 'Time (s)', 'FontSize', 14)
    leg = legend();
end

function pupilAlignedToDistractor(data)
    [starts, durs] = distractorToNextStim(data);
    pupil = [];
    Fss = getFs(data, 'photometry_ch1');
    tbounds = [-0.5,6.0];
    pupil_time = linspace(-0.5, 6.0, round(max(Fss)*diff(tbounds)));
    pupil = [];
    for i = 1:length(durs)
        if durs(i) > 6.0
            tp = data.pupil_area{i,1}(:,1) - starts(i);
            p = data.pupil_area{i,1}(:,2);
            p = p(tp > tbounds(1)-0.1 & tp < tbounds(2)+0.1);
            tp = tp(tp > tbounds(1)-0.1 & tp < tbounds(2)+0.1);
            try
                pupil = [pupil; interp1(tp, p, pupil_time)];
            catch 
                pupil = [pupil; nan(size(pupil_time))];
            end
        end
    end
    fig2 = figure();
    hold on 
    semshade(pupil(:,2:end-1), 0.3, 'k', 'k', ...
                pupil_time(2:end-1), 1);
    plot([0,0], [-2,2], 'k:', 'HandleVisibility', 'off')
    xlabel('Time (s)', 'FontSize', 14)
    ylabel('Pupil Area (z-score)', 'FontSize', 14)
end

function neAlignToDistractor(data)
    [starts, durs] = distractorToNextStim(data);
    ch1mat = [];
    ch2mat = [];
    Fss = getFs(data, 'photometry_ch1');
    tbounds = [-0.5,6.0];
    time = linspace(-0.5, 6.0, round(max(Fss)*diff(tbounds)));
    Fss = getFs(data, 'pupil_area');
    for i = 1:length(durs)
        if durs(i) > 6.0
            t = data.photometry_ch1{i,1}(:,1) - starts(i);
            ch1 = data.photometry_ch1{i,1}(:,2);
            ch2 = data.photometry_ch2{i,1}(:,2);
            ch1 = ch1(t > tbounds(1) & t < tbounds(2));
            ch2 = ch2(t > tbounds(1) & t < tbounds(2));
            t = t(t > tbounds(1) & t < tbounds(2));
            % using interp1 to avoid issues with differing sample rates
            ch1mat = [ch1mat; interp1(t, ch1, time)];
            ch2mat = [ch2mat; interp1(t, ch2, time)];
        end
    end
    fig = figure();
    tl = tiledlayout(1,2,'TileSpacing','Compact')
    axs = zeros(1,2);
    axs(1) = nexttile;
    hold on
    semshade(ch1mat(:,2:end-1), 0.3, 'k', 'k', ...
                time(2:end-1), 1);
    ylabel('mPFC NE (z-score)', 'FontSize', 14)
    plot([0,0], [-2,2], 'k:', 'HandleVisibility', 'off')
    xlim([-0.1, 6.0])
    axs(2) = nexttile;
    hold on
    semshade(ch2mat(:,2:end-1), 0.3, 'k', 'k', ...
                time(2:end-1), 1);
    ylabel('S1 NE (z-score)', 'FontSize', 14)
    plot([0,0], [-2,2], 'k:', 'HandleVisibility', 'off')
    xlabel(tl, 'Time (s)', 'FontSize', 14)
    xlim([-0.1, 6.0])
end    

function figure1(data)
    example_traces(data)
    session = '243-R-mPFC-S1-NE_2023_01_09';
    lickRasterHist(data, session)
end

function figure3(data)
    tbounds = [-1, 1];
    neByReactionTime(data, tbounds, 'response')
    tbounds = [-0.5, 6.0];
    neByStimStrength(data, tbounds, 'stimulus')
    neByOutcome(data, tbounds, 'stimulus')
    baselineNeByOutcome(data)
    increaseInNE(data)
    neAlignToDistractor(data)
end

function figure2(data)
    pupilDilationByOutcome(data)
    baselinePupilByOutcome(data)
    avgPsychCurve(data)
    reactionTimeVsStimStrength(data)
    plotFirstLickHist(data)
    tbounds = [-0.5, 6.0];
    pupilByOutcome(data, tbounds, 'stimulus')
    pupilByStimStrength(data, tbounds, 'stimulus')
    tbounds = [-1, 1];
    pupilByReactionTime(data, tbounds, 'response')
    pupilAlignedToDistractor(data)
end

function [starts, durs] = distractorToNextStim(data)
    difs = zeros(1,size(data,1));
    durs = zeros(1,size(data,1));
    starts = zeros(1,size(data,1));
    for trial = 1:size(data,1)
        if ~isempty(data.distractor_times{trial,1})
            difs(trial) = data.stimulus_time(trial) - data.distractor_times{trial,1}(1);
        else
            difs(trial) = nan;
        end
        if ~isnan(difs(trial)) && difs(trial)>0
            stims = [data.stimulus_time(trial); data.distractor_times{trial,1}];
            stims = sort(stims);
            durs(trial) = stims(2)-stims(1);
            starts(trial) = data.distractor_times{trial,1}(1);
        else
            durs(trial) = nan;
            starts(trial) = nan;
        end
    end
end


function lickRasterHist(data, session)
    data = filterTrials(data, 'session_id', session);
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    fig = figure();
    tl = tiledlayout(2,length(outcomes),'TileSpacing','Compact');
    axs = zeros(2,length(outcomes));
    for r = 1:2
        for c = 1:length(outcomes)
            axs(r,c) = nexttile;
        end
    end
    for o = 1:length(outcomes)
        outcome = outcomes{o};
        tmp = filterTrials(data, 'categorical_outcome', outcome);
        axes(axs(1,o))
        hold on
        fill([-2,0,0,-2],[0,0,size(tmp,1),size(tmp,1)],'r', 'FaceAlpha', 0.3)
        fill([0,0.8,0.8,0],[0,0,size(tmp,1),size(tmp,1)],'g', 'FaceAlpha', 0.3)
        fill([0.8,2.0,2.0,0.8],[0,0,size(tmp,1),size(tmp,1)],'w', 'FaceAlpha', 0.3)
        binned_licks = zeros(1,10);
        highs = linspace(0.08,0.8,10);
        lows = linspace(0,0.72,10);
        for trial = 1:size(tmp,1)
            licks = tmp.lick_times{trial,1}-tmp.stimulus_time(trial);
            good_licks = licks(licks>0 & licks<=0.8);
            bad_licks = licks(licks<0 | licks>0.8);
            plot(good_licks, repmat(trial, 1, length(good_licks)), 'k.')
            plot(bad_licks, repmat(trial, 1, length(bad_licks)), '.', 'Color', [0.5,0.5,0.5])
            for i = 1:length(highs)
                binned_licks(i) = binned_licks(i) + length(good_licks(good_licks>=lows(i) & good_licks<=highs(i)));
            end
        end
        xlim([-2,2])
        ylim([0,size(tmp,1)])
        title(outcome, 'FontSize', 16)
        xticks([])
        axes(axs(2,o))
        hold on
        fill([-2,0,0,-2],[0,0,max(binned_licks)+10,max(binned_licks)+10],'r', 'FaceAlpha', 0.3)
        fill([0,0.8,0.8,0],[0,0,max(binned_licks)+10,max(binned_licks)+10],'g', 'FaceAlpha', 0.3)
        fill([0.8,2.0,2.0,0.8],[0,0,max(binned_licks)+10,max(binned_licks)+10],'w', 'FaceAlpha', 0.3)
        bar(highs-0.04, binned_licks, 'k')
        xlim([-2,2])
        ylim([0,max(binned_licks)+10])
        yticks([])
    end
    axes(axs(1,1))
    ylabel('Trial', 'FontSize', 14)
    axes(axs(2,1))
    ylabel('Binned Responses', 'FontSize', 14)
    xlabel(tl, 'Time (s)', 'FontSize', 14)
end

function example_traces(data)
    i = 900;
    distractors = data.distractor_times{i,1};
    stim_time = data.stimulus_time(i);
    licks = data.lick_times{i,1};
    mpfc = smooth(data.photometry_ch1{i,1}(:,2),60);
    s1 = smooth(data.photometry_ch2{i,1}(:,2),60);
    t = data.photometry_ch1{i,1}(:,1);
    distractors = distractors - min(t);
    stim_time = stim_time - min(t);
    licks = licks - min(t);
    t = t-min(t);
    mpfc = mpfc(t>4);
    s1 = s1(t>4);
    t = t(t>4);
    distractors = distractors - min(t);
    stim_time = stim_time - min(t);
    licks = licks - min(t);
    t = t-min(t);
    pupil = data.pupil_area{i,1}(:,2);
    tp = data.pupil_area{i,1}(:,1);
    tp = tp-min(tp);
    pupil = pupil(tp>4);
    tp = tp(tp>4);
    tp = tp-min(tp);
    fig = figure();
    % tl = tiledlayout(3,1,'TileSpacing', 'Compact');
    % axs = zeros(3,1);
    % axs(1) = nexttile;
    subplot(9,1,1)
    hold on
    for d = 1:length(distractors)
        distractor = distractors(d);
        if d == 1
            plot([distractor, distractor], [-1,1], 'g', 'DisplayName', 'Distractors', 'LineWidth',3)
        else
            plot([distractor, distractor], [-1,1], 'g', 'HandleVisibility', 'off', 'LineWidth',3)
        end
    end
    plot([stim_time, stim_time], [-1,1], 'k', 'DisplayName', 'True Stimulus', 'LineWidth',3)
    ylabel('Stimuli', 'FontSize', 14)
    xlim([0,50])
    xticks([])
    yticks([])
    leg = legend();
    subplot(9,1,2)
    hold on
    for d = 1:length(licks)
        lick = licks(d);
        plot([lick, lick], [-1,1], 'k', 'DisplayName', 'Distractors', 'LineWidth',0.5)
    end
    ylabel('Stimuli', 'FontSize', 14)
    xlim([0,50])
    xticks([])
    yticks([])
    % axs(2) = nexttile;
    subplot(3,1,2)
    plot(t, mpfc, 'b', 'DisplayName', 'mPFC NE')
    hold on
    plot(t, s1, 'r', 'DisplayName', 'S1 NE')
    ylabel('Cortical NE (z-score)', 'FontSize', 14)
    xlim([0,50])
    xticks([])
    leg = legend('location', 'southeast');
    % axs(3) = nexttile;
    subplot(3,1,3)
    plot(tp, pupil, 'k', 'LineWidth', 2)
    ylabel('Pupil Area (z-score)', 'FontSize', 14)
    xlabel('Time (s)', 'FontSize', 14)
    xlim([0,50])
    ylim([-2,2])
end

function increaseInNE(data)
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    mpfc = zeros(2,length(outcomes));
    s1 = mpfc;
    for o = 1:length(outcomes)
        outcome = outcomes{o};
        tmp = filterTrials(data, 'categorical_outcome', outcome);
        [ch1, ch2, ~] = avg_photo_traces(tmp, [0,4.0], 'stimulus');
        [ch1b, ch2b, ~] = avg_photo_traces(tmp, [-0.5,0.0], 'stimulus');
        mpfc(1,o) = nanmean(nanmean(ch1))-nanmean(nanmean(ch1b));
        mpfc(2,o) = nanstd(nanmean(ch1,2)-nanmean(ch1,2)) / size(ch1,1);
        s1(1,o) = nanmean(nanmean(ch2))-nanmean(nanmean(ch2b));
        s1(2,o) = nanstd(nanmean(ch2,2)-nanmean(ch2b,2)) / size(ch2,1);
    end
    action_outcomes = {{'Hit', 'FA'}, {'Miss', 'CR'}};
    action_mpfc = zeros(2,length(action_outcomes));
    action_s1 = action_mpfc;
    for ao = 1:length(action_outcomes)
        outcome = action_outcomes{ao};
        tmp = filterTrials(data, 'categorical_outcome', outcome);
        [ch1, ch2, ~] = avg_photo_traces(tmp, [0,6.0], 'stimulus');
        [ch1b, ch2b, ~] = avg_photo_traces(tmp, [-0.5,0.0], 'stimulus');
        action_mpfc(1,ao) = nanmean(nanmean(ch1))-nanmean(nanmean(ch1b));
        action_mpfc(2,ao) = nanstd(nanmean(ch1,2)-nanmean(ch1b,2)) / size(ch1,1);
        action_s1(1,ao) = nanmean(nanmean(ch2))-nanmean(nanmean(ch2b));
        action_s1(2,ao) = nanstd(nanmean(ch2,2)-nanmean(ch2b,2)) / size(ch2,1);
    end
    x = size(mpfc,2)+2:size(mpfc,2)+1+size(action_mpfc,2);
    fig = figure();
    fig.Position = [1308, 1301, 1405, 573];
    tl = tiledlayout(1,2,'TileSpacing','Compact');
    axs = zeros(1,2);
    axs(1) = nexttile;
    hold on
    errorbar(1:size(mpfc,2), mpfc(1,:), mpfc(2,:), 'k.')
    bar(1:size(mpfc,2), mpfc(1,:), 'k')
    errorbar(x, action_mpfc(1,:), action_mpfc(2,:), 'k.')
    bar(x, action_mpfc(1,:), 'k')
    xticks([1:size(mpfc,2), x])
    labels = [outcomes, {'Responded', 'Withheld'}];
    xticklabels(labels)
    xtickangle(45)
    ylabel('Mean Evoked mPFC NE (z-score)', 'FontSize', 14)
    axs(2) = nexttile;
    hold on
    errorbar(1:size(s1,2), s1(1,:), s1(2,:), 'k.')
    bar(1:size(s1,2), s1(1,:), 'k')
    errorbar(x, action_s1(1,:), action_s1(2,:), 'k.')
    bar(x, action_s1(1,:), 'k')
    xticks([1:size(s1,2), x])
    labels = [outcomes, {'Responded', 'Withheld'}];
    xticklabels(labels)
    xtickangle(45)
    ylabel('Mean Evoked S1 NE (z-score)', 'FontSize', 14)
end

function baselineNeByOutcome(data)
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    ch1b = zeros(2,length(outcomes));
    ch2b = zeros(2,length(outcomes));
    for o = 1:length(outcomes)
        outcome = outcomes{o};
        tmp = filterTrials(data, 'categorical_outcome', outcome);
        [ch1, ch2, ~] = avg_photo_traces(tmp, [-0.5,0.0], 'stimulus');
        ch1b(1,o) = nanmean(nanmean(ch1));
        ch1b(2,o) = nanstd(nanmean(ch1,2)) / size(ch1,1);
        ch2b(1,o) = nanmean(nanmean(ch2));
        ch2b(2,o) = nanstd(nanmean(ch2,2)) / size(ch2,1);
    end
    fig = figure();
    fig.Position = [1308, 1301, 1405, 573];
    tl = tiledlayout(1,2,'TileSpacing','Compact');
    axs = zeros(1,2);
    axs(1) = nexttile;
    hold on
    errorbar(1:size(ch1b,2), ch1b(1,:), ch1b(2,:), 'k.')
    bar(1:size(ch1b,2), ch1b(1,:), 'k')
    axs(2) = nexttile;
    hold on
    errorbar(1:size(ch2b,2), ch2b(1,:), ch2b(2,:), 'k.')
    bar(1:size(ch2b,2), ch2b(1,:), 'k')
    % action trials
    action_outcomes = {{'Hit', 'FA'}, {'Miss', 'CR'}};
    action_ch1b = zeros(2,length(action_outcomes));
    action_ch2b = zeros(2,length(action_outcomes));
    for ao = 1:length(action_outcomes)
        outcome = action_outcomes{ao};
        tmp = filterTrials(data, 'categorical_outcome', outcome);
        [ch1, ch2, ~] = avg_photo_traces(tmp, [-0.5,0.0], 'stimulus');
        action_ch1b(1,ao) = nanmean(nanmean(ch1));
        action_ch1b(2,ao) = nanstd(nanmean(ch1,2)) / size(ch1,1);
        action_ch2b(1,ao) = nanmean(nanmean(ch2));
        action_ch2b(2,ao) = nanstd(nanmean(ch2,2)) / size(ch2,1);
    end
    axes(axs(1))
    x = size(ch1b,2)+2:size(ch1b,2)+1+size(action_ch1b,2);
    errorbar(x, action_ch1b(1,:), action_ch1b(2,:), 'k.')
    bar(x, action_ch1b(1,:), 'k')
    xticks([1:size(ch1b,2), x])
    labels = [outcomes, {'Responded', 'Withheld'}];
    xticklabels(labels)
    xtickangle(45)
    ylabel('Mean Baseline mPFC NE (z-score)', 'FontSize', 14)
    axes(axs(2))
    x = size(ch2b,2)+2:size(ch2b,2)+1+size(action_ch2b,2);
    errorbar(x, action_ch2b(1,:), action_ch2b(2,:), 'k.')
    bar(x, action_ch2b(1,:), 'k')
    xticks([1:size(ch2b,2), x])
    labels = [outcomes, {'Responded', 'Withheld'}];
    xticklabels(labels)
    xtickangle(45)
    ylabel('Mean Baseline S1 NE (z-score)', 'FontSize', 14)
end    

function neByOutcome(data, tbounds, alignTo)
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    fig = figure('Visible', 'on', 'WindowState', 'maximized');
    if ~exist('alignTo', 'var')
        alignTo = 'stimulus';
    end
    axs = 1:length(outcomes);
    tl = tiledlayout(2,length(outcomes), 'TileSpacing', 'Compact');
    axs = zeros(2,length(outcomes));
    for r = 1:2
        for c = 1:length(outcomes)
            axs(r,c) = nexttile;
        end
    end
    for o = 1:length(outcomes)
        outcome = outcomes{o};
        otmp = filterTrials(data, 'categorical_outcome', outcome);
        [ch1, ch2, tp] = avg_photo_traces(otmp, [tbounds(1), tbounds(2)], alignTo);
        axes(axs(1,o));
        hold on
        try
            semshade(ch1(:,2:end-1), 0.3, 'k', 'k', ...
                tp(2:end-1), 1);
        catch
            semshade(ch1(:,2:end-1), 0.3, 'k', 'k', ...
                tp(2:end-1), 1);
        end
        title(outcome, 'FontSize', 16)
        xlim(tbounds)
        ylim([-0.5,0.6])
        plot([0,0], [-0.5,0.6], 'k:', 'HandleVisibility', 'off')
        axes(axs(2,o));
        hold on
        try
            semshade(ch2(:,2:end-1), 0.3, 'k', 'k', ...
                tp(2:end-1), 1);
        catch
            semshade(ch2(:,2:end-1), 0.3, 'k', 'k', ...
                tp(2:end-1), 1);
        end
        xlim(tbounds)
        ylim([-0.5,0.6])
        plot([0,0], [-0.5,0.6], 'k:', 'HandleVisibility', 'off')
    end
    axes(axs(1,1))
    ylabel('mPFC NE (z-score)', 'FontSize', 14)
    axes(axs(2,1))
    ylabel('S1 NE (z-score)', 'FontSize', 14)
    xlabel(tl, 'Time (s)', 'FontSize', 14)
end

function neByStimStrength(data, tbounds, alignTo)
    fig = figure('Visible', 'on', 'WindowState', 'maximized');
    if ~exist('alignTo', 'var')
        alignTo = 'stimulus';
    end
    stim_strengths = unique(data.stimulus_strength);
    if length(unique(data.categorical_outcome)) > 2
        outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    else
        outcomes = {'Hit', 'FA'};
    end
    cols = distinguishable_colors(length(stim_strengths)+1);
    tl = tiledlayout(2,length(outcomes), 'TileSpacing', 'Compact');
    axs = zeros(2,length(outcomes));
    for r = 1:2
        for c = 1:length(outcomes)
            axs(r,c) = nexttile;
        end
    end
    for o = 1:length(outcomes)
        outcome = outcomes{o};
        if ~strcmp(outcome,'Delayed FA (CR)') && ~strcmp(outcome, 'Near Hit (Miss)')
            tmp = filterTrials(data, 'categorical_outcome', outcome);
        else
            tmp = [];
        end
        if ~isempty(tmp)
            for i = 1:length(stim_strengths)
                stim = stim_strengths(i);
                otmp = filterTrials(tmp, 'stim_strength', stim);
                n = size(otmp,1);
                l = sprintf('%.1f PSI (n=%i)', stim*10, n);
                if ~isempty(otmp)
                    [ch1, ch2, tp] = avg_photo_traces(otmp, [tbounds(1), tbounds(2)], alignTo);
                    axes(axs(1,o));
                    hold on
                    try
                        semshade(ch1(:,2:end-1), 0.3, cols(i,:), cols(i,:), ...
                            tp(2:end-1), 1, l);
                    catch
                        semshade(ch1(:,2:end-1), 0.3, cols{i}, cols{i}, ...
                            tp(2:end-1), 1, l);
                    end
                    axes(axs(2,o));
                    hold on
                    try
                        semshade(ch2(:,2:end-1), 0.3, cols(i,:), cols(i,:), ...
                            tp(2:end-1), 1, l);
                    catch
                        semshade(ch2(:,2:end-1), 0.3, cols{i}, cols{i}, ...
                            tp(2:end-1), 1, l);
                    end
                end
            end
        end
    end
    xlabel(tl, 'Time (s)', 'FontSize', 14)   
    axes(axs(1,1))
    ylabel('mPFC NE', 'FontSize', 14)
    axes(axs(2,1))
    ylabel('S1 NE', 'FontSize', 14)
    for c = 1:length(outcomes)
        for r = 1:2
            axes(axs(r,c))
            xlim(tbounds)
            ylim([-0.4,0.9])
            plot([0,0], [-0.4,0.9], 'k:', 'HandleVisibility', 'off')
        end
        axes(axs(1,c))
        title(outcomes{c}, 'FontSize', 16)
        leg = legend();
        leg.Title.String = 'Stimulus Strength';
    end
end

function neByReactionTime(data, tbounds, alignTo)
    pos = [1308, 1301, 1405, 573];
    outcomes = 'Hit';
    data = filterTrials(data, 'categorical_outcome', outcomes);
    starts = data.stimulus_time + data.response_time;
    data(isnan(starts),:) = [];
    cols = distinguishable_colors(5);
    ptiles = 20:20:100;
    low = prctile(data.response_time, 0);
    fig = figure();
    fig.Position = pos;
    tl = tiledlayout(1,2);
    axs(1) = nexttile;
    axs(2) = nexttile;
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
        [ch1, ch2, tp] = avg_photo_traces(tmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
        n = size(ch1,1);
        axes(axs(1))
        hold on
        try
            semshade(ch1(:,2:end-1), 0.3, cols(i,:), cols(i,:), ...
                tp(2:end-1), 1, sprintf('%s (n=%i)', l, n));
        catch
            % keyboard
            semshade(ch1(:,2:end-1), 0.3, cols{i}, cols{i}, ...
                tp(2:end-1), 1, sprintf('%s (n=%i)', l, n));
        end
        axes(axs(2))
        hold on
        try
            semshade(ch2(:,2:end-1), 0.3, cols(i,:), cols(i,:), ...
                tp(2:end-1), 1, sprintf('%s (n=%i)', l, n));
        catch
            % keyboard
            semshade(ch2(:,2:end-1), 0.3, cols{i}, cols{i}, ...
                tp(2:end-1), 1, sprintf('%s (n=%i)', l, n));
        end
    end
    axes(axs(1))
    ylabel('mPFC NE (z-score)', 'FontSize', 14)
    xlim(tbounds)
    leg = legend('location', 'southeast');
    leg.Title.String = 'Response Time';
    ylim([-0.2, 0.7])
    plot([0,0], [-0.2, 0.7], 'k:', 'HandleVisibility', 'off')
    axes(axs(2))
    ylabel('S1 NE (z-score)', 'FontSize', 14)
    xlabel(tl, 'Time (s)', 'FontSize', 14)
    xlim(tbounds)
    ylim([-0.2, 0.7])
    plot([0,0], [-0.2, 0.7], 'k:', 'HandleVisibility', 'off')
end

function pupilByReactionTime(data, tbounds, alignTo)
    outcomes = 'Hit';
    data = filterTrials(data, 'categorical_outcome', outcomes);
    starts = data.stimulus_time + data.response_time;
    data(isnan(starts),:) = [];
    cols = distinguishable_colors(5);
    ptiles = 20:20:100;
    low = prctile(data.response_time, 0);
    figure();
    hold on
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
        [pupil, t] = avg_pupil_traces(tmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
        n = size(pupil,1);
        try
            semshade(pupil(:,2:end-1), 0.3, cols(i, :), cols(i, :), ...
                t(2:end-1), 1, sprintf('%s (n=%i)', l, n));
        catch
            % keyboard
            semshade(pupil(:,2:end-1), 0.3, cols{i}, cols{i}, ...
            t(2:end-1), 1, sprintf('%s (n=%i)', l, n));
        end
    end
    leg = legend('location', 'northwest');
    leg.Title.String = 'Response Time';
    xlabel('Time (s)', 'FontSize', 14)
    ylabel('Pupil Area (z-score)', 'FontSize', 14)
    xlim(tbounds)
    ylim([-0.5,0.5])
    plot([0,0], [-0.5,0.5], 'k:', 'HandleVisibility', 'off')
end

function pupilByOutcome(data, tbounds, alignTo)
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    fig = figure('Visible', 'on', 'WindowState', 'maximized');
    if ~exist('alignTo', 'var')
        alignTo = 'stimulus';
    end
    cols = distinguishable_colors(length(outcomes));
    axs = 1:length(outcomes);
    tl = tiledlayout(1,length(outcomes));
    for o = 1:length(outcomes)
        outcome = outcomes{o};
        otmp = filterTrials(data, 'categorical_outcome', outcome);
        [pupil, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
        axs(o) = nexttile;
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
        plot([0,0], [-0.6, 1.55], 'k:', 'HandleVisibility', 'off')
    end
    ylabel(tl, 'Pupil Area (z-score)', 'FontSize', 14)
    xlabel(tl, 'Time (s)', 'FontSize', 14)
end

function pupilByStimStrength(data, tbounds, alignTo)
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
    tl = tiledlayout(1,length(outcomes));
    axs = zeros(1,length(outcomes));
    lines = [];
    for o = 1:length(outcomes)
        axs(o) = nexttile;
        axis square
        hold on
        outcome = outcomes{o};
        if ~strcmp(outcome,'Delayed FA (CR)') && ~strcmp(outcome, 'Near Hit (Miss)')
            tmp = filterTrials(data, 'categorical_outcome', outcome);
        else
            tmp = [];
        end
        if ~isempty(tmp)
            for i = 1:length(stim_strengths)
                stim = stim_strengths(i);
                otmp = filterTrials(tmp, 'stim_strength', stim);
                n = size(otmp,1);
                l = sprintf('%.1f PSI (n=%i)', stim*10, n);
                if ~isempty(otmp)
                    [pupil, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
                    try
                        out = semshade(pupil(:,2:end-1), 0.3, cols(i,:), cols(i,:), ...
                            t(2:end-1), 1, l);
                    catch
                        % keyboard
                        semshade(pupil(:,2:end-1), 0.3, cols{i}, cols{i}, ...
                        t(2:end-1), 1, sprintf('%s (n=%i)', l, n));
                    end
                end
                ylim([-0.6, 1.55])
                xlim(tbounds)
                leg = legend();
                leg.Title.String = 'Stimulus Strength';
                plot([0,0], [-0.6, 1.55], 'k:', 'HandleVisibility', 'off')
                % leg.Layout.Tile = 'South';
            end
        end
        title(outcome, 'FontSize', 16)
    end
    ylabel(tl, 'Pupil Area (z-score)', 'FontSize', 14)
    xlabel(tl, 'Time (s)', 'FontSize', 14)   
    % leg.Title.FontSize = 12;
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
        dilations(2,o) = nanstd(nanmean(pupil,2)-nanmean(baseline,2)) / size(pupil,1);
    end
    figure()
    hold on
    errorbar(1:size(dilations,2), dilations(1,:), dilations(2,:), 'k.')
    bar(1:size(dilations,2), dilations(1,:), 'k')
    action_outcomes = {{'Hit', 'FA'}, {'Miss', 'CR'}};
    action_dilations = zeros(2,length(action_outcomes));
    for ao = 1:length(action_outcomes)
        outcome = action_outcomes{ao};
        tmp = filterTrials(data, 'categorical_outcome', outcome);
        [pupil, ~] = avg_pupil_traces(tmp, [0,6.0], 'stimulus');
        [baseline, ~] = avg_pupil_traces(tmp, [-0.5,0.0], 'stimulus');
        action_dilations(1,ao) = nanmean(nanmean(pupil))-nanmean(nanmean(baseline));
        action_dilations(2,ao) = nanstd(nanmean(pupil,2)-nanmean(baseline,2)) / size(pupil,1);
    end
    x = size(dilations,2)+2:size(dilations,2)+1+size(action_dilations,2);
    errorbar(x, action_dilations(1,:), action_dilations(2,:), 'k.')
    bar(x, action_dilations(1,:), 'k')
    xticks([1:size(dilations,2), x])
    labels = [outcomes, {'Responded', 'Withheld'}];
    xticklabels(labels)
    ylabel('Mean Pupil Dilation (z-score)')
end
        

function baselinePupilByOutcome(data)
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
    hold on
    errorbar(1:size(baselines,2), baselines(1,:), baselines(2,:), 'k.')
    bar(1:size(baselines,2), baselines(1,:), 'k')
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
    histogram(data.response_time, 20, 'FaceColor', 'k', 'EdgeColor', 'k')
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

