function fig8b(data, k, data_ver, ssd_version, psychver, animals, shuff)
    ps = lumpByResponseProb(data_ver, ssd_version, psychver, animals, data, k, shuff);
    % fprintf('Pupil baseline by outcome / state:\n')
end

function ps = lumpByResponseProb(data_ver, ssd_version, psychver, animals, data, k, shuff)
    % set paths 
    fformat = {data_ver, 'state_Python2mat.mat'};
    base_path = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ssd_version, data_ver);
    outdir = strcat(base_path, 'figures/phys_by_state/', psychver, '/');
    if ~exist(outdir, 'dir')
        mkdir(outdir)
    end

    if startsWith(data_ver, 'behvaior') || startsWith(data_ver, 'last_trial')
        data = removeFirstTrials(data);
    end

    % for single number of states, get the states ordered by average response probability
    % in each state
    mrps = zeros(length(animals), k);
    ordered_states = mrps;
    for a = 1:length(animals)
        tmp = filterTrials(data, 'animal', num2str(animals(a)));
        filename = sprintf('%s%i_%s_%i%s', base_path, animals(a), fformat{1}, k, fformat{2});
        mrps(a,:) = meanResponseProb(filename, tmp, k);
        [~, inds] = sort(mrps(a,:));
        ordered_states(a,:) = inds - 1;
    end

    % average psychometric curves for each animal in each ordered state (starting with lowest)
    % figure('Position', [ 1151, 1516, 1830, 404])
    
    tbounds = [-4,0];
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    Fs = getFs(data, 'photometry_ch1');
    Fs = Fs(1);
    % pupil = {zeros(a,k), zeros(a,k), zeros(a,k), zeros(a,k)};
    ps = {};
    session_xcor = {[], [], [], []};
    for s = 1:k
        cols = distinguishable_colors(k);
        state_rp = [];
        for as = 1:size(ordered_states,1)
            i = ordered_states(as,s);
            filename = sprintf('%s%i_%s_%i%s', base_path, animals(as), fformat{1}, k, fformat{2});
            results = load(filename);
            stim_strengths = unique(data.stimulus_strength);
            rp = nan(1,length(stim_strengths));
            tmp = filterTrials(data, 'animal', num2str(animals(as)));
            statetmp = tmp(results.predicted_states == i,:);
            sessions = unique(statetmp.session_id);
            for ss = 1:length(sessions)
                tmp = filterTrials(statetmp, 'session_id', num2str(sessions(ss)));
                [mpfc, s1, t] = avg_photo_traces(tmp, tbounds, 'stimulus', ver);
                Fs = getFs(data, 'photometry_ch1');
                Fs = Fs(1);
                cs = zeros(size(tmp,1), length([tbounds(1):(1/Fs):tbounds(2)])*2-5);
                lags = zeros(size(tmp,1), length([tbounds(1):(1/Fs):tbounds(2)])*2-5);
                for i = 1:size(mpfc,1)
                    ch1 = mpfc(i,:);
                    ch2 = s1(i,:);
                    % mpfc x s1 
                    [c, lag] = xcorr(ch1(2:end-1), ch2(2:end-1), 'normalized');
                    try
                        lags(i,:) = lag ./ Fs;
                        cs(i,:) = c; % ./ length(ch1(2:end-1));
                    catch
                        lags(i,:) = nan(1, size(lags,2));
                        cs(i,:) = nan(1,size(cs,2));
                    end
                end
                if size(cs,1) > 1
                    try
                        session_xcor{s} = [session_xcor{s}; nanmean(cs)];
                    catch
                        keyboard 
                    end
                else
                    session_xcor{s} = [session_xcor{s}; cs];
                end
            end
        end
    end
    figure(); hold on;
    lags = linspace(tbounds(1), tbounds(1)*-1, size(session_xcor{s},2));
    ind = find(lags == 0);
    corrs = {};
    for s = 1:k 
        mat = session_xcor{s} - nanmean(shuff);
        mat = mat(:,ind);
        plot(zeros(1,length(mat))+(s-1)+(rand(size(mat))-0.5)*0.3, mat, 'o', 'MarkerEdgeColor', [1,1,1], 'MarkerFaceColor', cols(s,:), 'MarkerSize', 5)
        corrs{s} = mat;
    end
    errorbar(0:(k-1), cellfun(@mean, corrs), cellfun(@ste, corrs), 'k.', 'CapSize', 15, 'LineWidth', 2)
    xlabel('HMM State', 'FontSize', 16)
    ylabel({'Shuffle Corrected Cross Correlation', 'at 0s Lag'})
    ylim([-0.2, 0.7])
    yticks([-0.2, 0.7])
    xticks(0:(k-1))
end
            % if ~isempty(statetmp)
            %     for o = 1:length(outcomes)
            %         otmp = filterTrials(statetmp, 'categorical_outcome', outcomes{o});
            %         if ~isempty(otmp)
            %             [mpfc, s1, ~] = avg_photo_traces(otmp, tbounds, 'stimulus','z-score');
            %             keyboard 
            %             Fs = getFs(data, 'photometry_ch1');
            %             Fs = Fs(1);
            %             cs = zeros(size(tmp,1), length([tbounds(1):(1/Fs):tbounds(2)])*2-5);
            %             lags = zeros(size(tmp,1), length([tbounds(1):(1/Fs):tbounds(2)])*2-5);
            %             for i = 1:size(mpfc,1)
            %                 ch1 = mpfc(i,:);
            %                 ch2 = s1(i,:);
            %                 % mpfc x s1 
            %                 [c, lag] = xcorr(ch1(2:end-1), ch2(2:end-1));%, 'normalized');
            %                 try
            %                     lags(i,:) = lag ./ Fs;
            %                     cs(i,:) = c; % ./ length(ch1(2:end-1));
            %                 catch
            %                     lags(i,:) = nan(1, size(lags,2));
            %                     cs(i,:) = nan(1,size(cs,2));
            %                 end
            %             end
            %             if size(cs,1) > 1
            %                 session_xcor{o} = [session_xcor{o}; nanmean(cs)];
            %             else
            %                 session_xcor{o} = [session_xcor{o}; cs];
            %             end
            %         end
            %     end
            % end
        % end
    %     for i = 1:length(session_xcor)
    %         axes(axs(i))
    %         semshade(session_xcor{i}, 0.3, cols(s,:), cols(s,:), lags(1,:), 1)
    %     end
    % end
    % ylabel(tl, {'NE_{mPFC} x NE_{S1}', 'Shuffle Corrected Cross Correlation'}, 'FontSize', 16)
    % xlabel(tl, 'Lag (s)', 'FontSize', 16)
    % outcomes{3} = 'Correct Rejection';
    % outcomes{4} = 'False Alarm';
    % for i = 1:length(outcomes)
    %     axes(axs(i))
    %     title(outcomes{i}, 'FontSize', 16, 'FontWeight', 'normal')
    % end
    % unifyYLimits(fig)
    
    % for o = 1:length(outcomes)
    %     axes(axs(o))
    %     hold on
    %     avg = zeros(1,length(size(pupil{o},1)));
    %     err = zeros(1,length(size(pupil{o},1)));
    %     for c = 1:length(ps{o})
    %         avg(c) = nanmean(ps{o}{c});
    %         err(c) = nanstd(ps{o}{c}) / sqrt(sum(~isnan(ps{o}{c})));
    %     end
    %     errorbar([0:3], avg, err, 'k.')
    %     hold on
    %     bar([0:3], avg, 'EdgeColor', 'k', 'FaceColor', 'k')
    %     xticks([0:3])
    %     title(ttls{o})
    % end
    % xlabel(tl, 'States', 'FontSize', 16)
    % ylabel(tl, '\Delta NE_{S1} (z-score)', 'FontSize', 16)
    % subplot(1,4,1)
    % xlabel('Stimulus Strength (PSI)')
    % ylabel('Response Probability')
    % subplot(1,4,2)
    % xlim(tbounds)
    % ylabel('NE_{mPFC} (z-score)')
    % subplot(1,4,3)
    % xlim(tbounds)
    % xlabel('Time (s)')
    % ylabel('NE_{S1} (z-score)')
    % subplot(1,4,4)
    % xlim(tbounds)
    % ttls = {'Hit', 'Miss', 'Correct Rejection', 'False Alarm'};
    % for o = 1:length(outcomes)
    %     axes(axs(o))
    %     title(ttls{o}, 'FontSize', 16)
    %     ylim([-1,2])
    % end
    
    % ylabel(tl,'Pupil Area (z-score)', 'FontSize', 16)
    % % ylim([-0.3,0.4])
    % xlabel(tl, 'Time (s)', 'FontSize', 16)
    % axes(axs(1))
    % legend()
    % leg = legend()
    % title(leg, 'HMM State', 'FontSize', 16)
% end

function data = removeFirstTrials(data)
    sessions = unique(data.session_id);
    first_trials = zeros(1,length(sessions));
    for s = 1:length(sessions)
        session = sessions{s};
        trials = find(data.session_id == session);
        first_trials(s) = min(trials);
    end
    data(first_trials, :) = [];
end

function mpb = pupilBaseline(filename, data, k)
    results = load(filename);
    states = 0:k-1;
    mpb = zeros(1,length(states));
    for i = states
        tmp = data(results.predicted_states == i,:);
        if ~isempty(tmp)
            [pupil, ~] = avg_pupil_traces(tmp, [-0.5, 0], 'stimulus');
            pupil = nanmean(nanmean(pupil, 2));
            mpb(i+1) = pupil;
        end
    end     
end

function rps = responseProbSlope(filename, data, k)
    results = load(filename);
    states = 0:k-1;
    stim_strengths = unique(data.stimulus_strength);
    rps = zeros(1,length(states));
    cols = distinguishable_colors(length(states));
    % figure()
    for i = states
        rp = nan(1,length(stim_strengths));
        tmp = data(results.predicted_states == i,:);
        if ~isempty(tmp)
            tmp_strengths = unique(tmp.stimulus_strength);
            for ss = 1:length(tmp_strengths)
                sstmp = filterTrials(tmp, 'stim_strength', tmp_strengths(ss));
                if tmp_strengths(ss)
                    rtmp = filterTrials(sstmp, 'categorical_outcome', 'Hit');
                else
                    rtmp = filterTrials(sstmp, 'categorical_outcome', 'FA');
                end
                ind = find(stim_strengths == tmp_strengths(ss));
                rp(ind) = size(rtmp,1) / size(sstmp,1);
            end
        end
        % plot(stim_strengths.*10, rp, '*-', 'Color', cols(i+1,:))
        % hold on
        [p, ~] = polyfit(stim_strengths(1:5), rp(1:5), 1);
        rps(i+1) = p(1);
    end
end

function mrp = meanResponseProb(filename, data, k)
    results = load(filename);
    states = 0:k-1;
    stim_strengths = unique(data.stimulus_strength);
    mrp = zeros(1,length(states));
    cols = distinguishable_colors(length(states));
    % figure()
    for i = states
        rp = nan(1,length(stim_strengths));
        tmp = data(results.predicted_states == i,:);
        if ~isempty(tmp)
            tmp_strengths = unique(tmp.stimulus_strength);
            for ss = 1:length(tmp_strengths)
                sstmp = filterTrials(tmp, 'stim_strength', tmp_strengths(ss));
                if tmp_strengths(ss)
                    rtmp = filterTrials(sstmp, 'categorical_outcome', 'Hit');
                else
                    rtmp = filterTrials(sstmp, 'categorical_outcome', 'FA');
                end
                ind = find(stim_strengths == tmp_strengths(ss));
                rp(ind) = size(rtmp,1) / size(sstmp,1);
            end
            % plot(stim_strengths.*10, rp, 'Color', cols(i+1,:))
            % hold on
        end
        mrp(i+1) = nanmean(rp);
    end
end
