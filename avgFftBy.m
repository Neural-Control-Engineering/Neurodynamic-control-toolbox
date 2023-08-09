function avgFftBy(data, filterBy, filterValue, sortBy, t0, t1, outdir)
% average FFTs of photometry data for all trials filter by a particular feature.
%   Example: avgFftBy(data, 'animal', '197', 'response')
% would plot average FFTs of photometry traces for animal 197 sorted by go
% or no go (rather than categorical outcome).
% Craig Kelley, NEC Lab, 8/7/23

    data = swapPhotometryChannels(data);
    fig = figure('Visible', 'off'); hold on;
    colors = ['b', 'r', 'm', 'g', 'y', 'c'];
    data = filterTrials(data, filterBy, filterValue);
    
    if strcmp(sortBy, 'outcome')
        outcome_types = unique(data.categorical_outcome);
        if ~exist(outdir, 'dir')
            mkdir(outdir)
        end
        for out_i = 1:length(outcome_types)
            outcome = outcome_types(out_i);
            sesh_outcome = filterTrials(data, 'categorical_outcome', outcome);
            if ~isempty(sesh_outcome)
                photo = sesh_outcome.photometry_ch1;
                photo2 = sesh_outcome.photometry_ch2;
                stim_times = sesh_outcome.stimulus_time;
                Fs = 1 / (photo{1,1}(2,1) - photo{1,1}(1,1));
                t = photo{1,1}(:,1)-stim_times(1);
                t = t(t > -2 & t < 0);
                n = 2^nextpow2(length(t));
                f = Fs*(0:(n/2))/n;
                Ys = zeros(size(sesh_outcome,1),length(f));
                Ys2 = zeros(size(sesh_outcome,1),length(f));
                for i = 1:size(photo,1)
                    t = photo{i,1}(:,1)-stim_times(i);
                    y = photo{i,1}((t > t0 & t < t1) ,2);
                    y2 = photo2{i,1}((t > t0 & t < t1) ,2);
                    Y = fft(y-mean(y), n);    
                    Y2 = fft(y2-mean(y2), n);
                    Ys(i,:) = abs(Y(1:n/2+1));
                    Ys2(i,:) = abs(Y2(1:n/2+1));
                end                
                % plot(f, mean(Ys, 1))
                label = sprintf('%s (n=%i)', outcome, size(Ys,1));
                if size(Ys,1) > 1
                    subplot(2,1,1); hold on;
                    semshade(Ys, 0.3, colors(out_i), colors(out_i), f, [], label);
                    subplot(2,1,2); hold on;
                    semshade(Ys2, 0.3, colors(out_i), colors(out_i), f, [], label);
                else
                    subplot(2,1,2); hold on;
                    plot(f, Ys, colors(out_i), 'DisplayName', label)
                    plot(f, Ys2, colors(out_i), 'DisplayName', label)
                end
            end
        end
    elseif strcmp(sortBy, 'response')
        responses = [1,0];
        outcomes = {'go', 'no go'};
        if ~exist(outdir, 'dir')
            mkdir(outdir)
        end
        for out_i = 1:length(outcomes)
            outcome = outcomes(out_i);
            sesh_outcome = filterTrials(data, 'go-nogo', responses(out_i));
            if ~isempty(sesh_outcome)
                photo = sesh_outcome.photometry_ch1;
                photo2 = sesh_outcome.photometry_ch2;
                stim_times = sesh_outcome.stimulus_time;
                Fs = 1 / (photo{1,1}(2,1) - photo{1,1}(1,1));
                t = photo{1,1}(:,1)-stim_times(1);
                t = t(t > -2 & t < 0);
                n = 2^nextpow2(length(t));
                f = Fs*(0:(n/2))/n;
                Ys = zeros(size(sesh_outcome,1),length(f));
                Ys2 = zeros(size(sesh_outcome,1),length(f));
                for i = 1:size(photo,1)
                    t = photo{i,1}(:,1)-stim_times(i);
                    y = photo{i,1}((t > t0 & t < t1) ,2);
                    y2 = photo2{i,1}((t > t0 & t < t1) ,2);
                    Y = fft(y-mean(y), n);    
                    Y2 = fft(y2-mean(y2), n);
                    Ys(i,:) = abs(Y(1:n/2+1));
                    Ys2(i,:) = abs(Y2(1:n/2+1));
                end
                
                % plot(f, mean(Ys, 1))
                label = sprintf('%s (n=%i)', num2str(cell2mat(outcome)), size(Ys,1));
                if size(Ys,1) > 1
                    subplot(2,1,1); hold on;
                    semshade(Ys, 0.3, colors(out_i), colors(out_i), f, [], label);
                    subplot(2,1,2); hold on; 
                    semshade(Ys2, 0.3, colors(out_i), colors(out_i), f, [], label);
                else
                    subplot(2,1,1); hold on;
                    plot(f, Ys, colors(out_i), 'DisplayName', label)
                    subplot(2,1,2); hold on;
                    plot(f, Ys2, colors(out_i))
                end
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
    subplot(2,1,2)
    legend()
    xlabel('Frequency (Hz)')
    ylabel('Power (mV^2)')
    xlim([0,20])
    subplot(2,1,2)
    xlabel('Frequency (Hz)')
    ylabel('Power (mV^2)')
    xlim([0,20])
    saveas(fig, fname)
    close()
end      

