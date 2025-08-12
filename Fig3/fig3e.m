function shuff_xcor = fig3e(data, ver)

    animals = fetchAnimals(data);
    sessions = unique(data.session_id);
    
    animal_xcor = [];
    session_xcor = [];
    tbounds = [-4,0];

    for a = 1:length(animals)
        tmp = filterTrials(data, 'animal', num2str(animals(a)));
        [mpfc, s1, t] = avg_photo_traces(tmp, tbounds, 'stimulus', ver);
        try
            [pupil, tp] = avg_pupil_traces(tmp, tbounds, 'stimulus');
            Fs = getFs(data, 'photometry_ch1');
            Fs = Fs(1);
            cs = zeros(size(tmp,1), length([tbounds(1):(1/Fs):tbounds(2)])*2-5);
            lags = zeros(size(tmp,1), length([tbounds(1):(1/Fs):tbounds(2)])*2-5);
            for i = 1:size(mpfc,1)
                ch1 = mpfc(i,:);
                y = bandpassFilter(ch1, 0.1, 10, Fs);
                ch1 = downsample(y, round(Fs/10));
                ch2 = pupil(i,:);
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
    end
    animal_lags = lag ./ Fs;

    for s = 1:length(sessions)
        tmp = filterTrials(data, 'session_id', num2str(sessions(s)));
        [mpfc, s1, t] = avg_photo_traces(tmp, tbounds, 'stimulus', ver);
        try
            [pupil, tp] = avg_pupil_traces(tmp, tbounds, 'stimulus');
            Fs = getFs(data, 'photometry_ch1');
            Fs = Fs(1);
            cs = zeros(size(tmp,1), length([tbounds(1):(1/10):tbounds(2)])*2-5);
            lags = zeros(size(tmp,1), length([tbounds(1):(1/10):tbounds(2)])*2-5);
            for i = 1:size(pupil,1)
                ch1 = mpfc(i,:);
                y = bandpassFilter(ch1, 0.1, 10, Fs);
                ch1 = downsample(y, round(Fs/10));
                ch2 = pupil(i,:);
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
    end
    session_lags = lag ./ Fs;

    shuff_xcor = [];
    for ii = 1:1000
        s = randi(length(sessions));
        tmp = filterTrials(data, 'session_id', num2str(sessions(s)));
        [mpfc, s1, t] = avg_photo_traces(tmp, tbounds, 'stimulus', ver);
        try
            [pupil, tp] = avg_pupil_traces(tmp, tbounds, 'stimulus');
            Fs = getFs(data, 'photometry_ch1');
            Fs = Fs(1);
            cs = zeros(size(tmp,1), length([tbounds(1):(1/10):tbounds(2)])*2-5);
            lags = zeros(size(tmp,1), length([tbounds(1):(1/10):tbounds(2)])*2-5);
            for i = 1:size(pupil,1)
                ch1 = mpfc(i,:);
                y = bandpassFilter(ch1, 0.1, 10, Fs);
                ch1 = downsample(y, round(Fs/10));
                ch2 = pupil(i,:);
                x = randi([round(length(ch1)*0.25), round(length(ch1)*0.75)]);
                ch1 = [ch1(x:end), ch1(1:x-1)];
                % x = randi(length(ch2));
                % ch2 = [ch2(x:end), ch2(1:x-1)];
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
                shuff_xcor = [shuff_xcor; nanmean(cs)];
            else
                shuff_xcor = [shuff_xcor; cs];
            end
        end
    end
    
    fig_sesh = figure();
    % session_xcor = session_xcor(:,(session_lags >= -4 & session_lags <= 4));
    % session_lags = session_lags(session_lags >= -4 & session_lags <= 4);
    for r = 1:size(session_xcor,1)
        session_xcor(r,:) = session_xcor(r,:) - mean(shuff_xcor);
    end
    semshade(session_xcor, 0.3, 'k', 'k', linspace(-4,4,size(session_xcor,2)), 1);
    % hold on 
    % semshade(shuff_xcor, 0.3, 'r', 'r', session_lags, 1);
    xlabel('Lag (s)', 'FontSize', 16)
    ylabel({'NE_{mPFC} x Pupil Area', 'Shuffle Corrected Cross Correlation'}, 'FontSize', 16)

    saveas(fig_sesh, 'Figures/fig3e.fig')
    saveas(fig_sesh, 'Figures/fig3e.svg')

    % fig_animal = figure();
    % % animal_xcor = animal_xcor(:,(animal_lags >= -4 & animal_lags <= 4));
    % % animal_lags = animal_lags(animal_lags >= -4 & animal_lags <= 4);
    % semshade(animal_xcor, 0.3, 'k', 'k', animal_lags, 1);
    % xlabel('Lag (s)', 'FontSize', 16)
    % ylabel({'NE_{mPFC} x NE_{S1}', 'Normalized Cross Correlation'}, 'FontSize', 16)

end