function [processed_photometry_isos, processed_photometry_MWF0] = processRawPhotometry(behavior_data,paths,params)

%PROCESS_RAW_PHOTOMETRY Process raw photometry data and outputs df/f
%   This function takes the raw signal (pass the corresponding processed
%   behavior data file

% From doric photometry system imported matrix
% Column 1 - Time axis
% Column 2 - Analog 1 (isosbestic control for mPFC)
% Column 3 - Analog 2 (Signal of interest for mPFC)
% Column 4 - Analog 3 (Raw signal for mPFC)
% Column 5 - Analog 4 (isosbestic control for S1)
% Column 6 - Analog 5 (Signal of interest for S1)
% Coluean 7 - Analog 6 (Raw signal for S1)
% Column 8 - Digital 1 (1 when matlab program is running and sending a
% trigger)
% Column 9 - Digital 2 (1 when a true air puff stimulation is given)
% Column 10 - 13 not important

%(2022-12-22)Load test data for debug
% behavior_data=open("H:\.shortcut-targets-by-id\1yB5u8zHl-aBucQQEQZIgnPdQ1Re2j-5E\Project_Neurotransmitter-Exploration\Processed Behavior Data\240-R-mPFC-S1-NE_2022_12_15.mat");
% behavior_data = behavior_data.behavior_data;
% params = setAnalysisParameters([]);
% params.debug_mode = true;
% paths = setPaths();

%photometry_to_load = dir(fullfile(paths.raw_photometry_data,strcat(behavior_data.session_id,'*.csv')));
%raw_data = readtable(fullfile(paths.raw_photometry_data,photometry_to_load.name));
%raw_data = raw_data(raw_data{:,8}==1,:); % trim photometry data to include only when xPC was sending triggers

% Create alternative session id for checking for py photometry data
temp = split(behavior_data.session_id,'_');
behavior_data.session_id_alt = strcat(temp{1},'-',temp{2},'-',temp{3},'-',temp{4});


% Duration of video
if isfield(behavior_data,'wheel_displacement')
    session_length = (behavior_data.wheel_displacement(end,1) + params.drop_buffer_start + params.drop_buffer_end)/60; % assume length is documented in minutes -> / 60
else
    session_length = (behavior_data.video_details.pupil(3))/60;
end

% load photometry data from doric, py photometry will be handled separately
% below as a backup case
photometry_to_load = dir(fullfile(paths.raw_photometry_data,strcat(behavior_data.session_id,'*.csv')));

if ~isempty(photometry_to_load) 
    raw_data = readtable(fullfile(paths.raw_photometry_data,photometry_to_load.name),'ReadVariableNames',false);

    % trim photometry data to include only when xPC was sending tprocessRawriggers1,
    % (2022-12-22)and remove nan values in columns we care for compatibility
    raw_data = raw_data( ...
        raw_data{:,8}==1 & ~isnan(raw_data{:,1}) & ~isnan(raw_data{:,2})...
        & ~isnan(raw_data{:,3}) & ~isnan(raw_data{:,5}) & ~isnan(raw_data{:,6}),:);

    % Set a QC factor to make sure the number of samples recorded matches
    % the session duration:
    QC_photo_deci = behavior_data.meta_data.photometry.photometry_fs*session_length*60 ...
        /height(raw_data)/behavior_data.meta_data.photometry.decimation_factor;
    if QC_photo_deci > 3 || QC_photo_deci < 0.33
        corrected_photo_deci = round( ...
            behavior_data.meta_data.photometry.decimation_factor*QC_photo_deci, ...
            1, 'significant');
        warning(strcat("For session: ",behavior_data.session_id, ...
            " the photometry decimation factor recorded: ", ...
            num2str(behavior_data.meta_data.photometry.decimation_factor),...
            " does not match with photometry data length, and is automatically corrected to ",...
            num2str(corrected_photo_deci),". Further investigation is required."))
        behavior_data.meta_data.photometry.decimation_factor = corrected_photo_deci;
    end
    photometry_fs = behavior_data.meta_data.photometry.photometry_fs/...
        behavior_data.meta_data.photometry.decimation_factor;


    % (Unresolved) Right now phase 0 is not handled very complexly, eventually we should
    % bring it up-to-date with the other phases

    % (Unresolved) we need better way of compatibility check than the current one
    if ~strcmp(behavior_data.training_phase,"Phase 0")
        % find time of true stimulus signals in behavior log
        true_stim_times = behavior_data.stim_times; %(behavior_data.stim_strength > 0);
        % find time of the rising edge of true stimulus trigger in
        % photometry log in trimmed range
        recorded_stim_times = raw_data{diff(raw_data{:,9})==1,1};
        recorded_stim_times = recorded_stim_times(recorded_stim_times > params.drop_buffer_start ...
            & recorded_stim_times < (session_length*60 - params.drop_buffer_end));

        %% (2022-12-22) This code performs time synchronization between two data sets: recorded_stim_times and true_stim_times.
        % The loop iterates over the recorded stimulus times in reverse order (from the last element to the first).
        % For each recorded stimulus time, the code finds the true stimulus time that is closest.
        % If the absolute value of the difference between the recorded stimulus time and the closest true stimulus time is greater than 0.5 seconds before or 0.5 seconds after,
        % a warning is issued. If neither of these conditions is met, the code calculates the time shift between the recorded stimulus time and the closest true stimulus.
        % This time shift is used to adjust the timestamps in the raw_data array, starting from the end of timestamps until the start.
        % The value of calibr_end is updated to the index of the recorded stimulus time, so that the next iteration of the loop will start adjusting timestamps from the previous recorded stimulus time.
        % If the params.debug_mode flag is set, the time shift is recorded in for latter plotting.
        calibr_end = length(raw_data{:,1})+1;
        time_shifting_record = [];
        time_axis_old = raw_data{:,1};
        N_unmatched_trigger = 0;
        for i = length(recorded_stim_times):-1:1
            [time_shift_abs,idx] = min(abs(recorded_stim_times(i) - params.drop_buffer_start - true_stim_times));
            % (2022-12-23) if delete the 'continue skip' for loops with
            % time_shift_abs >5, Bugs will emerge to shift the time axis
            % wrongly when there is no matching triggers from
            % behavior_data, so I change this part back and deal with
            % overflow of warnings in later part
            if time_shift_abs > 5
                % (Unresolved) a temporary solution: trials close to trim
                % start and end are not counted in unmatch bases and wont
                % be reported in warnings
                if ~(i == length(recorded_stim_times) || i == 1)
                    N_unmatched_trigger = N_unmatched_trigger+1;
                end

                if params.debug_mode
                    time_shifting_record = [0,time_shifting_record];
                end
                continue
            elseif time_shift_abs > 0.5
                warning(strcat('For session: ',behavior_data.session_id, ...
                    ', The stim trigger-',num2str(i), ...
                    ' recorded by photometry log has a time shifting = ', num2str(time_shift_abs),...
                    's, this data session should be considered as unreliable and excluded'))
                if params.debug_mode
                    time_shifting_record = [0,time_shifting_record];
                end
                continue
            end
            calibr_value = recorded_stim_times(i) - params.drop_buffer_start - true_stim_times(idx);
            [~,recorded_stim_time_idx] = min(abs(raw_data{:,1}-recorded_stim_times(i)));
            time_axis_old(recorded_stim_time_idx:calibr_end-1,1) = ...
                time_axis_old(recorded_stim_time_idx:calibr_end-1,1) - calibr_value;
            calibr_end = recorded_stim_time_idx;
            if params.debug_mode
                time_shifting_record = [calibr_value,time_shifting_record];
            end
        end

        % (2022-12-23) to prevent multiple warnings cover important
        % message, now the number of unmatched triggers are cumulated and
        % report at once
        if N_unmatched_trigger > 0
            warning(strcat('For session: ',behavior_data.session_id, ...
                ", There are in total  ",num2str(N_unmatched_trigger), ...
                ' stim triggers recorded by photometry log without matching  ', ...
                ' triggers from XPC in 5 seconds, the two files could be mismatched.'))
        end

        %% (2022-12-22) Use interpolation to calibrate the sampling frequency for the data columns we care to exactly sam as photometry_fs
        time_axis_new = time_axis_old(1):1/photometry_fs:time_axis_old(end);
        temp_processed_photometry = zeros(numel(time_axis_new),6);
        temp_processed_photometry(:,1) = time_axis_new;
        % (2022-12-22) write a try catch condition to catch rare cases when
        % doric reports duplicated time points in photometry log
        try
            temp_processed_photometry(:,2) = interp1(time_axis_old, (raw_data{:,2}), time_axis_new, 'linear')';
            temp_processed_photometry(:,3) = interp1(time_axis_old, (raw_data{:,3}), time_axis_new, 'linear')';sd
            temp_processed_photometry(:,4) = interp1(time_axis_old, (raw_data{:,5}), time_axis_new, 'linear')';
            temp_processed_photometry(:,5) = interp1(time_axis_old, (raw_data{:,6}), time_axis_new, 'linear')';
            temp_processed_photometry(:,6) = interp1(time_axis_old, (raw_data{:,9}), time_axis_new, 'linear')';
        catch
            warning(strcat("For session: ",behavior_data.session_id, ...
                    " reverting to original time axis for interpolation."));
            [~,unique_idx,~] = unique(time_axis_old);
            temp_processed_photometry(:,2) = interp1(time_axis_old(unique_idx), ...
                (raw_data{unique_idx,2}), time_axis_new, 'linear')';
            temp_processed_photometry(:,3) = interp1(time_axis_old(unique_idx), ...
                (raw_data{unique_idx,3}), time_axis_new, 'linear')';
            temp_processed_photometry(:,4) = interp1(time_axis_old(unique_idx), ...
                (raw_data{unique_idx,5}), time_axis_new, 'linear')';
            temp_processed_photometry(:,5) = interp1(time_axis_old(unique_idx), ...
                (raw_data{unique_idx,6}), time_axis_new, 'linear')';
            temp_processed_photometry(:,6) = interp1(time_axis_old(unique_idx), ...
                (raw_data{unique_idx,9}), time_axis_new, 'linear')';
        end
    else
        time_axis_new = raw_data{:,1}';
        temp_processed_photometry = raw_data{:,:};
    end
    %% (2022-12-22) Process raw data to moving window F0 correctied data: processed_photometry_MWF0
    % using moving median window baseline to calculate correctied
    % photometry, the function 'msbackadj_NtExp' is adjusted from msbackadj
    % from bioinformatic toolbox, but return "Y(:,ns) = (Y(:,ns) - b)./b" instead of "Y(:,ns) = (Y(:,ns) - b)"
    % Window: 360 seconds, #windows = 500
    processed_photometry_MWF0 = zeros(numel(time_axis_new),4);
    processed_photometry_MWF0(:,1) = temp_processed_photometry(:,1);
    processed_photometry_MWF0(:,2) = msbackadj_NtExp( ...
        time_axis_new',temp_processed_photometry(:,3), ...
        'WindowSize',6*60, ...
        'StepSize',session_length*60/900, ...
        'Quantile', 0.5, ...
        'ShowPlot',  'no');
    processed_photometry_MWF0(:,3) = msbackadj_NtExp( ...
        time_axis_new',temp_processed_photometry(:,5), ...
        'WindowSize',6*60, ...
        'StepSize',session_length*60/900, ...
        'Quantile', 0.5, ...
        'ShowPlot',  'no');
    processed_photometry_MWF0(:,4) = temp_processed_photometry(:,6);

    % remove outliers from data
    processed_photometry_MWF0(:,2) = filloutliers(processed_photometry_MWF0(:,2),'linear',"movmedian",500);
    processed_photometry_MWF0(:,3) = filloutliers(processed_photometry_MWF0(:,3),'linear',"movmedian",500);

    %% (2022-12-23) The Trim of photometry data is after MWF0 methods
    % to cut the unstable part  when moving window is not complete,
    % but before Isosbesstic correction to prevent unstable early
    % photometry data causing negatively impact to linear fit between
    % 405 and 465 signals
    [~,idx_start] = min(abs(processed_photometry_MWF0(:,1) - params.drop_buffer_start));
    [~,idx_stop] = min(abs(processed_photometry_MWF0(:,1) - (processed_photometry_MWF0(end,1) ...
        -params.drop_buffer_end)));
    processed_photometry_MWF0 = processed_photometry_MWF0(idx_start:idx_stop,:);
    % Reset time to start at 0 - all data streams are trimmed and time
    % (2022-12-23) shift back the amount of "params.drop_buffer_start"
    % rather than reset directly to 0
    processed_photometry_MWF0(:,1) = processed_photometry_MWF0(:,1) - params.drop_buffer_start;
    processed_photometry_MWF0(:,2) = zscore(processed_photometry_MWF0(:,2));
    processed_photometry_MWF0(:,3) = zscore(processed_photometry_MWF0(:,3));
    % For stability, "idx_start" and "idx_stop" are not reused but find
    % directly from target matrix's time column, though they are
    % supposed to stay same
    [~,idx_start] = min(abs(temp_processed_photometry(:,1) - params.drop_buffer_start));
    [~,idx_stop] = min(abs(temp_processed_photometry(:,1) - (temp_processed_photometry(end,1) ...
        -params.drop_buffer_end)));
    temp_processed_photometry = temp_processed_photometry(idx_start:idx_stop,:);
    temp_processed_photometry(:,1) = temp_processed_photometry(:,1) - params.drop_buffer_start;

    %!!!
    %% Process raw data to isosbestic correctied data: processed_photometry_isos
    % Moving average filter params, 0 phase, (2022-12-22) the Moving average
    % filter is now set based on photometry decimation and params: MA_window
    n = round(photometry_fs*params.MA_window);
    b = ones(n,1)/n;
    a = 1;
    signal_405_channel_1 = filtfilt(b,a,temp_processed_photometry(:,2)); % isosbestic control for mPFC --- fill outliers and moving average filter data
    signal_405_channel_2 = filtfilt(b,a,temp_processed_photometry(:,4)); % isosbestic control for S1

    % Fit a line to the relationship between the true signal and the control
    fit_channel_1 = polyfit(signal_405_channel_1,temp_processed_photometry(:,3),1);
    iso_fit_channel_1 = fit_channel_1(1) .* signal_405_channel_1 + fit_channel_1(2);
    pho_channel_1 = (temp_processed_photometry(:,3) - iso_fit_channel_1(:)) ./ iso_fit_channel_1(:);

    fit_channel_2 = polyfit(signal_405_channel_2,temp_processed_photometry(:,5),1);
    iso_fit_channel_2 = fit_channel_2(1) .* signal_405_channel_2 + fit_channel_2(2);
    pho_channel_2 = (temp_processed_photometry(:,5) - iso_fit_channel_2(:)) ./ iso_fit_channel_2(:);

    processed_photometry_isos = zeros(height(temp_processed_photometry),4);
    processed_photometry_isos(:,1) = temp_processed_photometry(:,1);
    % remove outliers from data
    processed_photometry_isos(:,2) = zscore(filloutliers(pho_channel_1,'linear',"movmedian",500));
    processed_photometry_isos(:,3) = zscore(filloutliers(pho_channel_2,'linear',"movmedian",500));

    %         processed_photometry_isos(:,2) = zscore(movmean(processed_photometry_isos(:,2),params.movmean));
    %         processed_photometry_isos(:,3) = zscore(movmean(processed_photometry_isos(:,3),params.movmean));
    processed_photometry_isos(:,4) = temp_processed_photometry(:,6);


    % Add a condition to downsample if the file is large
    output_fs = round(photometry_fs);
    if photometry_fs > 500
        processed_photometry_MWF0 = downsample(processed_photometry_MWF0,10);
        processed_photometry_isos = downsample(processed_photometry_isos,10);
        output_fs = photometry_fs/10;
    end

    %% Debug mode: send crucial plots to assess the impact of (1) time calibration
    % (2) inconsistency of sampling rate in photometry file, (3) different
    % process methods to session data ann (4) trial data, (5) z-score
    % cutoff
    if params.debug_mode && ~strcmp(behavior_data.training_phase,"Phase 0")
        % (2022-12-22) create a path for store all debug report of one
        % animal together, For each photometry session, debug plots will be
        % appended into one pdf but recording date and time of reporting,
        % also stop plots from popping up.
        folder_name = split(behavior_data.session_id,'_');
        folder_name = folder_name{1};
        debug_report_folder = fullfile(paths.raw_photometry_data,"plot-photometry", folder_name);
        date_now = datetime;
        if ~exist(debug_report_folder, 'dir')
            mkdir(debug_report_folder)
        end
        debug_report_path = fullfile(debug_report_folder, ...
            strcat(behavior_data.session_id,'_photometry_report.pdf'));
        % (1) time calibration: time shifting value vs session ongoing time
        f1 = figure();set(gcf,'Visible', 'off')
        subplot(2,1,1)
        plot(recorded_stim_times, time_shifting_record)
        title('Time misalignment across session','FontSize',8)
        sgtitle({behavior_data.session_id,...
            strcat("Paradigm used: ",behavior_data.paradigm),...
            strcat("Doric downsampling rate: ",num2str(behavior_data.meta_data.photometry.decimation_factor)),...
            strcat("Report generated on: ",string(date_now))}, 'Interpreter', 'none','FontSize',8);
        ylabel("Time difference (t_d_o_r_i_c -t_x_p_c)",'FontSize',8);

        subplot(2,1,2)
        plot(time_axis_old); hold on;
        plot(time_axis_new);
        ylabel('Session duration (s)','FontSize',8)
        xlabel('Data points recorded at Doric','FontSize',8)
        legend('Old time axis','Corrected time axis','FontSize',3,'Location','southeast');
        %%
        exportgraphics(f1,debug_report_path,'Append',true,"Resolution",300,'ContentType','vector');

        %% (2) inconsistency of sampling rate in photometry file, time steps
        % in 5% error range from theoritical time steps is considered as
        % correct time steps.
        f2 = figure(); set(gcf,'Visible', 'off')
        subplot(2,1,1)
        [counts, groups] =groupcounts(diff(raw_data{:,1}));
        hold on
        plot(groups,log10(counts),'r.')
        plot(groups(abs(groups-1/photometry_fs)<0.05/photometry_fs), ...
            log10(counts(abs(groups-1/photometry_fs)<0.05/photometry_fs)),'b.')
        title('Inconsistency in sampling rate','FontSize',8)
        sgtitle({behavior_data.session_id,...
            strcat("Paradigm used: ",behavior_data.paradigm),...
            strcat("Doric downsampling rate: ",num2str(behavior_data.meta_data.photometry.decimation_factor)),...
            strcat("Report generated on: ",string(date_now))}, 'Interpreter', 'none','FontSize',8);
        xlabel("Sample step size",'FontSize',8); ylabel("log(Count of time steps)",'FontSize',8); legend('Unexpected time steps','Expected time steps','FontSize',3)
        subplot(2,1,2)
        temp = raw_data{1:end-1,1};
        histogram(temp(abs(diff(raw_data{1:end-1,1})-1/photometry_fs)>0.05/photometry_fs),60)
        title("Session distribution of the unexpected time steps", ...
            'Interpreter', 'none','FontSize',8);
        xlabel("Session time (s)",'FontSize',8);
        ylabel("Count of unexpected time steps",'FontSize',8);
        %%
        exportgraphics(f2,debug_report_path,'Append',true,"Resolution",300,'ContentType','vector');
        %%

        % (3) Session data using different processing methods
        % Channel 1
        f3 = figure(); set(gcf,'Visible', 'off')
        subplot(2,1,1)
        hold on
        yyaxis left
        plot(raw_data{:,1}, raw_data{:,3}); hold on;
        ylabel('Raw 465 (V)','FontSize',8);
        yyaxis right
        plot(raw_data{:,1}, raw_data{:,2});
        ylabel('Raw 405 (V)','FontSize',8);
        xlim([0,60*session_length])
        legend('Raw 465nm signal','Raw 405nm signal','FontSize',3)

        subplot(2,1,2)
        plot(processed_photometry_isos(:,1) + params.drop_buffer_start,processed_photometry_isos(:,2)); hold on;
        plot(processed_photometry_MWF0(:,1) + params.drop_buffer_start,processed_photometry_MWF0(:,2));
        xlim([0,60*session_length]);
        legend('w/ isosbestic correction','w/ moving window median correction','FontSize',3);
        xlabel("Session time (s)",'Fontsize',8); ylabel("zscore(df/F)",'FontSize',8);

        sgtitle({behavior_data.session_id,strcat("Channel 1 Summary: ", behavior_data.meta_data.photometry.channel_1_region), ...
            strcat("Paradigm used: ",behavior_data.paradigm),...
            strcat("filtfilt window for iso correction is: ",num2str(params.MA_window)),...
            strcat("Report generated on: ",string(date_now))}, 'Interpreter', 'none','FontSize',8);
        %%
        exportgraphics(f3,debug_report_path,'Append',true,"Resolution",300,'ContentType','vector');
        %%
        % Channel 2
        f4= figure(); set(gcf,'Visible', 'off')
        subplot(2,1,1)
        hold on
        yyaxis left
        plot(raw_data{:,1}, raw_data{:,6}); hold on;
        ylabel('Raw 465 (V)','FontSize',8);
        yyaxis right
        plot(raw_data{:,1}, raw_data{:,5});
        ylabel('Raw 405 (V)','FontSize',8);
        xlim([0,60*session_length])
        legend('Raw 465nm signal','Raw 405nm signal','FontSize',3,'Location','southeast')

        subplot(2,1,2)
        plot(processed_photometry_isos(:,1) + params.drop_buffer_start,processed_photometry_isos(:,3)); hold on;
        plot(processed_photometry_MWF0(:,1) + params.drop_buffer_start,processed_photometry_MWF0(:,3));
        xlim([0,60*session_length]);
        legend('w/ isosbestic correction','w/ moving window median correction','FontSize',3,'Location','southeast');
        xlabel("Session time (s)",'Fontsize',8); ylabel("zscore(df/F)",'FontSize',8);

        sgtitle({behavior_data.session_id,strcat("Channel 2 Summary: ", behavior_data.meta_data.photometry.channel_2_region), ...
            strcat("Paradigm used: ",behavior_data.paradigm),...
            strcat("filtfilt window for iso correction is: ",num2str(params.MA_window)),...
            strcat("Report generated on: ",string(date_now))}, 'Interpreter', 'none','FontSize',8);
        exportgraphics(f4,debug_report_path,'Append',true,"Resolution",300,'ContentType','vector');

        %%
        % Extract the matix containing -3 to +6s around the delivery of
        % true stims

        check_trials = true_stim_times(behavior_data.stim_strength > 0);
        trials_channel_1_MWF0 = zeros(9*output_fs+1,length(check_trials)-2);
        trials_channel_2_MWF0 = zeros(9*output_fs+1,length(check_trials)-2);
        trials_channel_1_isos = zeros(9*output_fs+1,length(check_trials)-2);
        trials_channel_2_isos = zeros(9*output_fs+1,length(check_trials)-2);
        trials_channel_1_control = zeros(9*output_fs+1,length(check_trials)-2);
        trials_channel_2_control = zeros(9*output_fs+1,length(check_trials)-2);
        trials_movement = zeros(9*100+1,length(check_trials)-2);

        for i = 1:1:length(check_trials)-4
            [~,trial_center_idx] = min(abs(processed_photometry_MWF0(:,1) - check_trials(i+1)));
            trials_channel_1_MWF0(:,i) = processed_photometry_MWF0( ...
                trial_center_idx-3*output_fs : ...
                trial_center_idx+6*output_fs,2);
            trials_channel_2_MWF0(:,i) = processed_photometry_MWF0( ...
                trial_center_idx-3*output_fs : ...
                trial_center_idx+6*output_fs,3);
            [~,trial_center_idx] = min(abs(processed_photometry_isos(:,1) - check_trials(i+1)));
            trials_channel_1_isos(:,i) = processed_photometry_isos( ...
                trial_center_idx-3*output_fs : ...
                trial_center_idx+6*output_fs,2);
            trials_channel_2_isos(:,i) = processed_photometry_isos( ...
                trial_center_idx-3*output_fs : ...
                trial_center_idx+6*output_fs,3);
            trials_channel_1_control(:,i) = zscore(iso_fit_channel_1( ...
                trial_center_idx-3*output_fs : ...
                trial_center_idx+6*output_fs));
            trials_channel_2_control(:,i) = zscore(iso_fit_channel_2( ...
                trial_center_idx-3*output_fs : ...
                trial_center_idx+6*output_fs));

            [~,wheel_center_idx] = min(abs(behavior_data.wheel_displacement(:,1) - check_trials(i+1)));
            trials_movement(:,i) = abs(zscore(behavior_data.wheel_displacement( ...
                wheel_center_idx-3*100 : ...
                wheel_center_idx+6*100,2) - behavior_data.wheel_displacement(wheel_center_idx-0*100,2)));
        end

        % (5) Session data using different processing methods
        f5= figure(); set(gcf,'Visible', 'off')
        time_trial = -3:1/output_fs:+6;
        time_movement = -3:1/100:+6;

        hold on
        for trial = 1:width(trials_channel_1_control)
            subplot(4,2,1)
            plot(time_trial, trials_channel_1_isos(:,trial),'LineWidth',0.5,'Color',[.7 .7 .7]); hold on;
            subplot(4,2,3)
            plot(time_trial, trials_channel_1_MWF0(:,trial),'LineWidth',0.5,'Color',[.7 .7 .7]); hold on;
            subplot(4,2,5)
            plot(time_trial, trials_channel_1_control(:,trial),'LineWidth',0.5,'Color',[.7 .7 .7]); hold on;
            subplot(4,2,7)
            plot(time_movement, trials_movement(:,trial),'LineWidth',0.5,'Color',[.7 .7 .7]); hold on;
        end
        subplot(4,2,1)
        plot(time_trial, mean(trials_channel_1_isos,2,'omitnan'),'LineWidth',2.0,'Color','r');
        legend('465 Signal with isosbestic correction','Location','southeast','FontSize',3);
        ylabel('Session zscore(df/F)','FontSize',5)
        ylim([-1 2]);xlim([-2 4]);
        title(strcat("Channel 1: ",behavior_data.meta_data.photometry.channel_1_region));
        subplot(4,2,3)
        plot(time_trial, mean(trials_channel_1_MWF0,2,'omitnan'), 'LineWidth',2.0,'Color','g');
        legend('465 Signal with moving window baseline correction','Location','southeast','FontSize',3);
        ylabel('Session zscore(df/F)','FontSize',5)
        ylim([-1 2]);xlim([-2 4]);
        subplot(4,2,5)
        plot(time_trial, mean(trials_channel_1_control,2,'omitnan'), 'LineWidth',2.0,'Color','b');
        legend('405 Signal fit to 465 Signal','Location','southeast','FontSize',3);
        ylabel('Trial zscore(F)','FontSize',5)
        ylim([-1 1]); xlim([-2 4]);
        subplot(4,2,7)
        plot(time_movement, mean(trials_movement,2,'omitnan'),'LineWidth',2.0,'Color','k');
        legend('abs(zscore(Wheel displacement))','Location','southeast','FontSize',3);
        ylabel('Trial zscore','FontSize',5)
        xlabel('Time relative to stim delivery (s)','FontSize',5)
        ylim([0 2]); xlim([-2 4]);
        hold on
        for trial = 1:width(trials_channel_2_control)
            subplot(4,2,2)
            plot(time_trial, trials_channel_2_isos(:,trial),'LineWidth',0.5,'Color',[.7 .7 .7]); hold on;
            subplot(4,2,4)
            plot(time_trial, trials_channel_2_MWF0(:,trial),'LineWidth',0.5,'Color',[.7 .7 .7]); hold on;
            subplot(4,2,6)
            plot(time_trial, trials_channel_2_control(:,trial),'LineWidth',0.5,'Color',[.7 .7 .7]); hold on;
            subplot(4,2,8)
            plot(time_movement, trials_movement(:,trial),'LineWidth',0.5,'Color',[.7 .7 .7]); hold on;
        end
        subplot(4,2,2)
        plot(time_trial, mean(trials_channel_2_isos,2,'omitnan'),'LineWidth',2.0,'Color','r');
        legend('465 Signal with isosbestic correction','Location','southeast','FontSize',3);
        ylim([-1 2]);xlim([-2 4]);
        title(strcat("Channel 2: ",behavior_data.meta_data.photometry.channel_2_region));
        subplot(4,2,4)
        plot(time_trial, mean(trials_channel_2_MWF0,2,'omitnan'), 'LineWidth',2.0,'Color','g');
        legend('465 Signal with moving window baseline correction','Location','southeast','FontSize',3);
        ylim([-1 2]);xlim([-2 4]);
        subplot(4,2,6)
        plot(time_trial, mean(trials_channel_2_control,2,'omitnan'), 'LineWidth',2.0,'Color','b');
        legend('405 Signal fit to 465 Signal','Location','southeast','FontSize',3);
        ylim([-1 1]); xlim([-2 4]);
        subplot(4,2,8)
        plot(time_movement, mean(trials_movement,2,'omitnan'),'LineWidth',2.0,'Color','k');
        legend('abs(zscore(Wheel displacement))','Location','southeast','FontSize',3);
        xlabel('Time relative to stim delivery (s)','FontSize',5)
        ylim([0 2]); xlim([-2 4]);
        sgtitle({behavior_data.session_id, ...
            strcat("Paradigm used: ",behavior_data.paradigm),...
            strcat("Visualizing ",num2str(length(true_stim_times(behavior_data.stim_strength>0))-2)," trials where > 0 stim delivered)"), ...
            strcat("filtfilt window for iso correction is: ",num2str(params.MA_window)), ...
            strcat("Report generated on: ",string(date_now))}, 'Interpreter', 'none','FontSize',8);


        %%
        exportgraphics(f5,debug_report_path,'Append',true,"Resolution",300,'ContentType','vector');

    end

    % debug mode: remove outliers
    %     hold on
    %     ttt = 1:1:length(pho_mPFC);
    %     plot(ttt, pho_mPFC)
    %     plot(ttt(abs(zscore(pho_mPFC))>4), pho_mPFC(abs(zscore(pho_mPFC))>4),'g.')
    %     plot(ttt(abs(zscore(pho_mPFC))>6), pho_mPFC(abs(zscore(pho_mPFC))>6),'r.')

    % else
    %     % Simplified for phase 0 right now.
    %     temp_processed_photometry(:,1) = raw_data(:,1);
    %     temp_processed_photometry(:,2) = filtfilt(b,a,raw_data(:,2)); % isosbestic control for mPFC --- fill outliers and moving average filter data
    %     temp_processed_photometry(:,3) = raw_data(:,3);%filtfilt(b,a,raw_data(:,3)); % signal of interest for mPFC
    %     temp_processed_photometry(:,4) = filtfilt(b,a,raw_data(:,5)); % isosbestic control for S1
    %     temp_processed_photometry(:,5) = raw_data(:,6);%filtfilt(b,a,raw_data(:,6)); % signal of interest for S1
    %     temp_processed_photometry(:,6) = raw_data(:,9);
    %
    %     % Fit a line to the relationship between the true signal and the control
    %     fit_channel_1 = polyfit(temp_processed_photometry(:,2),temp_processed_photometry(:,3),1);
    %     iso_fit_channel_1 = fit_channel_1(1) .* temp_processed_photometry(:,2) + fit_channel_1(2);
    %     pho_channel_1 = (temp_processed_photometry(:,3) - iso_fit_channel_1(:)) ./ iso_fit_channel_1(:);
    %
    %     fit_channel_2 = polyfit(temp_processed_photometry(:,4),temp_processed_photometry(:,5),1);
    %     iso_fit_channel_2 = fit_channel_2(1) .* temp_processed_photometry(:,4) + fit_channel_2(2);
    %     pho_channel_2 = (temp_processed_photometry(:,5) - iso_fit_channel_2(:)) ./ iso_fit_channel_2(:);
    %
    %     temp2_processed_photometry(:,1) = temp_processed_photometry(:,1);
    %     temp2_processed_photometry(:,2) = pho_channel_1;
    %     temp2_processed_photometry(:,3) = pho_channel_2;
    %     temp2_processed_photometry(:,4) = temp_processed_photometry(:,6);
    %
    %     processed_photometry_isos = temp2_processed_photometry;

    % If doric data is not found, automatically check if this is a py
    % photometry session
elseif(~isempty(dir(fullfile(paths.raw_photometry_data,strcat(behavior_data.session_id_alt,'*.csv')))))

    photometry_to_load = dir(fullfile(paths.raw_photometry_data,strcat(behavior_data.session_id_alt,'*.csv')));

    raw_data = readtable(fullfile(paths.raw_photometry_data,photometry_to_load.name),'ReadVariableNames',false);
    behavior_data.meta_data.photometry.decimation_factor = 1; % starting factor for py photometry
    
    if ischar(behavior_data.meta_data.photometry.photometry_fs) || behavior_data.meta_data.photometry.photometry_fs < 10
        behavior_data.meta_data.photometry.photometry_fs = 100; 
    end 

    
    % trim photometry data to include only when xPC was sending tprocessRawriggers1,
    % (2022-12-22)and remove nan values in columns we care for compatibility
    raw_data = raw_data(raw_data{:,4}==1,:);

    % Se a QC factor to make sure the number of samples recorded matches
    % the session duration:
    QC_photo_deci = behavior_data.meta_data.photometry.photometry_fs*session_length*60 ...
        /height(raw_data)/behavior_data.meta_data.photometry.decimation_factor;
    if QC_photo_deci > 3 || QC_photo_deci < 0.33
        corrected_photo_deci = round( ...
            behavior_data.meta_data.photometry.decimation_factor*QC_photo_deci, ...
            1, 'significant');
        warning(strcat("For session: ",behavior_data.session_id, ...
            " the photometry decimation factor recorded: ", ...
            num2str(behavior_data.meta_data.photometry.decimation_factor),...
            " does not match with photometry data length, and is automatically corrected to ",...
            num2str(corrected_photo_deci),". Further investigation is required."))
        behavior_data.meta_data.photometry.decimation_factor = corrected_photo_deci;
    end
    
    photometry_fs = behavior_data.meta_data.photometry.photometry_fs/...
    behavior_data.meta_data.photometry.decimation_factor;
    
    % Some sessions were cut short for photometry recordings, if this is
    % obviously the case, skip the processing
    if photometry_fs > 98
        % (Unresolved) Right now phase 0 is not handled very complexly, eventually we should
        % bring it up-to-date with the other phases
    
        % (Unresolved) we need better way of compatibility check than the current one
        if ~strcmp(behavior_data.training_phase,"Phase 0")
            % find time of true stimulus signals in behavior log
            true_stim_times = behavior_data.stim_times; %(behavior_data.stim_strength > 0);
            % find time of the rising edge of true stimulus trigger in
            % photometry log in trimmed range
            [recorded_stim_times,~] = find(diff(raw_data{:,3}==1));
            recorded_stim_times = recorded_stim_times/photometry_fs;
            recorded_stim_times = recorded_stim_times(recorded_stim_times > params.drop_buffer_start ...
                & recorded_stim_times < (session_length*60 - params.drop_buffer_end));
    
            %% (2022-12-22) This code performs time synchronization between two data sets: recorded_stim_times and true_stim_times.
            % The loop iterates over the recorded stimulus times in reverse order (from the last element to the first).
            % For each recorded stimulus time, the code finds the true stimulus time that is closest.
            % If the absolute value of the difference between the recorded stimulus time and the closest true stimulus time is greater than 0.5 seconds before or 0.5 seconds after,
            % a warning is issued. If neither of these conditions is met, the code calculates the time shift between the recorded stimulus time and the closest true stimulus.
            % This time shift is used to adjust the timestamps in the raw_data array, starting from the end of timestamps until the start.
            % The value of calibr_end is updated to the index of the recorded stimulus time, so that the next iteration of the loop will start adjusting timestamps from the previous recorded stimulus time.
            % If the params.debug_mode flag is set, the time shift is recorded in for latter plotting.
            calibr_end = length(raw_data{:,1})+1;
            time_shifting_record = [];
            time_axis_old = (1:length(raw_data{:,1}))/photometry_fs';
            N_unmatched_trigger = 0;
            for i = length(recorded_stim_times):-1:1
                [time_shift_abs,idx] = min(abs(recorded_stim_times(i) - params.drop_buffer_start - true_stim_times));
                % (2022-12-23) if delete the 'continue skip' for loops with
                % time_shift_abs >5, Bugs will emerge to shift the time axis
                % wrongly when there is no matching triggers from
                % behavior_data, so I change this part back and deal with
                % overflow of warnings in later part
                if time_shift_abs > 5
                    % (Unresolved) a temporary solution: trials close to trim
                    % start and end are not counted in unmatch bases and wont
                    % be reported in warnings
                    if ~(i == length(recorded_stim_times) || i == 1)
                        N_unmatched_trigger = N_unmatched_trigger+1;
                    end
    
                    if params.debug_mode
                        time_shifting_record = [0,time_shifting_record];
                    end
                    continue
                elseif time_shift_abs > 0.5
                    warning(strcat('For session: ',behavior_data.session_id, ...
                        ', The stim trigger-',num2str(i), ...
                        ' recorded by photometry log has a time shifting = ', num2str(time_shift_abs),...
                        's, this data session should be considered as unreliable and excluded'))
                    if params.debug_mode
                        time_shifting_record = [0,time_shifting_record];
                    end
                    continue
                end
                calibr_value = recorded_stim_times(i) - params.drop_buffer_start - true_stim_times(idx);
                [~,recorded_stim_time_idx] = min(abs(((1:length(raw_data{:,1}))/photometry_fs)-recorded_stim_times(i)));
                time_axis_old(1,recorded_stim_time_idx:calibr_end-1) = ...
                    time_axis_old(1,recorded_stim_time_idx:calibr_end-1) - calibr_value;
                calibr_end = recorded_stim_time_idx;
                if params.debug_mode
                    time_shifting_record = [calibr_value,time_shifting_record];
                end
            end
    
            % (2022-12-23) to prevent multiple warnings cover important
            % message, now the number of unmatched triggers are cumulated and
            % report at once
            if N_unmatched_trigger > 0
                warning(strcat('For session: ',behavior_data.session_id, ...
                    ", There are in total  ",num2str(N_unmatched_trigger), ...
                    ' stim triggers recorded by photometry log without matching  ', ...
                    ' triggers from XPC in 5 seconds, the two files could be mismatched.'))
            end
    
            %% (2022-12-22) Use interpolation to calibrate the sampling frequency for the data columns we care to exactly sam as photometry_fs
            time_axis_new = time_axis_old(1):1/photometry_fs:time_axis_old(end);
    
            temp_processed_photometry(:,1) = time_axis_new;
    
            try
                temp_processed_photometry(:,2) = interp1(time_axis_old, (raw_data{:,1}), time_axis_new, 'linear')';
                temp_processed_photometry(:,3) = interp1(time_axis_old, (raw_data{:,2}), time_axis_new, 'linear')';
                temp_processed_photometry(:,4) = ceil(interp1(time_axis_old, (raw_data{:,3}), time_axis_new, 'linear')');
            catch
                warning(strcat("For session: ",behavior_data.session_id, ...
                    " reverting to original time axis for interpolation."));
                [~,unique_idx,~] = unique(time_axis_old);
                temp_processed_photometry(:,2) = interp1(time_axis_old(unique_idx), ...
                    (raw_data{unique_idx,1}), time_axis_new, 'linear')';
                temp_processed_photometry(:,3) = interp1(time_axis_old(unique_idx), ...
                    (raw_data{unique_idx,2}), time_axis_new, 'linear')';
                temp_processed_photometry(:,4) = ceil(interp1(time_axis_old(unique_idx), ...
                    (raw_data{unique_idx,3}), time_axis_new, 'linear')');
            end
        else
            time_axis_new = time_axis_old;
            temp_processed_photometry = raw_data{:,:};
        end
        %% (2022-12-22) Process raw data to moving window F0 correctied data: processed_photometry_MWF0
        % using moving median window baseline to calculate correctied
        % photometry, the function 'msbackadj_NtExp' is adjusted from msbackadj
        % from bioinformatic toolbox, but return "Y(:,ns) = (Y(:,ns) - b)./b" instead of "Y(:,ns) = (Y(:,ns) - b)"
        % Window: 360 seconds, #windows = 500
        processed_photometry_MWF0 = zeros(numel(time_axis_new),3);
        processed_photometry_MWF0(:,1) = temp_processed_photometry(:,1);
        processed_photometry_MWF0(:,2) = msbackadj_NtExp( ...
            time_axis_new',temp_processed_photometry(:,2), ...
            'WindowSize',4*60, ...
            'StepSize',session_length*60/900, ...
            'Quantile', 0.5, ...
            'ShowPlot',  'no');
        processed_photometry_MWF0(:,3) = temp_processed_photometry(:,4);
    
        % remove outliers from data
        processed_photometry_MWF0(:,2) = filloutliers(processed_photometry_MWF0(:,2),'linear',"movmedian",200);
    
        %% (2022-12-23) The Trim of photometry data is after MWF0 methods
        % to cut the unstable part  when moving window is not complete,
        % but before Isosbesstic correction to prevent unstable early
        % photometry data causing negatively impact to linear fit between
        % 405 and 465 signals
        [~,idx_start] = min(abs(processed_photometry_MWF0(:,1) - params.drop_buffer_start));
        [~,idx_stop] = min(abs(processed_photometry_MWF0(:,1) - (processed_photometry_MWF0(end,1) ...
            -params.drop_buffer_end)));
        processed_photometry_MWF0 = processed_photometry_MWF0(idx_start:idx_stop,:);
        % Reset time to start at 0 - all data streams are trimmed and time
        % (2022-12-23) shift back the amount of "params.drop_buffer_start"
        % rather than reset directly to 0
        processed_photometry_MWF0(:,1) = processed_photometry_MWF0(:,1) - params.drop_buffer_start;
        processed_photometry_MWF0(:,2) = zscore(processed_photometry_MWF0(:,2));
        processed_photometry_MWF0(:,3) = zscore(processed_photometry_MWF0(:,3));
        % For stability, "idx_start" and "idx_stop" are not reused but find
        % directly from target matrix's time column, though they are
        % supposed to stay same
        [~,idx_start] = min(abs(temp_processed_photometry(:,1) - params.drop_buffer_start));
        [~,idx_stop] = min(abs(temp_processed_photometry(:,1) - (temp_processed_photometry(end,1) ...
            -params.drop_buffer_end)));
        temp_processed_photometry = temp_processed_photometry(idx_start:idx_stop,:);
        temp_processed_photometry(:,1) = temp_processed_photometry(:,1) - params.drop_buffer_start;
    
        %!!!
        %% Process raw data to isosbestic correctied data: processed_photometry_isos
        % Moving average filter params, 0 phase, (2022-12-22) the Moving average
        % filter is now set based on photometry decimation and params: MA_window
        n = ceil(photometry_fs*params.MA_window);
        b = ones(n,1)/n;
        a = 1;
        signal_405_channel_1 = filtfilt(b,a,temp_processed_photometry(:,2)); % isosbestic control for mPFC --- fill outliers and moving average filter data
        % Fit a line to the relationship between the true signal and the control
        fit_channel_1 = polyfit(signal_405_channel_1,temp_processed_photometry(:,3),1);
        iso_fit_channel_1 = fit_channel_1(1) .* signal_405_channel_1 + fit_channel_1(2);
        pho_channel_1 = (temp_processed_photometry(:,2) - iso_fit_channel_1(:)) ./ iso_fit_channel_1(:);
    
        processed_photometry_isos = zeros(height(temp_processed_photometry),3);
        processed_photometry_isos(:,1) = temp_processed_photometry(:,1);
        % remove outliers from data
        processed_photometry_isos(:,2) = zscore(filloutliers(pho_channel_1,'linear',"movmedian",100));
    
        processed_photometry_isos(:,3) = temp_processed_photometry(:,4);
    
    
        % Add a condition to downsample if the file is large
        output_fs = photometry_fs;
        if photometry_fs > 500
            processed_photometry_MWF0 = downsample(processed_photometry_MWF0,10);
            processed_photometry_isos = downsample(processed_photometry_isos,10);
            output_fs = photometry_fs/10;
        end
    
        %% Debug mode: send crucial plots to assess the impact of (1) time calibration
        % (2) inconsistency of sampling rate in photometry file, (3) different
        % process methods to session data ann (4) trial data, (5) z-score
        % cutoff
        if params.debug_mode && ~strcmp(behavior_data.training_phase,"Phase 0")
            % (2022-12-22) create a path for store all debug report of one
            % animal together, For each photometry session, debug plots will be
            % appended into one pdf but recording date and time of reporting,
            % also stop plots from popping up.
            folder_name = split(behavior_data.session_id,'_');
            folder_name = folder_name{1};
            debug_report_folder = fullfile(paths.raw_photometry_data,"plot-photometry", folder_name);
            date_now = datetime;
            if ~exist(debug_report_folder, 'dir')
                mkdir(debug_report_folder)
            end
            debug_report_path = fullfile(debug_report_folder, ...
                strcat(behavior_data.session_id,'_photometry_report.pdf'));
            % (1) time calibration: time shifting value vs session ongoing time
            f1 = figure();set(gcf,'Visible', 'off')
            subplot(2,1,1)
            plot(recorded_stim_times, time_shifting_record(1:length(recorded_stim_times)))
            title('Time misalignment across session','FontSize',8)
            sgtitle({behavior_data.session_id,...
                strcat("Paradigm used: ",behavior_data.paradigm),...
                strcat("Pyphotometry downsampling rate: ",num2str(behavior_data.meta_data.photometry.decimation_factor)),...
                strcat("Report generated on: ",string(date_now))}, 'Interpreter', 'none','FontSize',8);
            ylabel("Time difference (t_p_y -t_x_p_c)",'FontSize',8);
    
            subplot(2,1,2)
            plot(time_axis_old); hold on;
            plot(time_axis_new);
            ylabel('Session duration (s)','FontSize',8)
            xlabel('Data points recorded at Pyphotometry','FontSize',8)
            legend('Old time axis','Corrected time axis','FontSize',3,'Location','southeast');
            %%
            exportgraphics(f1,debug_report_path,'Append',true,"Resolution",300,'ContentType','vector');
    
            %% (2) inconsistency of sampling rate in photometry file, time steps
            % in 5% error range from theoritical time steps is considered as
            % correct time steps.
            f2 = figure(); set(gcf,'Visible', 'off')
            subplot(2,1,1)
            [counts, groups] =groupcounts(diff(raw_data{:,1}));
            hold on
            plot(groups,log10(counts),'r.')
            plot(groups(abs(groups-1/photometry_fs)<0.05/photometry_fs), ...
                log10(counts(abs(groups-1/photometry_fs)<0.05/photometry_fs)),'b.')
            title('Inconsistency in sampling rate','FontSize',8)
            sgtitle({behavior_data.session_id,...
                strcat("Paradigm used: ",behavior_data.paradigm),...
                strcat("Pyphotometry downsampling rate: ",num2str(behavior_data.meta_data.photometry.decimation_factor)),...
                strcat("Report generated on: ",string(date_now))}, 'Interpreter', 'none','FontSize',8);
            xlabel("Sample step size",'FontSize',8); ylabel("log(Count of time steps)",'FontSize',8); legend('Unexpected time steps','Expected time steps','FontSize',3)
            subplot(2,1,2)
            temp = raw_data{1:end-1,1};
            histogram(temp(abs(diff(raw_data{1:end-1,1})-1/photometry_fs)>0.05/photometry_fs),60)
            title("Session distribution of the unexpected time steps", ...
                'Interpreter', 'none','FontSize',8);
            xlabel("Session time (s)",'FontSize',8);
            ylabel("Count of unexpected time steps",'FontSize',8);
            %%
            exportgraphics(f2,debug_report_path,'Append',true,"Resolution",300,'ContentType','vector');
            %%
    
            % (3) Session data using different processing methods
            % Channel 1
            f3 = figure(); set(gcf,'Visible', 'off')
            subplot(2,1,1)
            hold on
            yyaxis left
            plot(time_axis_old', raw_data{:,2}); hold on;
            ylabel('Raw 465 (V)','FontSize',8);
            yyaxis right
            plot(time_axis_old', raw_data{:,1});
            ylabel('Raw 405 (V)','FontSize',8);
            xlim([0,60*session_length])
            legend('Raw 465nm signal','Raw 405nm signal','FontSize',3)
    
            subplot(2,1,2)
            plot(processed_photometry_isos(:,1) + params.drop_buffer_start,processed_photometry_isos(:,2)); hold on;
            plot(processed_photometry_MWF0(:,1) + params.drop_buffer_start,processed_photometry_MWF0(:,2));
            xlim([0,60*session_length]);
            legend('w/ isosbestic correction','w/ moving window median correction','FontSize',3);
            xlabel("Session time (s)",'Fontsize',8); ylabel("zscore(df/F)",'FontSize',8);
    
            sgtitle({behavior_data.session_id,strcat("Channel 1 Summary: ", behavior_data.meta_data.photometry.channel_1_region), ...
                strcat("Paradigm used: ",behavior_data.paradigm),...
                strcat("filtfilt window for iso correction is: ",num2str(params.MA_window)),...
                strcat("Report generated on: ",string(date_now))}, 'Interpreter', 'none','FontSize',8);
            %%
            exportgraphics(f3,debug_report_path,'Append',true,"Resolution",300,'ContentType','vector');
    
    
            %%
            % Extract the matix containing -3 to +6s around the delivery of
            % true stims
    
            check_trials = true_stim_times(behavior_data.stim_strength > 0);
            trials_channel_1_MWF0 = zeros(9*output_fs+1,length(check_trials)-2);
            trials_channel_1_isos = zeros(9*output_fs+1,length(check_trials)-2);
            trials_channel_1_control = zeros(9*output_fs+1,length(check_trials)-2);
            trials_movement = zeros(9*100+1,length(check_trials)-2);
    
            for i = 1:1:length(check_trials)-3
                [~,trial_center_idx] = min(abs(processed_photometry_MWF0(:,1) - check_trials(i+1)));
                trials_channel_1_MWF0(:,i) = processed_photometry_MWF0( ...
                    trial_center_idx-3*output_fs : ...
                    trial_center_idx+6*output_fs,2);
                trials_channel_2_MWF0(:,i) = processed_photometry_MWF0( ...
                    trial_center_idx-3*output_fs : ...
                    trial_center_idx+6*output_fs,3);
                [~,trial_center_idx] = min(abs(processed_photometry_isos(:,1) - check_trials(i+1)));
                trials_channel_1_isos(:,i) = processed_photometry_isos( ...
                    trial_center_idx-3*output_fs : ...
                    trial_center_idx+6*output_fs,2);
                trials_channel_2_isos(:,i) = processed_photometry_isos( ...
                    trial_center_idx-3*output_fs : ...
                    trial_center_idx+6*output_fs,3);
                trials_channel_1_control(:,i) = zscore(iso_fit_channel_1( ...
                    trial_center_idx-3*output_fs : ...
                    trial_center_idx+6*output_fs));
    
                [~,wheel_center_idx] = min(abs(behavior_data.wheel_displacement(:,1) - check_trials(i+1)));
                trials_movement(:,i) = abs(zscore(behavior_data.wheel_displacement( ...
                    wheel_center_idx-3*100 : ...
                    wheel_center_idx+6*100,2) - behavior_data.wheel_displacement(wheel_center_idx-0*100,2)));
            end
    
            % (5) Session data using different processing methods
            f5= figure(); set(gcf,'Visible', 'off')
            time_trial = -3:1/output_fs:+6;
            time_movement = -3:1/100:+6;
    
            hold on
            for trial = 1:width(trials_channel_1_control)
                subplot(4,2,1)
                plot(time_trial, trials_channel_1_isos(:,trial),'LineWidth',0.5,'Color',[.7 .7 .7]); hold on;
                subplot(4,2,3)
                plot(time_trial, trials_channel_1_MWF0(:,trial),'LineWidth',0.5,'Color',[.7 .7 .7]); hold on;
                subplot(4,2,5)
                plot(time_trial, trials_channel_1_control(:,trial),'LineWidth',0.5,'Color',[.7 .7 .7]); hold on;
                subplot(4,2,7)
                plot(time_movement, trials_movement(:,trial),'LineWidth',0.5,'Color',[.7 .7 .7]); hold on;
            end
            subplot(4,2,1)
            plot(time_trial, mean(trials_channel_1_isos,2,'omitnan'),'LineWidth',2.0,'Color','r');
            legend('465 Signal with isosbestic correction','Location','southeast','FontSize',3);
            ylabel('Session zscore(df/F)','FontSize',5)
            ylim([-1 2]);xlim([-2 4]);
            title(strcat("Channel 1: ",behavior_data.meta_data.photometry.channel_1_region));
            subplot(4,2,3)
            plot(time_trial, mean(trials_channel_1_MWF0,2,'omitnan'), 'LineWidth',2.0,'Color','g');
            legend('465 Signal with moving window baseline correction','Location','southeast','FontSize',3);
            ylabel('Session zscore(df/F)','FontSize',5)
            ylim([-1 2]);xlim([-2 4]);
            subplot(4,2,5)
            plot(time_trial, mean(trials_channel_1_control,2,'omitnan'), 'LineWidth',2.0,'Color','b');
            legend('405 Signal fit to 465 Signal','Location','southeast','FontSize',3);
            ylabel('Trial zscore(F)','FontSize',5)
            ylim([-1 1]); xlim([-2 4]);
            subplot(4,2,7)
            plot(time_movement, mean(trials_movement,2,'omitnan'),'LineWidth',2.0,'Color','k');
            legend('abs(zscore(Wheel displacement))','Location','southeast','FontSize',3);
            ylabel('Trial zscore','FontSize',5)
            xlabel('Time relative to stim delivery (s)','FontSize',5)
            ylim([0 2]); xlim([-2 4]);
            hold on
    
            %%
            exportgraphics(f5,debug_report_path,'Append',true,"Resolution",300,'ContentType','vector');
        end
    
        % Final QC
        if N_unmatched_trigger > 3
            processed_photometry_isos = [];
            processed_photometry_MWF0 = [];
    
            display(strcat("The photometry for session ", behavior_data.session_id, "did not pass QC and will not be saved."))
        end
    
    else
        processed_photometry_isos = [];
        processed_photometry_MWF0 = [];

        display(strcat("The photometry for session ", behavior_data.session_id, " appears to have been prematurely truncated. Skipping this session."))
    end

else
    processed_photometry_isos = [];
    processed_photometry_MWF0 = [];

    display(strcat("The photometry for session ", behavior_data.session_id, " does not exist. Please check data integrity."))
end

end


