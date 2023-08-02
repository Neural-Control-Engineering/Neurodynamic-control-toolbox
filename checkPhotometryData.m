function [NTData, time] = checkPhotometryData(paths, session_list, params)
    if length(session_list) == 1
        % Load corresponding processed behavior data structure
        session_list_csv = strcat(session_list, '.csv');
        ntData = csvread(fullfile(paths.processed_photometry_data,session_list_csv));
        behavData = load(fullfile(paths.processed_behavior_data,session_list));

        photo_fs = behavData.behavior_data.meta_data.photometry.photometry_fs/behavData.behavior_data.meta_data.photometry.decimation_factor;
        
        % Generate a sample signal with steps
        pulse_rise = behavData.behavior_data.pulse.rise_times;
        % Set the threshold for detecting steps
        threshold = 0.5;
        % Calculate the first derivative of the signal
        dx = diff(pulse_rise);
        % Find the indices where the derivative crosses the threshold
        stimtimes = pulse_rise(dx > threshold);
        stimtimes = stimtimes(stimtimes >= 0);

        regionNT_names = {behavData.behavior_data.meta_data.photometry.channel_1_region, behavData.behavior_data.meta_data.photometry.channel_2_region};
        NTswstim = zeros(length(stimtimes), photo_fs*(params.before_event+params.after_event), length(regionNT_names));
        
        for i = 2:length(stimtimes)-1 %maybe should zero pad the first to not exclude it
            [~, idx] = min(abs(ntData(:, 1)-stimtimes(i)));
            startidx = idx - (params.before_event * photo_fs);
            endidx = idx + (params.after_event * photo_fs);
            NTswstim(i, :, 1) = ntData(startidx:endidx-1, 2); %first chan NT
            NTswstim(i, :, 2) = ntData(startidx:endidx-1, 3); %second chan NT
%             NTswstim(i, :, 1) = movmean(zscore(ntData(startidx:endidx-1, 2)), 60); %first chan NT
%             NTswstim(i, :, 2) = movmean(zscore(ntData(startidx:endidx-1, 3)), 60); %second chan NT
        end
        
        full_name = char(session_list(1));
        hyf_idx = strfind(full_name, '-');
        animal_name = full_name(1:hyf_idx(1)-1);

        % Calculate mean and SEM for both channels
        mean_ch1 = mean(NTswstim(:, :, 1), 1);
        mean_ch2 = mean(NTswstim(:, :, 2), 1);
        sem_ch1 = std(NTswstim(:, :, 1), 0, 1) / sqrt(size(NTswstim, 1));
        sem_ch2 = std(NTswstim(:, :, 2), 0, 1) / sqrt(size(NTswstim, 1));

        time = linspace(-1*params.before_event, params.after_event, length(NTswstim(1, :, 1)));

        % Segment the trials into 1 second before pulse, 1 second pulse, and 1 second after pulse
        before_pulse = NTswstim(:, 1:photo_fs, :);
        during_pulse = NTswstim(:, photo_fs+1:2*photo_fs, :);
        after_pulse = NTswstim(:, 2*photo_fs+1:end, :);

        linePropsCh1 = {'-','Color', '#EDB120','MarkerFaceColor','k'}; %use more dull colors for noisier NE data
        linePropsCh2 = {'-b','MarkerFaceColor','k'};

        % Plot channel 1 with shaded SEM
        figure(1);
        shadedErrorBar(time, mean_ch1, sem_ch1, 'lineProps', linePropsCh1);
        title(strcat(char(regionNT_names(1)), " Pulse Stimulus Aligned for ", animal_name));

        % Plot channel 2 with shaded SEM
        figure(2);
        shadedErrorBar(time, mean_ch2, sem_ch2, 'lineProps', linePropsCh2);
        title(strcat(char(regionNT_names(1)), " Pulse Stimulus Aligned for ", animal_name));
        
        % Cross-correlation
        figure(3);
        [c,lags] = xcorr(mean(NTswstim(:, :, 2),1),mean(NTswstim(:, :, 1),1));
        stem(lags,c);
        title(strcat("Entire Cross-correlation for ", char(regionNT_names(1)), " and ", char(regionNT_names(2)), " for ", animal_name));
        
        % Power Spectrum
        figure(4);
        [pxx,f] = pwelch(mean(NTswstim(:, :, 1),1),[],[],[],photo_fs);
        loglog(f,pxx);
        hold on;
        [pxx,f] = pwelch(mean(NTswstim(:, :, 2),1),[],[],[],photo_fs);
        loglog(f,pxx);
        title(strcat("Entire Power Spectrum for ", char(regionNT_names(1)), " and ", char(regionNT_names(2)), " for ", animal_name));
        legend(regionNT_names);
        hold off;

        % Coherence
        figure(6);
        [Cxy,f] = mscohere(mean(NTswstim(:, :, 1),1), mean(NTswstim(:, :, 2),1),[],[],[],photo_fs);
        plot(f,Cxy);
        title(strcat("Coherence between ", char(regionNT_names(1)), " and ", char(regionNT_names(2)), " for ", animal_name));

        % Plot average (sem) for each segment
        segments = {before_pulse, during_pulse, after_pulse};
        segment_names = {'Before Pulse', 'During Pulse', 'After Pulse'};
        figure(8);
        for seg = 1:length(segments)
            subplot(3,1,seg);
            mean_segment_ch1 = mean(segments{seg}(:,:,1), 1);
            mean_segment_ch2 = mean(segments{seg}(:,:,2), 1);
            sem_segment_ch1 = std(segments{seg}(:,:,1), 0, 1) / sqrt(size(segments{seg}(:,:,1), 1));
            sem_segment_ch2 = std(segments{seg}(:,:,2), 0, 1) / sqrt(size(segments{seg}(:,:,2), 1));
            
            time = 0:(1/photo_fs):(length(mean_segment_ch1)-1)/photo_fs;

            shadedErrorBar(time, mean_segment_ch1, sem_segment_ch1, 'lineProps', {'-','Color', '#EDB120','MarkerFaceColor','k'});
            hold on;
            shadedErrorBar(time, mean_segment_ch2, sem_segment_ch2, 'lineProps', {'-b','MarkerFaceColor','k'});
            hold off;
            title(strcat("Mean and SEM for ", char(regionNT_names(1)), " and ", char(regionNT_names(2)), " ", segment_names{seg}, " for ", animal_name));
            legend(regionNT_names);
        end

        % Plot power spectrum for each segment
        figure(7);
        for seg = 1:length(segments)
            subplot(3,1,seg);
            [pxx,f] = pwelch(mean(segments{seg}(:,:,1),1),[],[],[],photo_fs);
            loglog(f,pxx);
            hold on;
            [pxx,f] = pwelch(mean(segments{seg}(:,:,2),1),[],[],[],photo_fs);
            loglog(f,pxx);
            title(strcat("Power Spectrum for ", char(regionNT_names(1)), " and ", char(regionNT_names(2)), " ", segment_names{seg}, " for ", animal_name));
            legend(regionNT_names);
            hold off;
        end

        % Return Data jic
        NTData = NTswstim;
    else
        session_list_csv = strcat(session_list, '.csv');

        full_name = char(session_list(1));
        hyf_idx = strfind(full_name, '-');
        animal_name = full_name(1:hyf_idx(1)-1);
        
        for sl = 1:length(session_list_csv)
            behavData = load(fullfile(paths.processed_behavior_data,session_list(sl)));
            photo_fs = behavData.behavior_data.meta_data.photometry.photometry_fs/behavData.behavior_data.meta_data.photometry.decimation_factor;
            regionNT_names = {behavData.behavior_data.meta_data.photometry.channel_1_region, behavData.behavior_data.meta_data.photometry.channel_2_region};
            if sl == 1
                alldat = zeros(1, photo_fs*(params.before_event+params.after_event), length(regionNT_names));
            end
            try
                ntData = csvread(fullfile(paths.processed_photometry_data,session_list_csv(sl)));
            catch
                namnam = char(session_list(sl));
                disp("Processed Photometry file for " + namnam(end-10+1:end) + " was not found or empty")
                continue
            end
            % Generate a sample signal with steps
            pulse_rise = behavData.behavior_data.pulse.rise_times;
            % Set the threshold for detecting steps
            threshold = 0.5;
            % Calculate the first derivative of the signal
            dx = diff(pulse_rise);
            % Find the indices where the derivative crosses the threshold
            stimtimes = pulse_rise(dx > threshold);
            stimtimes = stimtimes(stimtimes >= 0);
        
            regionNT_names = {behavData.behavior_data.meta_data.photometry.channel_1_region, behavData.behavior_data.meta_data.photometry.channel_2_region};
            NTswstim = zeros(length(stimtimes), photo_fs*(params.before_event+params.after_event), length(regionNT_names));
        
            for i = 2:length(stimtimes)-1 %maybe should zero pad the first to not exclude it
                [~, idx] = min(abs(ntData(:, 1)-stimtimes(i)));
                startidx = idx - (params.before_event * photo_fs);
                endidx = idx + (params.after_event * photo_fs);
                NTswstim(i, :, 1) = ntData(startidx:endidx-1, 2); %first chan NT
                NTswstim(i, :, 2) = ntData(startidx:endidx-1, 3); %second chan NT
            end
        
            %alldat(end+1, :, :) = NTswstim; %will give us a row at the top with all zeros
            alldat = [alldat; NTswstim];
        end

        alldat = alldat(2:end, :, :); %getting rid of zeros at top

        % Calculate mean and SEM for both channels
        mean_ch1 = mean(alldat(:, :, 1), 1);
        mean_ch2 = mean(alldat(:, :, 2), 1);
        sem_ch1 = std(alldat(:, :, 1), 0, 1) / sqrt(size(alldat, 1));
        sem_ch2 = std(alldat(:, :, 2), 0, 1) / sqrt(size(alldat, 1));

        time = linspace(-1*params.before_event, params.after_event, length(alldat(1, :, 1)));

        % Segment the trials into 1 second before pulse, 1 second pulse, and 1 second after pulse
        before_pulse = alldat(:, 1:photo_fs, :);
        during_pulse = alldat(:, photo_fs+1:2*photo_fs, :);
        after_pulse = alldat(:, 2*photo_fs+1:end, :);

        linePropsCh1 = {'-','Color', '#EDB120','MarkerFaceColor','k'}; %use more dull colors for noisier NE data
        linePropsCh2 = {'-b','MarkerFaceColor','k'};

        % Plot channel 1 with shaded SEM
        figure(1);
        shadedErrorBar(time, mean_ch1, sem_ch1, 'lineProps', linePropsCh1);
        title(strcat(char(regionNT_names(1)), " Pulse Stimulus Aligned for ", animal_name));

        % Plot channel 2 with shaded SEM
        figure(2);
        shadedErrorBar(time, mean_ch2, sem_ch2, 'lineProps', linePropsCh2);
        title(strcat(char(regionNT_names(2)), " Pulse Stimulus Aligned for ", animal_name));
        
        % Cross-correlation
        figure(3);
        [c,lags] = xcorr(mean(alldat(:, :, 2),1),mean(alldat(:, :, 1),1));
        stem(lags,c);
        title(strcat("Entire Cross-correlation for ", char(regionNT_names(1)), " and ", char(regionNT_names(2)), " for ", animal_name));
        
        % Power Spectrum
        figure(4);
        [pxx,f] = pwelch(mean(alldat(:, :, 1),1),[],[],[],photo_fs);
        loglog(f,pxx);
        hold on;
        [pxx,f] = pwelch(mean(alldat(:, :, 2),1),[],[],[],photo_fs);
        loglog(f,pxx);
        title(strcat("Entire Power Spectrum for ", char(regionNT_names(1)), " and ", char(regionNT_names(2)), " for ", animal_name));
        legend(regionNT_names);
        hold off;

        % Coherence
        figure(6);
        [Cxy,f] = mscohere(mean(alldat(:, :, 1),1), mean(alldat(:, :, 2),1),[],[],[],photo_fs);
        plot(f,Cxy);
        title(strcat("Coherence between ", char(regionNT_names(1)), " and ", char(regionNT_names(2)), " for ", animal_name));

        % Plot average (sem) for each segment
        segments = {before_pulse, during_pulse, after_pulse};
        segment_names = {'Before Pulse', 'During Pulse', 'After Pulse'};
        figure(8);
        for seg = 1:length(segments)
            subplot(3,1,seg);
            mean_segment_ch1 = mean(segments{seg}(:,:,1), 1);
            mean_segment_ch2 = mean(segments{seg}(:,:,2), 1);
            sem_segment_ch1 = std(segments{seg}(:,:,1), 0, 1) / sqrt(size(segments{seg}(:,:,1), 1));
            sem_segment_ch2 = std(segments{seg}(:,:,2), 0, 1) / sqrt(size(segments{seg}(:,:,2), 1));
            
            seg_time = 0:(1/photo_fs):(length(mean_segment_ch1)-1)/photo_fs;

            shadedErrorBar(seg_time, mean_segment_ch1, sem_segment_ch1, 'lineProps', {'-','Color', '#EDB120','MarkerFaceColor','k'});
            hold on;
            shadedErrorBar(seg_time, mean_segment_ch2, sem_segment_ch2, 'lineProps', {'-b','MarkerFaceColor','k'});
            hold off;
            title(strcat("Mean and SEM for ", char(regionNT_names(1)), " and ", char(regionNT_names(2)), " ", segment_names{seg}, " for ", animal_name));
            legend(regionNT_names);
        end

        % Plot power spectrum for each segment
        figure(7);
        for seg = 1:length(segments)
            subplot(3,1,seg);
            [pxx,f] = pwelch(mean(segments{seg}(:,:,1),1),[],[],[],photo_fs);
            loglog(f,pxx);
            hold on;
            [pxx,f] = pwelch(mean(segments{seg}(:,:,2),1),[],[],[],photo_fs);
            loglog(f,pxx);
            title(strcat("Power Spectrum for ", char(regionNT_names(1)), " and ", char(regionNT_names(2)), " ", segment_names{seg}, " for ", animal_name));
            legend(regionNT_names);
            hold off;
        end

        % Return Data jic
        NTData = alldat;
    end
