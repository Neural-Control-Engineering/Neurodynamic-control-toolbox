function plotNEfftsAllTrials(data, session_id) 
    % place to save figs 
    outdir = strcat('./FFTS/', session_id, '_ffts/single_trials/');
    mkdir(outdir);
    sesh_inds = data.session_id == session_id;
    photo = data.photometry_ch1(sesh_inds);
    stim_times = data.stimulus_time(sesh_inds);
    Fs = 1 / (photo{1,1}(2,1) - photo{1,1}(1,1));
    session_ids = data.session_id;
    outcomes = data.categorical_outcome;
    parfor i = 1:size(photo,1)
        t = photo{i,1}(:,1)-stim_times(i);
        y = photo{i,1}((t > -2 & t < 0) ,2);
        n = 2^nextpow2(length(y));
        Y = abs(fft(y-mean(y), n));
        f = Fs*(0:(n/2))/n;
        fig = figure('Visible', 'off');
        plot(f,abs(Y(1:n/2+1)))
        t = sprintf('%s, trial %i: %s', session_ids(i), i, outcomes(i))
        t = strrep(t, '_', '-')
        title(t)
        xlabel('Frequency (Hz)')
        ylabel('Power (mv^2')
        saveas(fig, strcat(outdir, '/trial_', num2str(i), '.png'))
        close()
    end

end


    

    