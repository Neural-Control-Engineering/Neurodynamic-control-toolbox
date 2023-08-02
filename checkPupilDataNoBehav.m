function pu_trials = checkPupilDataNoBehav(paths,session_list,params)
    for sl = 1:length(session_list)
        addy = dir(fullfile(paths.processed_pupil_data,session_list(sl)+"*")); %dir so annoying CNN name doesn't matter
        if isempty(addy)
            namnam = char(session_list(sl));
            disp("Processed pupil file for " + namnam(end-10+1:end) + " was not found")
            continue
        end
        pupil_ds = load(fullfile(addy.folder, addy.name));
        behav_dat = load(fullfile(paths.processed_behavior_data,session_list(sl)));
    
        pupil_fs = behav_dat.behavior_data.meta_data.pupil.pupil_fs;
    
        if sl == 1
            pu_trials = zeros(1, pupil_fs*(params.before_event+params.after_event));
        end
    
        pupilvt = [pupil_ds(:, 1)/pupil_fs, pupil_ds(:, 2)];
    
        pulse_rise = behav_dat.behavior_data.pulse.rise_times;
        % Set the threshold for detecting steps
        threshold = 0.5;
        % Calculate the first derivative of the signal
        dx = diff(pulse_rise);
        % Find the indices where the derivative crosses the threshold
        stimtimes = pulse_rise(dx > threshold);
        stimtimes = stimtimes(stimtimes >= 0);
%         stimtimes = behav_dat.behavior_data.stim_times;

        pupilwstim = zeros(length(stimtimes)-1, pupil_fs*(params.before_event+params.after_event)); %should probably fix the -2
        
        len_pvt = size(pupilvt, 1);

        for st = 2:length(stimtimes)-2
            [~, idx] = min(abs(pupilvt(:,1)-stimtimes(st)));
            startidx = idx - (params.before_event * pupil_fs);
            endidx = idx + (params.after_event * pupil_fs);
            if endidx <= len_pvt %just evan
                pupilwstim(st, :) = pupilvt(startidx:endidx-1, 2);
            end
        end
        pu_trials = [pu_trials; pupilwstim];
    end
    pu_trials = pu_trials(3:end, :); %srry
    disp(size(pu_trials))

    time = linspace(-1*params.before_event, params.after_event, length(pu_trials(1, :)));
    
    % Calculate mean and SEM
    pupil_mean = mean(pu_trials, 1);
    pupil_sem = std(pu_trials, 0, 1) / sqrt(size(pu_trials, 1));

    % Create new figure
    figure(1); hold on;

    % Plot using shadedErrorBar
    shadedErrorBar(time, pupil_mean, pupil_sem, ...
                   'lineprops', '-r', 'transparent', 1);

    % Configure plot
    title('Mean and SEM of Pupil Data');
    xlabel('Time');
    ylabel('Amplitude');
    hold off;
end
    

