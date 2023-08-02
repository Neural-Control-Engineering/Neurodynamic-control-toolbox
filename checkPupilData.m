function [pu_trials, behav_dat] = checkPupilData(paths,session_list,params)
    if length(session_list) == 1
        addy = dir(fullfile(paths.processed_pupil_data,session_list+"*")); %dir so annoying CNN name doesn't matter
        pupil_ds = load(fullfile(addy.folder, addy.name));
        behav_dat = load(fullfile(paths.processed_behavior_data,session_list));

        pupil_framerate = behav_dat.behavior_data.meta_data.pupil.pupil_fs;

        pupilvt = [pupil_ds(:, 1)/pupil_framerate, pupil_ds(:, 2)];
        stimtimes = behav_dat.behavior_data.stim_times;

        possible_stims = sort(unique(behav_dat.behavior_data.stim_strength), 'descend');

        pu_trials = zeros(length(possible_stims), pupil_framerate*(params.before_event+params.after_event));

        stimstronk = behav_dat.behavior_data.stim_strength;
        
        for it = 1:length(possible_stims)
            stimmys = stimtimes(stimstronk == possible_stims(it));
            stim_comp = zeros(sum(stimstronk == possible_stims(it)), pupil_framerate*(params.before_event+params.after_event));
            for tt = 1:length(stimmys)-1 %-1 because end indexing? tf last one missing from analysis
                [~, idx] = min(abs(pupilvt(:,1)-stimmys(tt)));
                startidx = idx - (params.before_event * pupil_framerate);
                endidx = idx + (params.after_event * pupil_framerate);
                stim_comp(tt, :) = pupilvt(startidx:endidx-1, 2);
            end
            pu_trials(it, :) = mean(stim_comp);
        end

        time = linspace(-1*params.before_event, params.after_event, length(pu_trials(1, :)));
        figure();
        plot(time, pu_trials)
        legend(string(possible_stims) + " PSI")
    else
        for sl = 1:length(session_list)
            addy = dir(fullfile(paths.processed_pupil_data,session_list(sl)+"*")); %dir so annoying CNN name doesn't matter
            if isempty(addy)
                namnam = char(session_list(sl));
                disp("Processed file for " + namnam(end-10+1:end) + " was not found")
                continue
            end
            pupil_ds = load(fullfile(addy.folder, addy.name));
            behav_dat = load(fullfile(paths.processed_behavior_data,session_list(sl)));
        
            pupil_framerate = behav_dat.behavior_data.meta_data.pupil.pupil_fs;
        
            pupilvt = [pupil_ds(:, 1)/pupil_framerate, pupil_ds(:, 2)];
            stimtimes = behav_dat.behavior_data.stim_times;
            
            stimstronk = behav_dat.behavior_data.stim_strength;
            pupil_framerate = behav_dat.behavior_data.meta_data.pupil.pupil_fs;
            possible_stims = sort(unique(behav_dat.behavior_data.stim_strength), 'descend');
            pu_trials = cell(possible_stims);
            
            for it = 1:length(possible_stims)
                stimmys = stimtimes(stimstronk == possible_stims(it));
                stim_comp = zeros(sum(stimstronk == possible_stims(it)), pupil_framerate*(params.before_event+params.after_event));
                for tt = 1:length(stimmys)-1 %-1 because end indexing? tf last one missing from analysis
                    [~, idx] = min(abs(pupilvt(:,1)-stimmys(tt)));
                    startidx = idx - (params.before_event * pupil_framerate);
                    endidx = idx + (params.after_event * pupil_framerate);
                    stim_comp(tt, :) = pupilvt(startidx:endidx-1, 2);
                end
                pu_trials(it, :) = mean(stim_comp);
            end

            size(pu_trials)
        end
    end
end


