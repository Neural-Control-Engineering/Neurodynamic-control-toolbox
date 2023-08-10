function avgEMABy(data, filterBy, filterValue, sortBy, t0, t1, base_path)
% average photometry data for all trials filtered by a particular feature using EMA.

    data = swapPhotometryChannels(data);
    data = filterTrials(data, filterBy, filterValue);
    colors = ['b', 'r', 'm', 'g', 'y', 'c'];
    fig = figure('Visible', 'on'); hold on;

    if strcmp(sortBy, 'outcome')
        outcome_types = unique(data.categorical_outcome);
        outdir = base_path;
        if ~exist(outdir, 'dir')
            mkdir(outdir)
        end
        for out_i = 1:length(outcome_types)
            outcome = outcome_types(out_i);
            data_outcome = filterTrials(data, 'categorical_outcome', outcome);
            Fs = 1 / (data_outcome.photometry_ch2{1,1}(2,1) - data_outcome.photometry_ch2{1,1}(1,1));
            ch1mat = zeros(size(data_outcome,1), round(Fs*2));
            ch2mat = ch1mat;

            for i = 1:size(data_outcome,1)
                ch1 = data_outcome.photometry_ch1{i,1}(:,2);
                ch2 = data_outcome.photometry_ch2{i,1}(:,2);
                t = data_outcome.photometry_ch1{i,1}(:,1) - data_outcome.stimulus_time(i);
                ch1 = ch1(t > t0 & t < t1);
                ch2 = ch2(t > t0 & t < t1);
                t = t(t > t0 & t < t1);

                try
                    ch1mat(i,:) = ch1;
                    ch2mat(i,:) = ch2;
                catch
                    ch1mat(i,:) = nan(1,size(ch1mat,2));
                    ch2mat(i,:) = nan(1,size(ch2mat,2));
                end
            end

            label = sprintf('%s (n=%i)', outcome, size(ch1mat,1));
            ema_ch1 = computeEMA(ch1mat, 21); % 21 is a sample EMA period, adjust as necessary
            ema_ch2 = computeEMA(ch2mat, 21);

            subplot(2,1,1)
            hold on
            semshade(ema_ch1, 0.3, colors(out_i), colors(out_i), t, [], label);

            subplot(2,1,2)
            hold on
            semshade(ema_ch2, 0.3, colors(out_i), colors(out_i), t, [], label);
        end
    elseif strcmp(sortBy, 'response')
        responses = [1,0];
        outcomes = {'go', 'no go'};
        outdir = base_path;
        if ~exist(outdir, 'dir')
            mkdir(outdir)
        end
        for out_i = 1:2
            outcome = outcomes{out_i};
            data_outcome = filterTrials(data, 'go-nogo', responses(out_i));
            Fs = 1 / (data_outcome.photometry_ch2{1,1}(2,1) - data_outcome.photometry_ch2{1,1}(1,1));
            ch1mat = zeros(size(data_outcome,1), round(Fs*2));
            ch2mat = ch1mat;

            for i = 1:size(data_outcome,1)
                ch1 = data_outcome.photometry_ch1{i,1}(:,2);
                ch2 = data_outcome.photometry_ch2{i,1}(:,2);
                t = data_outcome.photometry_ch1{i,1}(:,1) - data_outcome.stimulus_time(i);
                ch1 = ch1(t > t0 & t < t1);
                ch2 = ch2(t > t0 & t < t1);
                t = t(t > t0 & t < t1);

                try
                    ch1mat(i,:) = ch1;
                    ch2mat(i,:) = ch2;
                catch
                    ch1mat(i,:) = nan(1,size(ch1mat,2));
                    ch2mat(i,:) = nan(1,size(ch2mat,2));
                end
            end

            label = sprintf('%s (n=%i)', outcome, size(ch1mat,1));
            ema_ch1 = computeEMA(ch1mat, 21); 
            ema_ch2 = computeEMA(ch2mat, 21);

            subplot(2,1,1)
            hold on
            semshade(ema_ch1, 0.3, colors(out_i), colors(out_i), t, [], label);

            subplot(2,1,2)
            hold on
            semshade(ema_ch2, 0.3, colors(out_i), colors(out_i), t, [], label);
        end
    end

    subplot(2,1,1)
    n = strsplit(data.session_id(1), '-');
    animal = n(1);
    t = sprintf('%s - %s', animal, data.photometry_region_ch1{1});
    title(t)

    subplot(2,1,2)
    t = sprintf('%s - %s', animal, data.photometry_region_ch2{1});
    title(t)

%     fname = sprintf('%s%s.png', outdir, animal);
%     legend('Location', 'southwest')
%     saveas(fig, fname)
%     close()

end
