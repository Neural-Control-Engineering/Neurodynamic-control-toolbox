function [NTData, time] = checkNTData(paths, session_list, params)
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
        
        figure(3);
        [c,lags] = xcorr(mean(NTswstim(:, :, 2),1),mean(NTswstim(:, :, 1),1));
        stem(lags,c);
        title(strcat(char(regionNT_names(1)), " and ", char(regionNT_names(2)), " xcorr for ", animal_name))

        NTData = NTswstim;
    end
