function [animal_peaks, animal_pl, session_peaks, session_pl] = neCrossCorrByOutcomeBar(data, ver, peak_ver)
    animals = fetchAnimals(data);
    sessions = unique(data.session_id);
    
    animal_xcor = {[], [], [], [], [], [], [], []};
    session_xcor = {[], [], [], [], [], [], [], []};
    tbounds = [-2,0];

    outcomes = {'Hit', 'Miss', 'CR', 'FA', {'Hit', 'FA'}, {'Miss', 'CR'}, {'Hit', 'CR'}, {'Miss', 'FA'}};

    for a = 1:length(animals)
        tmp = filterTrials(data, 'animal', num2str(animals(a)));
        for o = 1:length(outcomes)
            otmp = filterTrials(tmp, 'categorical_outcome', outcomes{o});
            [mpfc, s1, t] = avg_photo_traces(otmp, tbounds, 'stimulus', ver);
            Fs = getFs(data, 'photometry_ch1');
            Fs = Fs(1);
            cs = zeros(size(otmp,1), length([tbounds(1):(1/Fs):tbounds(2)])*2-5);
            lags = zeros(size(otmp,1), length([tbounds(1):(1/Fs):tbounds(2)])*2-5);
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
                animal_xcor{o} = [animal_xcor{o}; nanmean(cs)];
            else
                animal_xcor{o} = [animal_xcor{o}; cs];
            end
        end
    end
    animal_lags = lag ./ Fs;

    for s = 1:length(sessions)
        tmp = filterTrials(data, 'session_id', num2str(sessions(s)));
        for o = 1:length(outcomes)
            otmp = filterTrials(tmp, 'categorical_outcome', outcomes{o});
            [mpfc, s1, t] = avg_photo_traces(otmp, tbounds, 'stimulus', ver);
            Fs = getFs(data, 'photometry_ch1');
            Fs = Fs(1);
            cs = zeros(size(otmp,1), length([tbounds(1):(1/Fs):tbounds(2)])*2-5);
            lags = zeros(size(otmp,1), length([tbounds(1):(1/Fs):tbounds(2)])*2-5);
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
                session_xcor{o} = [session_xcor{o}; nanmean(cs)];
            else
                session_xcor{o} = [session_xcor{o}; cs];
            end
        end
    end
    session_lags = lag ./ Fs;

    animal_peaks = {[], [], [], [], [], [], [], []};
    animal_pl = animal_peaks;
    session_peaks = animal_peaks;
    session_pl = session_peaks;

    for o = 1:length(outcomes)
        for r = 1:size(animal_xcor{o},1)
            [peak, ind] = max(animal_xcor{o}(r,:));
            % animal_peaks{o} = [animal_peaks{o}; peak];
            n = floor(length(animal_xcor{o}(r,:))/2);
            if strcmp(peak_ver, 'atzero')
                animal_peaks{o} = [animal_peaks{o}; animal_xcor{o}(r,n)];
            else
                animal_peaks{o} = [animal_peaks{o}; peak];
            end
            animal_pl{o} = [animal_pl{o}; animal_lags(ind)];
        end
        for r = 1:size(session_xcor{o},1)
            [peak, ind] = max(session_xcor{o}(r,:));
            n = floor(length(session_xcor{o}(r,:))/2);
            if strcmp(peak_ver, 'atzero')
                session_peaks{o} = [session_peaks{o}; session_xcor{o}(r,n)];
            else
                session_peaks{o} = [session_peaks{o}; peak];
            end
            session_pl{o} = [session_pl{o}; session_lags(ind)];
        end
    end

    session_avg = zeros(length(session_peaks), 1);
    session_err = zeros(length(session_peaks), 1);
    animal_avg = zeros(length(animal_peaks), 1);
    animal_err = zeros(length(animal_peaks), 1);
    for i = 1:length(session_peaks)
        session_avg(i) = mean(session_peaks{i});
        session_err(i) = std(session_peaks{i}) / sqrt(length(session_peaks{i}));
        animal_avg(i) = mean(animal_peaks{i});
        animal_err(i) = std(animal_peaks{i}) / sqrt(length(animal_peaks{i}));
    end

    fig_session = figure();
    errorbar([1:4, 6:7, 9:10], session_avg, session_err, 'k.')
    hold on
    bar([1:4, 6:7, 9:10], session_avg, 'FaceColor', 'k', 'EdgeColor', 'k')
    xticks([1:4, 6:7, 9:10])
    xticklabels({'Hit', 'Miss', 'CR', 'FA', 'Action', 'Withhold', 'Correct', 'Incorrect'})
    xtickangle(45)
    ylabel('Peak Cross Correlation')

    fig_animal = figure();
    errorbar([1:4, 6:7, 9:10], animal_avg, animal_err, 'k.')
    hold on
    bar([1:4, 6:7, 9:10], animal_avg, 'FaceColor', 'k', 'EdgeColor', 'k')
    xticks([1:4, 6:7, 9:10])
    xticklabels({'Hit', 'Miss', 'CR', 'FA', 'Action', 'Withhold', 'Correct', 'Incorrect'})
    xtickangle(45)
    ylabel('Peak Cross Correlation')


end
