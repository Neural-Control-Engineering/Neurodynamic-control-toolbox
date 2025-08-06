function [animal_peaks, animal_pl, session_peaks, session_pl] = fig3g(data, ver, peak_ver, shuff)
    animals = fetchAnimals(data);
    sessions = unique(data.session_id);
    
    animal_xcor = {[], [], [], [], [], [], [], []};
    session_xcor = {[], [], [], [], [], [], [], []};
    tbounds = [-4,0];

    outcomes = {'Hit', 'Miss', 'CR', 'FA', {'Hit', 'FA'}, {'Miss', 'CR'}, {'Hit', 'CR'}, {'Miss', 'FA'}};

    for a = 1:length(animals)
        tmp = filterTrials(data, 'animal', num2str(animals(a)));
        for o = 1:length(outcomes)
            otmp = filterTrials(tmp, 'categorical_outcome', outcomes{o});
            [mpfc, s1, t] = avg_photo_traces(otmp, tbounds, 'stimulus', ver);
            try
                [pupil, tp] = avg_pupil_traces(otmp, tbounds, 'stimulus');
                Fs = getFs(data, 'photometry_ch1');
                Fs = Fs(1);
                cs = zeros(size(otmp,1), length([tbounds(1):(1/10):tbounds(2)])*2-5);
                lags = zeros(size(otmp,1), length([tbounds(1):(1/10):tbounds(2)])*2-5);
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
                    animal_xcor{o} = [animal_xcor{o}; nanmean(cs)];
                else
                    animal_xcor{o} = [animal_xcor{o}; cs];
                end
            end
        end
    end
    animal_lags = lag ./ Fs;

    for s = 1:length(sessions)
        tmp = filterTrials(data, 'session_id', num2str(sessions(s)));
        for o = 1:length(outcomes)
            otmp = filterTrials(tmp, 'categorical_outcome', outcomes{o});
            [mpfc, s1, t] = avg_photo_traces(otmp, tbounds, 'stimulus', ver);
            try
                [pupil, tp] = avg_pupil_traces(otmp, tbounds, 'stimulus');
                Fs = getFs(data, 'photometry_ch1');
                Fs = Fs(1);
                cs = zeros(size(otmp,1), length([tbounds(1):(1/10):tbounds(2)])*2-5);
                lags = zeros(size(otmp,1), length([tbounds(1):(1/10):tbounds(2)])*2-5);
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
                    session_xcor{o} = [session_xcor{o}; nanmean(cs)];
                else
                    session_xcor{o} = [session_xcor{o}; cs];
                end
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
            [peak, ind] = max(animal_xcor{o}(r,:)-nanmean(shuff));
            n = floor(length(animal_xcor{o}(r,:))/2);
            if strcmp(peak_ver, 'atzero')
                animal_peaks{o} = [animal_peaks{o}; animal_xcor{o}(r,n)-nanmean(shuff(:,n))];
            else
                animal_peaks{o} = [animal_peaks{o}; peak];
            end
            animal_pl{o} = [animal_pl{o}; animal_lags(ind)];
        end
        for r = 1:size(session_xcor{o},1)
            [peak, ind] = max(session_xcor{o}(r,:)-nanmean(shuff));
            n = floor(length(session_xcor{o}(r,:))/2);
            if strcmp(peak_ver, 'atzero')
                session_peaks{o} = [session_peaks{o}; session_xcor{o}(r,n)-nanmean(shuff(:,n))];
            else
                session_peaks{o} = [session_peaks{o}; peak];
            end
            session_pl{o} = [session_pl{o}; session_lags(ind)];
        end
    end

    fig_session = figure();
    hold on 
    x = [1:4, 6:7, 9:10];
    for i = 1:length(session_peaks)
        plot(zeros(1,length(session_peaks{i}))+x(i)+(rand([1,length(session_peaks{i})])-0.5)*0.3, session_peaks{i}, 'o', 'MarkerFaceColor', [0.5,0.5,0.5], 'MarkerEdgeColor', [1,1,1], 'MarkerSize', 5)
    end
    errorbar(x, cellfun(@mean, session_peaks), cellfun(@ste, session_peaks), 'k.', 'CapSize', 15, 'LineWidth', 2)
    xticks(x)
    xticklabels({'Hit', 'Miss', 'CR', 'FA', 'Action', 'Withhold', 'Correct', 'Incorrect'})
    xtickangle(45)
    if strcmp(peak_ver, 'atzero')
        ylabel('Cross Correlation at 0s Lag', 'FontSize', 16)
    else
        ylabel('Peak Correlation at 0s Lag', 'FontSize', 16)
    end

end
