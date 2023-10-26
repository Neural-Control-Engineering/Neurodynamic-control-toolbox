% script for plotting physiology data based on states identified by glm-hmm
% Craig Kelley, NEC Lab, 8/25/23

data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
animals = fetchAnimals(data);
data(cellfun(@isempty, data.photometry_ch1),:) = [];
ssd_version = 'v2';
animals_v1 = [3316, 3258, 3133, 200, 199, 198, 197, 196, 180, 167, 152];
animals_v2 = [240, 241, 242, 243];
animals = animals_v2;
base_path = 'Analysis/session_avgs/';
cols = distinguishable_colors(8);

%% plot avg traces for hits aligned to response 
tbounds = [-0.5, 0.5];
for animal = animals 
    atmp = filterTrials(data, 'animal', num2str(animal));
    sessions = unique(atmp.session_id);
    out_path = sprintf('%s/align_to_response/%i/', base_path, animal);
    if ~exist(out_path, 'dir')
        mkdir(out_path);
    end
    for s = 1:length(sessions)
        session = sessions{s};
        tmp = filterTrials(atmp, 'session_id', session);
        fig = plotByOutcome(tmp, {'Hit'}, tbounds, cols, 'response');
        saveas(fig, sprintf('%s%s.png', out_path, session));
        saveas(fig, sprintf('%s%s.fig', out_path, session));
        saveas(fig, sprintf('%s%s.svg', out_path, session));
        close(fig);
    end
    fig = plotByOutcome(atmp, {'Hit'}, tbounds, cols, 'response');
    saveas(fig, sprintf('%s%i.png', out_path, animal));
    saveas(fig, sprintf('%s%i.fig', out_path, animal));
    saveas(fig, sprintf('%s%i.svg', out_path, animal));
    close(fig);
end

%% plot avg traces sorted by outcome and stimulus strength aligned to stimulus
tbounds = [-0.5, 1.0];
for animal = animals
    atmp = filterTrials(data, 'animal', num2str(animal));
    stim_strength = unique(atmp.stimulus_strength);
    outcomes = unique(atmp.categorical_outcome);
    sessions = unique(atmp.session_id);

    for s = 1:length(sessions)
        session = sessions{s}; 
        % plots for each session
        otmp = filterTrials(atmp, 'session_id', session);
        % plot by outcome 
        outcome_fig = plotByOutcome(otmp, outcomes, tbounds, cols);
        out_path = sprintf('%soutcome/%i/', base_path, animal);
        if ~exist(out_path, 'dir')
            mkdir(out_path);
        end
        subplot(3,1,1); title(strrep(session, '_', ' '));
        saveas(outcome_fig, sprintf('%s%s.png', out_path, session));
        saveas(outcome_fig, sprintf('%s%s.fig', out_path, session));
        saveas(outcome_fig, sprintf('%s%s.svg', out_path, session));
        close()
        % plot by stimulus strength 
        strength_fig = plotByStimStrength(otmp, stim_strength, tbounds, cols);
        out_path = sprintf('%sstim_strength/%i/', base_path, animal);
        if ~exist(out_path, 'dir')
            mkdir(out_path);
        end
        subplot(3,1,1); title(strrep(session, '_', ' '));
        saveas(strength_fig, sprintf('%s%s.png', out_path, session))
        saveas(strength_fig, sprintf('%s%s.fig', out_path, session))
        saveas(strength_fig, sprintf('%s%s.svg', out_path, session))
        close()
    end
    % avg by outcome for each animal 
    out_path = 'Analysis/animal_avgs/outcome/';
    if ~exist(out_path, 'dir')
        mkdir(out_path);
    end
    outcome_fig = plotByOutcome(atmp, outcomes, tbounds, cols);
    subplot(3,1,1); title(num2str(animal));
    saveas(outcome_fig, sprintf('%s%i.png', out_path, animal))
    saveas(outcome_fig, sprintf('%s%i.fig', out_path, animal))
    saveas(outcome_fig, sprintf('%s%i.svg', out_path, animal))
    close()
    % avg by stim strength for each animal 
    out_path = 'Analysis/animal_avgs/stim_strength/';
    if ~exist(out_path, 'dir')
        mkdir(out_path);
    end
    strength_fig = plotByStimStrength(atmp, stim_strength, tbounds, cols);
    subplot(3,1,1); title(num2str(animal));
    saveas(strength_fig, sprintf('%s%i.png', out_path, animal))
    saveas(strength_fig, sprintf('%s%i.fig', out_path, animal))
    saveas(strength_fig, sprintf('%s%i.svg', out_path, animal))
    close()
end

function fig = plotByStimStrength(data, strengths, tbounds, cols)
    fig = figure('Visible', 'off', 'WindowState', 'maximized');
    for i = 1:length(strengths)
        outcome = strengths(i) * 10;
        otmp = filterTrials(data, 'stim_strength', outcome);
        if ~isempty(otmp)
            [ch1, ch2, tp] = avg_photo_traces(otmp, tbounds);
            n = size(ch1,1);
            subplot(3,1,1)
            hold on 
            try
                semshade(ch1(:,2:end-1), 0.3, cols(i+1,:), cols(i+1,:), ...
                    tp(2:end-1), 1, sprintf('%.1f (n=%i)', outcome, n));
            catch
                % keyboard
                plot(tp, ch1, 'DisplayName', ...
                    sprintf('%.1f (n=%i)', outcome, n))
            end
            subplot(3,1,2)
            hold on 
            try
                semshade(ch2(:,2:end-1), 0.3, cols(i+1,:), cols(i+1,:), ...
                    tp(2:end-1), 1, sprintf('%.1f (n=%i)', outcome, n));
            catch
                % keyboard
                plot(tp, ch2, 'DisplayName', ...
                    sprintf('%.1f (n=%i)', outcome, n))
            end
            [pupil, t] = avg_pupil_traces(otmp, [-0.6, 1.1]);
            % keyboard
            subplot(3,1,3)
            hold on
            try
                semshade(pupil(:,2:end-1), 0.3, cols(i+1, :), cols(i+1, :), ...
                    t(2:end-1), 1, sprintf('%.1f (n=%i)', outcome, n));
            catch
                % keyboard
                plot(t, pupil, 'DisplayName', ...
                    sprintf('%.1f (n=%i)', outcome, n));
            end
        end
    end
    subplot(3,1,1)
    ylabel('NE mPFC')
    subplot(3,1,2)
    ylabel('NE S1')
    subplot(3,1,3)
    ylabel('Pupil Area')
    xlabel('Time (s)')
    legend('location', 'southeast')
end
    

function fig = plotByOutcome(data, outcomes, tbounds, cols, alignTo)
    fig = figure('Visible', 'off', 'WindowState', 'maximized');
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
            subplot(3,1,1)
            hold on 
            try
                semshade(ch1(:,2:end-1), 0.3, cols(i+1,:), cols(i+1,:), ...
                    tp(2:end-1), 1, sprintf('%s (n=%i)', outcome, n));
            catch
                % keyboard
                plot(tp, ch1, 'DisplayName', ...
                    sprintf('%s (n=%i)', outcome, n))
            end
            subplot(3,1,2)
            hold on 
            try
                semshade(ch2(:,2:end-1), 0.3, cols(i+1,:), cols(i+1,:), ...
                    tp(2:end-1), 1, sprintf('%s (n=%i)', outcome, n));
            catch
                % keyboard
                plot(tp, ch2, 'DisplayName', ...
                    sprintf('%s (n=%i)', outcome, n))
            end
            [pupil, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
            % keyboard
            subplot(3,1,3)
            hold on
            try
                semshade(pupil(:,2:end-1), 0.3, cols(i+1, :), cols(i+1, :), ...
                    t(2:end-1), 1, sprintf('%s (n=%i)', outcome, n));
            catch
                % keyboard
                plot(t, pupil, 'DisplayName', ...
                    sprintf('%s (n=%i)', outcome, n));
            end
        end
    end
    subplot(3,1,1)
    ylabel('NE mPFC')
    subplot(3,1,2)
    ylabel('NE S1')
    subplot(3,1,3)
    ylabel('Pupil Area')
    xlabel('Time (s)')
    legend('location', 'southeast')
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