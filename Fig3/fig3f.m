function [animal_peaks, animal_pl, session_peaks, session_pl] = fig3f(data, ver, shuff)
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

    fig_sesh = figure();
    tl_sesh = tiledlayout(2,2);
    outcomes{3} = 'Correct Rejection';
    outcomes{4} = 'False Alarm';
    for o = 1:4
        axs_sesh(o) = nexttile;
        mat = session_xcor{o};
        for r = 1:size(mat,1)
            mat(r,:) = mat(r,:) - nanmean(shuff);
        end
        semshade(mat, 0.3, 'k', 'k', linspace(-4,4,size(mat,2)), 1);
        hold on
        % plot([0,0],[0,0.4],'k:')
        title(outcomes{o}, 'FontSize', 16, 'FontWeight', 'normal')
        % ylim([0,0.32])
        xlim([-4,4])
    end
    xlabel(tl_sesh, 'Lag (s)', 'FontSize', 16)
    ylabel(tl_sesh, {'NE_{mPFC} x Pupil Area', 'Shuffle Corrected Cross Correlation'}, 'FontSize', 16)
    unifyYLimits(fig_sesh)

    % fig_animal = figure();
    % tl_animal = tiledlayout(1,length(outcomes));
    % for o = 1:length(outcomes)
    %     axs_sesh(o) = nexttile;
    %     semshade(animal_xcor{o}, 0.3, 'k', 'k', animal_lags, 1);
    %     hold on
    %     plot([0,0],[0,0.4],'k:')
    %     title(outcomes{o}, 'FontSize', 16)
    %     ylim([0,0.35])
    % end
    % xlabel(tl_animal, 'Lag (s)', 'FontSize', 16)
    % ylabel(tl_animal, {'NE_{mPFC} x NE_{S1}', 'Normalized Cross Correlation'}, 'FontSize', 16)

    animal_peaks = {[], [], [], [], [], [], [], []};
    animal_pl = animal_peaks;
    session_peaks = animal_peaks;
    session_pl = session_peaks;

    for o = 1:length(outcomes)
        for r = 1:size(animal_xcor{o},1)
            [peak, ind] = max(animal_xcor{o}(r,:));
            animal_peaks{o} = [animal_peaks{o}; peak];
            animal_pl{o} = [animal_pl{o}; animal_lags(ind)];
        end
        for r = 1:size(session_xcor{o},1)
            [peak, ind] = max(session_xcor{o}(r,:));
            session_peaks{o} = [session_peaks{o}; peak];
            session_pl{o} = [session_pl{o}; session_lags(ind)];
        end
    end


end
