function avgTracesBy(data, filterBy, filterValue, sortBy, alignTo, tbounds, outdir)
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

    if ~exist(outdir, 'dir')
        mkdir(outdir)
    end

    if strcmp(sortBy, 'outcome')
        outcome_types = unique(data.categorical_outcome);
        
        for out_i = 1:length(outcome_types)
            % loop over possible outcomes 
            outcome = outcome_types(out_i);
            data_outcome  = filterTrials(data, 'categorical_outcome', outcome);
            % Fs = 1 / (data_outcome.photometry_ch2{1,1}(2,1) - data_outcome.photometry_ch2{1,1}(1,1));
            Fss = getFs(data_outcome);
            ch1mat = zeros(size(data_outcome,1), round(max(Fss)*diff(tbounds)));
            ch2mat = ch1mat;

            % determine alignments 
            if strcmp(alignTo, 'stimulus_time')
                starts = data_outcome.stimulus_time;
            elseif strcmp(alignTo, 'response_time')
                starts = data_outcome.stimulus_time + data_outcome.response_time;
            end

            if ~isempty(data_outcome)
                for i = 1:size(data_outcome,1)
                    if Fss(i) == max(Fss)
                        ch1 = data_outcome.photometry_ch1{i,1}(:,2);
                        ch2 = data_outcome.photometry_ch2{i,1}(:,2);
                        % just two seconds prior to stimulus 
                        t = data_outcome.photometry_ch1{i,1}(:,1) - starts(i);
                        ch1 = ch1(t > tbounds(1) & t < tbounds(2));
                        ch2 = ch2(t > tbounds(1) & t < tbounds(2));
                        t = t(t > tbounds(1) & t < tbounds(2));
                        ch1mat(i,:) = ch1;
                        ch2mat(i,:) = ch2;
                    else
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
        
        for out_i = 1:2
            outcome = outcomes{out_i};
            data_outcome = filterTrials(data, 'go-nogo', responses(out_i));
            % Fs = 1 / (data_outcome.photometry_ch2{1,1}(2,1) - data_outcome.photometry_ch2{1,1}(1,1));
            Fss = getFs(data_outcome);
            ch1mat = zeros(size(data_outcome,1), round(max(Fss)*diff(tbounds)));
            ch2mat = ch1mat;

            % determine alignments 
            if strcmp(alignTo, 'stimulus_time')
                starts = data_outcome.stimulus_time;
            elseif strcmp(alignTo, 'response_time')
                starts = data_outcome.stimulus_time + data_outcome.response_time;
            end

            if ~isempty(data_outcome)
                for i = 1:size(data_outcome,1)
                    if Fss(i) == max(Fss)
                        ch1 = data_outcome.photometry_ch1{i,1}(:,2);
                        ch2 = data_outcome.photometry_ch2{i,1}(:,2);
                        % just two seconds prior to stimulus 
                        t = data_outcome.photometry_ch1{i,1}(:,1) - starts(i);
                        ch1 = ch1(t > tbounds(1) & t < tbounds(2));
                        ch2 = ch2(t > tbounds(1) & t < tbounds(2));
                        t = t(t > tbounds(1) & t < tbounds(2));
                        ch1mat(i,:) = ch1;
                        ch2mat(i,:) = ch2;
                    else
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
    n = strsplit(data.session_id(1), '-');
    animal = n(1);
    t = sprintf('%s - %s', animal, data.photometry_region_ch1{1});
    title(t)
    subplot(2,1,2)
    t = sprintf('%s - %s', animal, data.photometry_region_ch2{1});
    title(t)
    fname = sprintf('%s%s.png', outdir, animal);
    legend('Location', 'southwest')
    saveas(fig, fname)
    close()
end
                    