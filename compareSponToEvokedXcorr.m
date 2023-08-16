function compareSponToEvokedXcorr(Datastore)
    data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
    data = filterTrials(data, 'go-nogo', 1);
    data = swapPhotometryChannels(data);
    % get list of animals in filtered dataset 
    animals = fetchAnimals(data);
    tbounds_spon = [-1.5, 0];
    tbounds_resp = [0, 1.5];
    outcomes = unique(data.categorical_outcome);
    outcomes = flipud(outcomes);

    if ~exist('Analysis/Xcorr/spontaneousVsEvoked/', 'dir')
        mkdir('Analysis/Xcorr/spontaneousVsEvoked/');
    end

    for a = 1:length(animals)
        animal = num2str(animals(a));
        tmp = filterTrials(data, 'animal', animal);
        fig = figure('Visible', 'off');
        yl = zeros(2,2);
        for o = 1:length(outcomes)
            data_outcome = filterTrials(tmp, 'categorical_outcome', outcomes(o));
            starts_spon = data_outcome.stimulus_time;
            starts_resp = data_outcome.stimulus_time + data_outcome.response_time;
            % allocate data 
            Fs = 1 / (data_outcome.photometry_ch2{1,1}(2,1) - data_outcome.photometry_ch2{1,1}(1,1));
            cs_spon = zeros(size(data_outcome,1), round(Fs*2*diff(tbounds_spon)-1));
            lags_spon = zeros(size(data_outcome,1), round(Fs*2*diff(tbounds_spon)-1));
            cs_resp = zeros(size(data_outcome,1), round(Fs*2*diff(tbounds_resp)-1));
            lags_resp = zeros(size(data_outcome,1), round(Fs*2*diff(tbounds_resp)-1));
            % before stim 
            for i = 1:size(data_outcome,1)
                ch1 = data_outcome.photometry_ch1{i,1}(:,2);
                ch2 = data_outcome.photometry_ch2{i,1}(:,2);
                % just two seconds prior to stimulus 
                tspon = data_outcome.photometry_ch1{i,1}(:,1) - starts_spon(i);
                ch1spon = ch1(tspon > tbounds_spon(1) & tspon < tbounds_spon(2));
                ch2spon = ch2(tspon > tbounds_spon(1) & tspon < tbounds_spon(2));
                tresp = data_outcome.photometry_ch1{i,1}(:,1) - starts_resp(i);
                ch1resp = ch1(tresp > tbounds_resp(1) & tresp < tbounds_resp(2));
                ch2resp = ch2(tresp > tbounds_resp(1) & tresp < tbounds_resp(2));
                [cspon, lagspon] = xcorr(ch1spon-mean(ch1spon), ch2spon-mean(ch2spon));
                try
                    lags_spon(i,:) = lagspon ./ Fs;
                    cs_spon(i,:) = cspon;
                catch
                    lags_spon(i,:) = nan(1, size(lags_spon,2));
                    cs_spon(i,:) = nan(1,size(cs_spon,2));
                end
                [cresp, lagresp] = xcorr(ch1resp-mean(ch1resp), ch2resp-mean(ch2resp));
                try
                    lags_resp(i,:) = lagresp ./ Fs;
                    cs_resp(i,:) = cresp;
                catch
                    lags_resp(i,:) = nan(1, size(lags_resp,2));
                    cs_resp(i,:) = nan(1,size(cs_resp,2));
                end
            end
            subplot(1,2,o)
            hold on
            semshade(cs_spon, 0.3, 'b', 'b', lags_spon(1,:), [], 'Spontaneous');
            semshade(cs_resp, 0.3, 'r', 'r', lags_resp(1,:), [], 'Evoked');
            legend('location', 'southwest')
            title(sprintf('%s (n=%i)', outcomes(o), size(lags_resp,1)))
            xlabel('Lag (s)')
            ylabel('Xcorr')
            xlim([-1.5, 1.5])
            yl(o,:) = ylim;
        end
        subplot(1,2,1)
        ylim([min(min(yl)), max(max(yl))])
        subplot(1,2,2)
        ylim([min(min(yl)), max(max(yl))])
        saveas(fig, sprintf('Analysis/Xcorr/spontaneousVsEvoked/%i.png', animals(a)))
    end

    fig = figure('Visible', 'off');
    yl = zeros(2,2);
    for o = 1:length(outcomes)
        data_outcome = filterTrials(data, 'categorical_outcome', outcomes(o));
        starts_spon = data_outcome.stimulus_time;
        starts_resp = data_outcome.stimulus_time + data_outcome.response_time;
        % allocate data 
        Fs = 1 / (data_outcome.photometry_ch2{1,1}(2,1) - data_outcome.photometry_ch2{1,1}(1,1));
        cs_spon = zeros(size(data_outcome,1), round(Fs*2*diff(tbounds_spon)-1));
        lags_spon = zeros(size(data_outcome,1), round(Fs*2*diff(tbounds_spon)-1));
        cs_resp = zeros(size(data_outcome,1), round(Fs*2*diff(tbounds_resp)-1));
        lags_resp = zeros(size(data_outcome,1), round(Fs*2*diff(tbounds_resp)-1));
        % before stim 
        for i = 1:size(data_outcome,1)
            ch1 = data_outcome.photometry_ch1{i,1}(:,2);
            ch2 = data_outcome.photometry_ch2{i,1}(:,2);
            % just two seconds prior to stimulus 
            tspon = data_outcome.photometry_ch1{i,1}(:,1) - starts_spon(i);
            ch1spon = ch1(tspon > tbounds_spon(1) & tspon < tbounds_spon(2));
            ch2spon = ch2(tspon > tbounds_spon(1) & tspon < tbounds_spon(2));
            tresp = data_outcome.photometry_ch1{i,1}(:,1) - starts_resp(i);
            ch1resp = ch1(tresp > tbounds_resp(1) & tresp < tbounds_resp(2));
            ch2resp = ch2(tresp > tbounds_resp(1) & tresp < tbounds_resp(2));
            [cspon, lagspon] = xcorr(ch1spon-mean(ch1spon), ch2spon-mean(ch2spon));
            try
                lags_spon(i,:) = lagspon ./ Fs;
                cs_spon(i,:) = cspon;
            catch
                lags_spon(i,:) = nan(1, size(lags_spon,2));
                cs_spon(i,:) = nan(1,size(cs_spon,2));
            end
            [cresp, lagresp] = xcorr(ch1resp-mean(ch1resp), ch2resp-mean(ch2resp));
            try
                lags_resp(i,:) = lagresp ./ Fs;
                cs_resp(i,:) = cresp;
            catch
                lags_resp(i,:) = nan(1, size(lags_resp,2));
                cs_resp(i,:) = nan(1,size(cs_resp,2));
            end
        end
        subplot(1,2,o)
        hold on
        semshade(cs_spon, 0.3, 'b', 'b', lags_spon(1,:), [], 'Spontaneous');
        semshade(cs_resp, 0.3, 'r', 'r', lags_resp(1,:), [], 'Evoked');
        legend('location', 'southwest')
        title(sprintf('%s (n=%i)', outcomes(o), size(lags_resp,1)))
        xlabel('Lag (s)')
        ylabel('Xcorr')
        xlim([-1.5, 1.5])
        yl(o,:) = ylim;
    end
    subplot(1,2,1)
    ylim([min(min(yl)), max(max(yl))])
    subplot(1,2,2)
    ylim([min(min(yl)), max(max(yl))])
    saveas(fig, sprintf('Analysis/Xcorr/spontaneousVsEvoked/all_animals.png'))

end