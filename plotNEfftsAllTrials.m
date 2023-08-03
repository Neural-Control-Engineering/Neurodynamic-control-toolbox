function plotNEfftsAllTrials(data, session_id) 
    % place to save figs 
    mkdir(strcat('./', session_id, '_ffts/'));
    inds = data.session_id == session_id;
    photo = data.photometry_ch1(inds);
    onsets = data.trial_onset_time(inds);
    Fs = 1 / (photo{1,1}(2,1) - photo{1,1}(1,1));
    parfor i = 1:size(photo,1)
        y = photo{i,1}((photo{i,1}(:,1) < onsets(i)), 2);
        n = 2^nextpow2(length(y));
        Y = fft(y-mean(y), n);
        f = Fs*(0:(n/2))/n;
        fig = figure('Visible', 'off');
        plot(f,abs(Y(1:n/2+1)))
        saveas(fig, strcat('./', session_id, '_ffts/trial_', num2str(i), '.png'))
    end

end


    

    