function avgFftByOutcome(data, session_id)
    outdir = strcat('./FFTS/session_avgs/');
    mkdir(outdir);
    outcome_types = unique(data.categorical_outcome);
    fig = figure('Visible', 'off'); hold on;
    colors = ['b', 'r', 'm', 'g', 'y', 'c'];
    for out_i = 1:length(outcome_types)
        outcome = outcome_types(out_i);
        sesh_outcome = data(data.session_id == session_id & data.categorical_outcome == outcome, :);
        if ~isempty(sesh_outcome)
            photo = sesh_outcome.photometry_ch1;
            stim_times = sesh_outcome.stimulus_time;
            Fs = 1 / (photo{1,1}(2,1) - photo{1,1}(1,1));
            t = photo{1,1}(:,1)-stim_times(1);
            t = t(t > -2 & t < 0);
            n = 2^nextpow2(length(t));
            f = Fs*(0:(n/2))/n;
            Ys = zeros(size(sesh_outcome,1),length(f));
            for i = 1:size(photo,1)
                t = photo{i,1}(:,1)-stim_times(i);
                y = photo{i,1}((t > -2 & t < 0) ,2);
                Y = fft(y-mean(y), n);    
                Ys(i,:) = abs(Y(1:n/2+1));
            end
            
            % plot(f, mean(Ys, 1))
            label = sprintf('%s (n=%i)', outcome, size(Ys,1));
            if size(Ys,1) > 1
                semshade(Ys, 0.3, colors(out_i), colors(out_i), f, [], label);
            else
                plot(f, Ys, colors(out_i), 'DisplayName', label)
            end
        end
    end
    title(strrep(session_id, '_', '-'))
    t = strcat(outdir, session_id, '.png');
    legend()
    xlabel('Frequency (Hz)')
    ylabel('Power (mV^2)')
    saveas(fig, t)
    close()
end      

