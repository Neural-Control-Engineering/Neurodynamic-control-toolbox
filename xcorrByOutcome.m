function xcorrByOutcome(data, session_id)
    
    % clean data and reduce to just one session 
    data = swapPhotometryChannels(data);
    data = data(data.session_id == session_id,:);

    % identify range of outcomes + boilerplate
    outcome_types = unique(data.categorical_outcome);
    colors = ['b', 'r', 'm', 'g', 'y', 'c'];
    outdir = './Xcorrs/session_avgs/';
    mkdir(outdir)
    fig = figure('Visible', 'off'); hold on;

    for out_i = 1:length(outcome_types)
        % loop over possible outcomes 
        outcome = outcome_types(out_i);
        data_outcome  = data(data.categorical_outcome == outcome, :);
        if ~isempty(data_outcome)
            % allocate space for corrs and lags 
            Fs = 1 / (data_outcome.photometry_ch1{1,1}(2,1) - data_outcome.photometry_ch1{1,1}(1,1));
            cs = zeros(size(data_outcome,1), round(Fs*4-1));
            lags = zeros(size(data_outcome,1), round(Fs*4-1));
            % compute xcorr for each trial
            for i = 1:size(data_outcome,1)
                ch1 = data_outcome.photometry_ch1{i,1}(:,2);
                ch2 = data_outcome.photometry_ch2{i,1}(:,2);
                % just two seconds prior to stimulus 
                t = data_outcome.photometry_ch1{i,1}(:,1) - data_outcome.stimulus_time(i);
                ch1 = ch1(t < 0 & t > -2);
                ch2 = ch2(t < 0 & t > -2);
                [c, lag] = xcorr(ch1-mean(ch1), ch2-mean(ch2));
                try
                    lags(i,:) = lag ./ Fs;
                    cs(i,:) = c;
                catch
                    lags(i,:) = nan(1, size(lags,2));
                    cs(i,:) = nan(1,size(cs,2));
                end
            end
        end
        % mean + sem for those outcomes with multiple trials, just plot otherwise 
        label = sprintf('%s (n=%i)', outcome, size(lags,1));
        if size(lags,1) > 1
            semshade(cs, 0.3, colors(out_i), colors(out_i), lags(1,:), [], label);
        else
            plot(lags, cs, colors(out_i), 'DisplayName', label)
        end
    end
    t = sprintf('%s %s-%s', strrep(session_id, '_', '-'), data.photometry_region_ch1{1}, data.photometry_region_ch2{1});
    title(t)
    fname = sprintf('%s%s.png', outdir, session_id);
    legend()
    xlabel('Lags (s)')
    ylabel('Xcorr')
    saveas(fig, fname)
    close()

end

