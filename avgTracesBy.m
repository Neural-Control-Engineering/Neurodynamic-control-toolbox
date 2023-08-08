function avgTracesBy(data, filterBy, filterValue, sortBy)
% average photometry data for all trials filtered by a particular feature. 
%   Example: avgTracesBy(data, 'animal', '109', 'outcome')
% would plot average photometry traces for animal 109 sorted by categorical
% outcome, rather than e.g. response (go/no go).
% Craig Kelley, NEC Lab, 8/7/23
%     TODO: hadle one or two channels (right now just two)


    data = swapPhotometryChannels(data);
    data = filterTrials(data, filterBy, filterValue);
    colors = ['b', 'r', 'm', 'g', 'y', 'c'];
    fig = figure('Visible', 'off'); hold on;

    if strcmp(sortBy, 'outcome')
        outcome_types = unique(data.categorical_outcome);
        outdir = sprintf('./avgTraces/%s_avgs-by-outcome/', filterBy);
        mkdir(outdir)
        for out_i = 1:length(outcome_types)
            % loop over possible outcomes 
            outcome = outcome_types(out_i);
            data_outcome  = filterTrials(data, 'categorical_outcome', outcome);
            Fs = 1 / (data_outcome.photometry_ch2{1,1}(2,1) - data_outcome.photometry_ch2{1,1}(1,1));
            ch1mat = zeros(size(data_outcome,1), round(Fs*2));
            ch2mat = ch1mat;
            if ~isempty(data_outcome)
                for i = 1:size(data_outcome,1)
                    ch1 = data_outcome.photometry_ch1{i,1}(:,2);
                    ch2 = data_outcome.photometry_ch2{i,1}(:,2);
                    % just two seconds prior to stimulus 
                    t = data_outcome.photometry_ch1{i,1}(:,1) - data_outcome.stimulus_time(i);
                    ch1 = ch1(t < 0 & t > -2);
                    ch2 = ch2(t < 0 & t > -2);
                    t = t(t < 0 & t > -2);
                    try
                        ch1mat(i,:) = ch1;
                        ch2mat(i,:) = ch2;
                    catch
                        ch1mat(i,:) = nan(1,size(ch1mat,2));
                        ch2mat(i,:) = nan(1,size(ch2mat,2));
                    end
                end
            end
            label = sprintf('%s (n=%i)', outcome, size(ch1mat,1));
            if size(ch1mat,1) > 1
                subplot(2,1,1)
                hold on
                semshade(ch1mat, 0.3, colors(out_i), colors(out_i), t, [], label);
                subplot(2,1,2)
                hold on
                semshade(ch2mat, 0.3, colors(out_i), colors(out_i), t, [], label);
            else
                subplot(2,1,1)
                hold on
                plot(t, ch1mat, colors(out_i), 'DisplayName', label)
                subplot(2,1,2)
                hold on
                plot(t, ch2mat, colors(out_i), 'DisplayName', label)
            end
        end
    elseif strcmp(sortBy, 'response')
        responses = [1,0];
        outcomes = {'go', 'no go'};
        outdir = sprintf('./avgTraces/%s_avgs-by-response/', filterBy);
        mkdir(outdir)
        for out_i = 1:2
            outcome = outcomes{out_i};
            data_outcome = filterTrials(data, 'go-nogo', responses(out_i));
            Fs = 1 / (data_outcome.photometry_ch2{1,1}(2,1) - data_outcome.photometry_ch2{1,1}(1,1));
            ch1mat = zeros(size(data_outcome,1), round(Fs*2));
            ch2mat = ch1mat;
            if ~isempty(data_outcome)
                for i = 1:size(data_outcome,1)
                    ch1 = data_outcome.photometry_ch1{i,1}(:,2);
                    ch2 = data_outcome.photometry_ch2{i,1}(:,2);
                    % just two seconds prior to stimulus 
                    t = data_outcome.photometry_ch1{i,1}(:,1) - data_outcome.stimulus_time(i);
                    ch1 = ch1(t < 0 & t > -2);
                    ch2 = ch2(t < 0 & t > -2);
                    t = t(t < 0 & t > -2);
                    try
                        ch1mat(i,:) = ch1;
                        ch2mat(i,:) = ch2;
                    catch
                        ch1mat(i,:) = nan(1,size(ch1mat,2));
                        ch2mat(i,:) = nan(1,size(ch2mat,2));
                    end
                end
            end
            label = sprintf('%s (n=%i)', outcome, size(ch1mat,1));
            if size(ch1mat,1) > 1
                subplot(2,1,1)
                hold on
                semshade(ch1mat, 0.3, colors(out_i), colors(out_i), t, [], label);
                subplot(2,1,2)
                hold on
                semshade(ch2mat, 0.3, colors(out_i), colors(out_i), t, [], label);
            else
                subplot(2,1,1)
                hold on
                plot(t, ch1mat, colors(out_i), 'DisplayName', label)
                subplot(2,1,2)
                hold on
                plot(t, ch2mat, colors(out_i), 'DisplayName', label)
            end
        end
    end
    subplot(2,1,1)
    t = sprintf('%s %s-%s', strrep(filterValue, '_', '-'), data.photometry_region_ch1{1}, data.photometry_region_ch2{1});
    title(t)
    fname = sprintf('%s%s.png', outdir, filterValue);
    legend('Location', 'southwest')
    saveas(fig, fname)
    close()
end
                    