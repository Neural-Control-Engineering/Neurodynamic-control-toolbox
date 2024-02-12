function neCrossCorr(data, ver)

    animals = fetchAnimals(data);
    sessions = unique(data.session_id);
    
    animal_xcor = [];
    session_xcor = [];
    tbounds = [-2,0];

    for a = 1:length(animals)
        tmp = filterTrials(data, 'animal', num2str(animals(a)));
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
            animal_xcor = [animal_xcor; nanmean(cs)];
        else
            animal_xcor = [aniaml_xcor; cs];
        end
    end
    animal_lags = lag ./ Fs;

    for s = 1:length(sessions)
        tmp = filterTrials(data, 'session_id', num2str(sessions(s)));
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
            session_xcor = [session_xcor; nanmean(cs)];
        else
            session_xcor = [session_xcor; cs];
        end
    end
    session_lags = lag ./ Fs;
    
    fig_sesh = figure();
    % session_xcor = session_xcor(:,(session_lags >= -4 & session_lags <= 4));
    % session_lags = session_lags(session_lags >= -4 & session_lags <= 4);
    semshade(session_xcor, 0.3, 'k', 'k', session_lags, 1);
    xlabel('Lag (s)', 'FontSize', 16)
    ylabel({'NE_{mPFC} x NE_{S1}', 'Normalized Cross Correlation'}, 'FontSize', 16)

    fig_animal = figure();
    % animal_xcor = animal_xcor(:,(animal_lags >= -4 & animal_lags <= 4));
    % animal_lags = animal_lags(animal_lags >= -4 & animal_lags <= 4);
    semshade(animal_xcor, 0.3, 'k', 'k', animal_lags, 1);
    xlabel('Lag (s)', 'FontSize', 16)
    ylabel({'NE_{mPFC} x NE_{S1}', 'Normalized Cross Correlation'}, 'FontSize', 16)

end