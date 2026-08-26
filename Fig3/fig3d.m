function fig3d(data, ver, peak_ver, shuff)

    tbounds = [-4,0];
    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    Fs = getFs(data, 'photometry_ch1');
    Fs = Fs(1);
    peaks = {[],[],[],[]};
    sesh = {{},{},{},{}};
    subj = {{},{},{},{}};
    result = {};
    count = 1;

    for o = 1:length(outcomes)
        otmp = filterTrials(data, 'categorical_outcome', outcomes{o});
        [mpfc, s1, ~] = avg_photo_traces(otmp, tbounds, 'stimulus', ver);
        for i = 1:size(mpfc,1)
            ch1 = mpfc(i,:);
            ch2 = s1(i,:);
            % mpfc x s1 
            [c, lag] = xcorr(ch1(2:end-1), ch2(2:end-1), 'normalized');
            [peak, ~] = max(c-nanmean(shuff));
            n = floor(length(lag)/2);
            if strcmp(peak_ver, 'atzero')
                peaks{o} = [peaks{o}; c(n)-nanmean(shuff(:,n))];
            else
                peaks{o} = [peaks{o}; peak];
            end
            sesh{o} = vertcat(sesh{o}, otmp(i,:).session_id{1});
            result{count} = outcomes{o};
            count = count + 1;
        end
    end
    all_peaks = [peaks{1}; peaks{2}; peaks{3}; peaks{4}];
    session = vertcat(sesh{1}, sesh{2}, sesh{3}, sesh{4});
    subject = {};
    for i = 1:length(session)
        subject{i} = session{i}(1:3);
    end
    subject = subject';
    response = [ones(size(peaks{1})); zeros(size(peaks{2})); zeros(size(peaks{3})); ones(size(peaks{4}))];
    outcomes = [ones(size(peaks{1})); zeros(size(peaks{2})); ones(size(peaks{3})); zeros(size(peaks{4}))];

    T = table(all_peaks, result', response, session, subject,  'VariableNames', {'Correlation', 'Result', 'Response', 'Session', 'Subject'});

    lmeTbl = T(:, {'Correlation', 'Result', 'Response', 'Session', 'Subject'});

    % Make sure response is numeric
    lmeTbl.Correlation = double(lmeTbl.Correlation);

    % Make predictors categorical
    lmeTbl.Response = categorical(lmeTbl.Response);
    lmeTbl.Result = categorical(lmeTbl.Result);
    lmeTbl.Session  = categorical(lmeTbl.Session);
    lmeTbl.Subject  = categorical(lmeTbl.Subject);
    % lmeTbl.Outcome  = categorical(lmeTbl.Outcome);

    % Remove rows with missing values in any model variable
    badRows = isnan(lmeTbl.Correlation) | ...
            isundefined(lmeTbl.Response) | ...
            isundefined(lmeTbl.Result) | ...
            isundefined(lmeTbl.Subject) | ...
            isundefined(lmeTbl.Session);

    lmeTbl(badRows,:) = [];

    % Optional but useful: remove unused category levels
    lmeTbl.Response = removecats(lmeTbl.Response);
    lmeTbl.Session  = removecats(lmeTbl.Session);
    lmeTbl.Subject  = removecats(lmeTbl.Subject);
    lmeTbl.Result  = removecats(lmeTbl.Result);

    fprintf('Correlation by response LME\n')
    lme = fitlme(lmeTbl, ...
        'Correlation ~ Response + (1|Session) + (1|Subject)');
    anova(lme)
    fprintf('Correlation by outcome LME\n')
    lmeR = fitlme(lmeTbl, ...
        'Correlation ~ Result + (1|Session) + (1|Subject)');
    anova(lmeR)
    % compare(lme, lmeR)

    fig = figure();
    hold on; 
    % for i = 1:length(peaks)
    %     plot((rand(size(peaks{i}))-0.5)*0.1+i, peaks{i}, 'o', 'MarkerFaceColor', [0.5,0.5,0.5], 'MarkerEdgeColor', 'w', 'MarkerSize', 2)
    % end
    bar(1:4, cellfun(@nanmean, peaks), 'FaceColor', [0.5,0.5,0.5], 'EdgeColor', 'k')
    errorbar(1:4, cellfun(@nanmean, peaks), cellfun(@ste, peaks), 'k.', 'LineWidth', 2, 'CapSize', 25)
    bar(6:7, [nanmean(vertcat(peaks{1}, peaks{4})), nanmean(vertcat(peaks{2}, peaks{3}))], 'FaceColor', [0.5,0.5,0.5], 'EdgeColor', 'k')
    errorbar(6:7, [nanmean(vertcat(peaks{1}, peaks{4})), nanmean(vertcat(peaks{2}, peaks{3}))], [ste(vertcat(peaks{1}, peaks{4})), ste(vertcat(peaks{2}, peaks{3}))], 'k.', 'LineWidth', 2, 'CapSize', 25)
    xticks([1:4, 6:7])
    xticklabels({'Hit', 'Miss', 'Correct Rejection', 'False Alarm', 'Responded', 'Withheld'})
    xtickangle(45)
    lims = ylim;
    plot([5,5], lims, 'k--')
    ylim(lims)
    xlabel('Trial Outcome', 'FontSize', 16)
    ylabel('Correlation Coefficient at 0s Lag', 'FontSize', 16)
    saveas(fig, 'Figures/fig3d.fig')
    saveas(fig, 'Figures/fig3d.svg')
    
end 
