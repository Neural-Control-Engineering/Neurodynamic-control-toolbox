clc; clear; close all;
%Datastore file on GDrive
%TODO: Make super plot of Pysch Curve strat. by Basline Pupil and slope
%TODO: Add Exponential fit to data

%Note only whisker stuff on 240-243

% Specify the directory where you want to save the figure
% Be sure to use the Drive Shortcut
inputDirectory = "G:\.shortcut-targets-by-id\1yB5u8zHl-aBucQQEQZIgnPdQ1Re2j-5E\Project_Neurotransmitter-Exploration\Datastores\240-R-mPFC-S1-NE\240-R-mPFC-S1-NE_Datastore_created_19-Jun-2023.mat";

pattern = '(?<=\\|/)[^\\|/]*(?=\\|/[^\\|/]*$)';
tokens = regexp(inputDirectory, pattern, 'match');
animalName = tokens{end}

outputDirectory = "C:\Users\Gabog\Downloads\Proj_NT_Exp Plots\Ported SSD\"+animalName;
mkdir(outputDirectory);  % '.png' can be replaced with other formats such as '.jpg', '.pdf', etc.
%%
dstor = load(inputDirectory);
% datastore = dstor.combinedTable;
datastore = dstor.Datastore;

disp(size(datastore))
% 
% % Logical arrays for non-empty rows in each column
% nonEmpty_ch1 = ~cellfun(@isempty, datastore.photometry_ch1);
% nonEmpty_ch2 = ~cellfun(@isempty, datastore.photometry_ch2);
% nonEmpty_pupil_area = ~cellfun(@isempty, datastore.pupil_area);
% nonEmpty_whisker_rad = ~cellfun(@isempty, datastore.whisker_rad);
% 
% % Logical array for non-empty rows in all of the columns
% nonEmpty_all = nonEmpty_ch1 & nonEmpty_ch2 & nonEmpty_pupil_area & nonEmpty_whisker_rad;
% 
% % Filter out the rows where any of 'photometry_ch1', 'photometry_ch2', 'pupil_area' are empty
% datastore = datastore(nonEmpty_all, :);
% datastore = datastore(2:end, :);
% [r, c] = size(datastore);
% 
% datastore = datastore(datastore.paradigm ~= "SSD_Simplified_Phase_III_20MIN", :);

[r, c] = size(datastore);

% Checking if any of the two channels are swapped
% Find the most frequently occurring reference in photometry_region_ch1
[uniqueValues_ch1, ~, occurrences_ch1] = unique(datastore.photometry_region_ch1, 'stable');
count_ch1 = accumarray(occurrences_ch1, 1);
[~, idx_mode_ch1] = max(count_ch1);
mode_ch1 = uniqueValues_ch1{idx_mode_ch1};

% Find the most frequently occurring reference in photometry_region_ch2
[uniqueValues_ch2, ~, occurrences_ch2] = unique(datastore.photometry_region_ch2, 'stable');
count_ch2 = accumarray(occurrences_ch2, 1);
[~, idx_mode_ch2] = max(count_ch2);
mode_ch2 = uniqueValues_ch2{idx_mode_ch2};

% Find rows where photometry_region_ch1 does not match the mode of ch1
% or photometry_region_ch2 does not match the mode of ch2
rows_to_swap = ~(strcmp(datastore.photometry_region_ch1, mode_ch1) & strcmp(datastore.photometry_region_ch2, mode_ch2));

% Iterate through each variable in the table
varNames = datastore.Properties.VariableNames;
for i = 1:numel(varNames)
    if endsWith(varNames{i}, '_ch1')
        % Find the corresponding ch2 column
        ch2_column = strrep(varNames{i}, '_ch1', '_ch2');
        % Swap the values in ch1 and ch2 for the identified rows
        tmp = datastore.(varNames{i})(rows_to_swap);
        datastore.(varNames{i})(rows_to_swap) = datastore.(ch2_column)(rows_to_swap);
        datastore.(ch2_column)(rows_to_swap) = tmp;
    end
end
for i = 1:length(find(rows_to_swap))
    found_idx = find(rows_to_swap);
    disp("Swapped Channels for Row " + string(found_idx(i)));
end

%%
% Task 1: Overview Table
paradigms = unique(datastore.paradigm);
nParadigms = numel(paradigms);
sessionCounts = zeros(nParadigms, 1);
trialCounts = zeros(nParadigms, 1);

for i = 1:nParadigms
    paradigmData = datastore(strcmp(datastore.paradigm, paradigms{i}), :);
    sessionCounts(i) = numel(unique(paradigmData.session_id));
    trialCounts(i) = size(paradigmData, 1);
end

% Create the table and display it or save to a file
overviewTable = table(paradigms, sessionCounts, trialCounts, ...
                      'VariableNames', {'Paradigm', 'Sessions', 'Trials'});
disp(overviewTable);

% Task 2: Average + SEM Psychometric Curve with shadedErrorBar
uniqueParadigms = unique(datastore.paradigm);
figure;
hold on;

puffs = unique(datastore.stimulus_strength); % Assuming stimulus_strength represents puffs

% Plot each unique session's psychometric curve in grey
uniqueSessions = unique(datastore.session_id); % Assuming there is a 'session' column
for s = 1:numel(uniqueSessions)
    sessionData = datastore(strcmp(datastore.session_id, uniqueSessions{s}), :);
    psycho_curve = sessionData.pscho_curve{1}; % Assuming psycho_curve is stored in cell arrays
    plot(psycho_curve(1, :) * 10, psycho_curve(2, :), 'Color', [0.7, 0.7, 0.7, 0.5], 'LineWidth', 1); % Assuming PSI and performance are stored in psycho_curve
end

% Plot the average with SEM
for p = 1:numel(uniqueParadigms)
    paradigmData = datastore(strcmp(datastore.paradigm, uniqueParadigms{p}), :);
    % Use the provided function to calculate the psychometric curve and SEM
    psychometric_performance = calculatePsychometricCurvesSEM(...
        paradigmData.stimulus_strength, ...
        paradigmData.go_nogo, ... % Assuming go_nogo is the binary response
        'Phase III', ... % Assuming phase is in column 'phase'
        puffs ...
    );
    
    % Plot the data with shadedErrorBar
    shadedErrorBar(...
        psychometric_performance(1, :)*10, ... % x-axis (puffs)
        psychometric_performance(2, :), ... % y-axis (psychometric performance)
        psychometric_performance(3, :), ...  % error (SEM)
        'lineprops', '-' ...
    );
end

hold off;
title('2: Average Psychometric Curves with Individual Session Curves');
xlabel('Stimulus PSI');
ylabel('Psychometric Performance');
f = get(gca,'Children');
legend([f(1),f(end)], [uniqueParadigms, 'Session Curves']);


% Task 3: Histogram of Baseline Pupil Sizes
figure;
if iscell(datastore.pupil_base_before_stimulus)
    pupil_base_before_stim = cell2mat(datastore.pupil_base_before_stimulus);
else
    pupil_base_before_stim = datastore.pupil_base_before_stimulus;
end
histogram(pupil_base_before_stim);
title('3: Histogram of Baseline Pupil Sizes');
xlabel('Baseline Pupil Size');
ylabel('Frequency');

% Task 4: Average pupil traces with time aligned to stimulus_time, stratified by stimulus strength

% Set whether to plot global_pupil_avg
global_pupil_avg = 1;
% Calculate the sample rate from the first non-empty pupil matrix
firstNonEmptyIndex = find(~cellfun(@isempty, datastore.pupil_area), 1);
timeDiff = diff(datastore.pupil_area{firstNonEmptyIndex}(1:2, 1));
pupil_fs = 1 / timeDiff;

% Extract unique stimulus strengths
uniqueStimStrengths = unique(datastore.stimulus_strength);

% Initialize average pupil trace matrix
numPreStimSamples = ceil(1.5 * pupil_fs); % 1.5 seconds before stimulus
numPostStimSamples = ceil(5 * pupil_fs); % 5 seconds after stimulus

figure;
hold on;

% Loop over unique stimulus strengths
for s = 1:numel(uniqueStimStrengths)
    stimStrength = uniqueStimStrengths(s);
    stimData = datastore(datastore.stimulus_strength == stimStrength, :);
    
    % Initialize a matrix to store pupil traces for current stimulus strength
    pupilTraces = [];
    
    % Loop over each trial with current stimulus strength
    for t = 1:height(stimData)
        pupilData = stimData.pupil_area{t}; % Assuming pupil_area is a cell array of matrices
        if ~isempty(pupilData)
            stimulusTime = stimData.stimulus_time(t);
            
            % Find the index of stimulusTime in the pupilData
            [~, stimIdx] = min(abs(pupilData(:, 1) - stimulusTime));
            
            % Extract relevant window around the stimulus
            startIndex = max(1, stimIdx - numPreStimSamples);
            endIndex = min(size(pupilData, 1), stimIdx + numPostStimSamples);
            try
                pupilTraces(:, end+1) = pupilData(startIndex:endIndex, 2); % Column 2 is the pupil area
            catch e
                fprintf(1,'The identifier was:\n%s',e.identifier);
                fprintf(1,'There was an error! The message was:\n%s', e.message);
            end
        else
            disp(strcat("Index ", string(t), " Pupil Traces is Empty"))
        end
    end
    
    % Compute average pupil trace
    avgPupilTrace = mean(pupilTraces, 2);
    semPupilTrace = std(pupilTraces, 0, 2) / sqrt(size(pupilTraces, 2)); % Compute SEM
    
    % Plotting the average pupil trace for current stimulus strength with SEM shaded region
    shadedErrorBar((-numPreStimSamples:numPostStimSamples) / pupil_fs, avgPupilTrace, semPupilTrace, 'lineprops', '-');
end

% Plotting global average (black line)
if global_pupil_avg
    stimData = datastore;
    for t = 1:height(stimData)
        pupilData = stimData.pupil_area{t}; % Assuming pupil_area is a cell array of matrices
        if ~isempty(pupilData)
            stimulusTime = stimData.stimulus_time(t);
            
            % Find the index of stimulusTime in the pupilData
            [~, stimIdx] = min(abs(pupilData(:, 1) - stimulusTime));
            
            % Extract relevant window around the stimulus
            startIndex = max(1, stimIdx - numPreStimSamples);
            endIndex = min(size(pupilData, 1), stimIdx + numPostStimSamples);
            try
                pupilTraces(:, end+1) = pupilData(startIndex:endIndex, 2); % Column 2 is the pupil area
            catch e
                fprintf(1,'The identifier was:\n%s',e.identifier);
                fprintf(1,'There was an error! The message was:\n%s', e.message);
            end
        else
            disp(strcat("Index ", string(t), " Pupil Traces is Empty"))
        end
    end
    
    % Compute average pupil trace
    avgPupilTrace = mean(pupilTraces, 2);
    semPupilTrace = std(pupilTraces, 0, 2) / sqrt(size(pupilTraces, 2)); % Compute SEM
    
    % Plotting the average pupil trace for current stimulus strength with SEM shaded region
    shadedErrorBar((-numPreStimSamples:numPostStimSamples) / pupil_fs, avgPupilTrace, semPupilTrace, 'lineprops', 'k-');
    plot((-numPreStimSamples:numPostStimSamples) / pupil_fs, avgPupilTrace, 'k-', 'LineWidth', 2)
end


hold off;
title('4: Average Pupil Traces Aligned to Stimulus Time');
xlabel('Time (s) relative to stimulus onset');
ylabel('Average Pupil Area');
stimPSIs = string(uniqueStimStrengths*10)+" PSI";
stimPSIs(end+1) = "Avg (All PSIs)";
%legend(arrayfun(@num2str, uniqueStimStrengths*10, 'UniformOutput', false));
legend(stimPSIs);

% Task 5: Histogram of baseline photometry for each brain region

% Check if photometry_region_ch2 contains any non-empty data
hasCh2Data = any(~cellfun(@isempty, datastore.photometry_region_ch2));

if hasCh2Data
    % If ch2 data exists, create a 2x1 subplot
    figure;
    
    % Extract region names
    regionNameCh1 = datastore.photometry_region_ch1{1};
    regionNameCh2 = datastore.photometry_region_ch2{1};
    
    % Plot histogram for photometry_region_ch1 if non-empty
    ch1Data = datastore.photo_base_before_stim_ch1; 
    if iscell(ch1Data)
        ch1Data = cell2mat(ch1Data(~cellfun(@isempty, ch1Data)));
    end
    if ~isempty(ch1Data)
        subplot(2, 1, 1);
        histogram(ch1Data);
        title(['5: Histogram of baseline photometry for ' regionNameCh1]);
        xlabel('Photometry values');
        ylabel('Frequency');
    end
    
    % Plot histogram for photometry_region_ch2 if non-empty
    ch2Data = datastore.photo_base_before_stim_ch2;
    if iscell(ch2Data)
        ch2Data = cell2mat(ch2Data(~cellfun(@isempty, ch2Data)));
    end
    if ~isempty(ch2Data)
        subplot(2, 1, 2);
        histogram(ch2Data);
        title(['5: Histogram of baseline photometry for ' regionNameCh2]);
        xlabel('Photometry values');
        ylabel('Frequency');
    end
else
    % If no ch2 data, only plot histogram for photometry_region_ch1
    
    % Extract region name
    regionNameCh1 = datastore.photometry_region_ch1{1};
    
    % Plot histogram for photometry_region_ch1 if non-empty
    ch1Data = datastore.photo_base_before_stim_ch1;
    if iscell(ch1Data)
        ch1Data = cell2mat(ch1Data(~cellfun(@isempty, ch1Data)));
    end
    if ~isempty(ch1Data)
        figure;
        histogram(ch1Data);
        title(['5: Histogram of baseline photometry for ' regionNameCh1]);
        xlabel('Photometry values');
        ylabel('Frequency');
    else
        disp('No data available for plotting');
    end
end

% Task 6: Average photometry traces for each brain region, stratified by stimulus strength
figure;

preStimTime = 1.5; % seconds
postStimTime = 5; % seconds

for ch = 1:2
    if ch == 1 || hasCh2Data
        regionName = datastore.(['photometry_region_ch' num2str(ch)]){1};
        subplot(2, 1, ch);
        hold on;
        colors = jet(length(uniqueStimStrengths));
        
        % Variable to store photometry data across all stimulus strengths
        allStimPhotometryData = [];
        
        % Loop through unique stimulus strengths
        for idx = 1:length(uniqueStimStrengths)
            stimStrength = uniqueStimStrengths(idx);
            photometryData = [];
            
            for trial = 1:height(datastore)
                if datastore.stimulus_strength(trial) == stimStrength
                    photometryTrialData = datastore.(['photometry_ch' num2str(ch)])(trial);
                    photometryTrialData = photometryTrialData{1};
                    stimulusTime = datastore.stimulus_time(trial);
                    
                    if ~isempty(photometryTrialData)
                        % Align time to stimulus time
                        timeRelativeToStimulus = photometryTrialData(:, 1) - stimulusTime;
                        
                        % Extract 1.5 seconds before and 5 seconds after stimulus
                        validIndices = (timeRelativeToStimulus >= -preStimTime) & (timeRelativeToStimulus <= postStimTime);
                        alignedData = photometryTrialData(validIndices, :);
                        
                        % Store the aligned photometry data
                        photometryData = [photometryData, alignedData(:, 2)];
                        allStimPhotometryData = [allStimPhotometryData, alignedData(:, 2)];
                    end
                end
            end
            
            % Plot the average trace for the current stimulus strength
            timeAxis = linspace(-preStimTime, postStimTime, size(photometryData, 1));
            H = shadedErrorBar(timeAxis, mean(photometryData, 2), ...
                           std(photometryData, 0, 2)/sqrt(size(photometryData, 2)), 'lineprops', '-');
        end
        
        % Plot the average trace across all stimulus strengths
        H = shadedErrorBar(timeAxis, mean(allStimPhotometryData, 2), ...
                       std(allStimPhotometryData, 0, 2)/sqrt(size(allStimPhotometryData, 2)), 'lineprops', 'k-');
        H = plot(timeAxis, mean(allStimPhotometryData, 2), 'k-', 'LineWidth', 2);
        
        title(['6: Average photometry traces for ' regionName ' stratified by stimulus strength']);
        xlabel('Time (s) relative to stimulus');
        ylabel('Photometry value');
        stimPSIs = string(uniqueStimStrengths*10)+" PSI";
        stimPSIs(end+1) = "Avg (All PSIs)";
        legend(stimPSIs);
        hold off;
    end
end

% Task 7: Psychometric curve stratified by baseline pupil size 

% Define bins for pupil size
generateAdjacentPairs = @(array) [array(1:end-1).' array(2:end).'];
pupil_bins = [0, .2, .4, .6, .8, 1.0]; %must include 0 and 1
bin_spans = generateAdjacentPairs(pupil_bins).*100;
bin_spans = string(bin_spans(:, 1)) + "-" + string(bin_spans(:, 2)) + "%";
bin_spans = bin_spans';

% Preprocess Data
pupil_5 = datastore.pupil_5pctl;
pupil_95 = datastore.pupil_95pctl;

% Check and convert pupil_5 if it is a cell array and keep valid indexes
if iscell(pupil_5)
    validIndexes_5 = ~cellfun(@isempty, pupil_5);
    pupil_5 = cell2mat(pupil_5(validIndexes_5));
else
    validIndexes_5 = true(size(pupil_5));
end

% Check and convert pupil_95 if it is a cell array and keep valid indexes
if iscell(pupil_95)
    validIndexes_95 = ~cellfun(@isempty, pupil_95);
    pupil_95 = cell2mat(pupil_95(validIndexes_95));
else
    validIndexes_95 = true(size(pupil_95));
end

% Combine valid indexes
validIndexes = validIndexes_5 & validIndexes_95;

% Filter pupil_base_before_stimulus by valid indexes
pupil_base_before_stimulus = datastore.pupil_base_before_stimulus(validIndexes);
if iscell(pupil_base_before_stimulus)
    pupil_base_before_stimulus = cell2mat(pupil_base_before_stimulus);
end
% Compute pupil_mean and pupil_std
pupil_mean = (pupil_5 + pupil_95) / 2;
pupil_std = (pupil_5 - pupil_95) / (2 * -1.645);
cum_prob = normcdf(pupil_base_before_stimulus, pupil_mean, pupil_std);

% Bin the cumulative probabilities
binned = discretize(cum_prob, pupil_bins);

uniquebins = unique(binned);

figure;
hold on;

puffs = unique(datastore.stimulus_strength); % Assuming stimulus_strength represents puffs

for p = 1:numel(uniquebins)
    paradigmData = datastore(binned == uniquebins(p), :);
    % Use the provided function to calculate the psychometric curve and SEM
    psychometric_performance = calculatePsychometricCurvesSEM(...
        paradigmData.stimulus_strength, ...
        paradigmData.go_nogo, ... % Assuming go_nogo is the binary response
        'Phase III', ... % Assuming phase is in column 'phase'
        puffs ...
    );
    
    % Plot the data with shadedErrorBar
    shadedErrorBar(...
        psychometric_performance(1, :)*10, ... % x-axis (puffs)
        psychometric_performance(2, :), ... % y-axis (psychometric performance)
        psychometric_performance(3, :), ...  % error (SEM)
        'lineprops', '-' ...
    );
end

hold off;
title('7: Average Psychometric Curves Stratisfied by Baseline Pupil Size');
xlabel('Stimulus PSI');
ylabel('Psychometric Performance');
legend(bin_spans);

% Task 8: Psychometric curve stratified by baseline photometry for each channel

% Define bins for photometry
generateAdjacentPairs = @(array) [array(1:end-1).' array(2:end).'];
photometry_bins = [0, .2, .4, .6, .8, 1.0]; % must include 0 and 1
bin_spans = generateAdjacentPairs(photometry_bins).*100;
bin_spans = string(bin_spans(:, 1)) + "-" + string(bin_spans(:, 2)) + "%";
bin_spans = bin_spans';

% Puffs
puffs = unique(datastore.stimulus_strength); % Assuming stimulus_strength represents puffs

% Channel names and photometry baselines
channels = {datastore.photometry_region_ch1{1}, datastore.photometry_region_ch2{1}};
photometry_baselines = {'photo_base_before_stim_ch1', 'photo_base_before_stim_ch2'};
photometry_5pctl = {'photometry_5pctl_ch1', 'photometry_5pctl_ch2'};
photometry_95pctl = {'photometry_95pctl_ch1', 'photometry_95pctl_ch2'};

figure;
hold on;

for ch = 1:numel(channels)
    photometry_baseline = datastore.(photometry_baselines{ch});
    
    % Map photometry baseline to cumulative probability distribution
    % Convert to numeric arrays if they are cell arrays
    if iscell(photometry_baseline)
        photometry_baseline = cell2mat(datastore.(photometry_5pctl{ch}));
    end

    if iscell(datastore.(photometry_5pctl{ch}))
        photometry_5pctl_values = cell2mat(datastore.(photometry_5pctl{ch}));
    else
        photometry_5pctl_values = datastore.(photometry_5pctl{ch});
    end
    
    if iscell(datastore.(photometry_95pctl{ch}))
        photometry_95pctl_values = cell2mat(datastore.(photometry_95pctl{ch}));
    else
        photometry_95pctl_values = datastore.(photometry_95pctl{ch});
    end
    
    % Now compute photometry_mean
    photometry_mean = (photometry_5pctl_values + photometry_95pctl_values) / 2;
    photometry_std = (photometry_95pctl_values - photometry_5pctl_values) / (2 * 1.645);
    cum_prob = normcdf(photometry_baseline, photometry_mean, photometry_std);
    
    % Bin the cumulative probabilities
    binned = discretize(cum_prob, photometry_bins);
    uniquebins = unique(binned);

    for p = 1:numel(uniquebins)
        paradigmData = datastore(binned == uniquebins(p), :);
        % Use the provided function to calculate the psychometric curve and SEM
        psychometric_performance = calculatePsychometricCurvesSEM(...
            paradigmData.stimulus_strength, ...
            paradigmData.go_nogo, ... % Assuming go_nogo is the binary response
            'Phase III', ... % Assuming phase is in column 'phase'
            puffs ...
        );

        % Plot the data with shadedErrorBar for each channel
        subplot(numel(channels), 1, ch);
        hold on;
        shadedErrorBar(...
            psychometric_performance(1, :)*10, ... % x-axis (puffs)
            psychometric_performance(2, :), ... % y-axis (psychometric performance)
            psychometric_performance(3, :), ...  % error (SEM)
            'lineprops', '-' ...
        );
        title(['8: ' 'Psychometric Curves for ' channels{ch}]);
        xlabel('Stimulus PSI');
        ylabel('Psychometric Performance');
        if p == length(uniquebins)
            legend(bin_spans);
        end
        hold off;
    end
    legend(bin_spans);
    sgtitle('8: Average Psychometric Curves Stratisfied by Baseline Photometry');
end

% Task 9: Psychometric curve stratified by pupil baseline slope

% Define bins for baseline slope
generateAdjacentPairs = @(array) [array(1:end-1).' array(2:end).'];
slope_bins = [-inf, -.5,0, .5,inf]; % Define appropriate slope bins based on your data
bin_spans = generateAdjacentPairs(slope_bins);
bin_spans = string(bin_spans(:, 1)) + " to " + string(bin_spans(:, 2));
bin_spans = bin_spans';

num_trials = size(datastore, 1);
baseline_slopes = zeros(num_trials, 1);

% Calculate baseline slopes for each trial
for i = 1:num_trials
    pupil_area = datastore.pupil_area{i};
    
    % Check if pupil_area matrix is empty, and if so, skip to the next iteration
    if isempty(pupil_area)
        %baseline_slopes(i) = NaN;
        continue;
    end
    
    % Calculate sampling rate
    time_diff = pupil_area(2, 1) - pupil_area(1, 1);
    sampling_rate = 1 / time_diff;
    
    % Get stimulus time for this trial
    stimulus_time = datastore.stimulus_time(i);
    
    % Select baseline data (1/2 second before stimulus_time)
    relative_time = pupil_area(:, 1) - stimulus_time;
    time_indices = find(relative_time >= (-0.5) & relative_time < 0);
    baseline_data = pupil_area(time_indices, 2);
    time = (1:length(time_indices))' / sampling_rate;
    
    % Fit line to baseline data and extract the slope
    fit_line = polyfit(time, baseline_data, 1);
    baseline_slopes(i) = fit_line(1);
end

% Map baseline slopes to cumulative probability distribution
% slope_mean = mean(baseline_slopes);
% slope_std = std(baseline_slopes);
% cum_prob = normcdf(baseline_slopes, slope_mean, slope_std);

% Bin the cumulative probabilities
binned = discretize(baseline_slopes, slope_bins);

% Puffs
puffs = unique(datastore.stimulus_strength); % Assuming stimulus_strength represents puffs

% Plot psychometric curves for each bin
figure;
hold on;
uniquebins = unique(binned(~isnan(binned)));
for p = 1:numel(uniquebins)
    paradigmData = datastore(binned == uniquebins(p), :);
    % Use the provided function to calculate the psychometric curve and SEM
    psychometric_performance = calculatePsychometricCurvesSEM(...
        paradigmData.stimulus_strength, ...
        paradigmData.go_nogo, ... % Assuming go_nogo is the binary response
        'Phase III', ... % Assuming phase is in column 'phase'
        puffs ...
    );

    % Plot the data with shadedErrorBar
    shadedErrorBar(...
        psychometric_performance(1, :)*10, ... % x-axis (puffs)
        psychometric_performance(2, :), ... % y-axis (psychometric performance)
        psychometric_performance(3, :), ... % error (SEM)
        'lineprops', '-' ...
    );
end

hold off;
title('9: Average Psychometric Curves Stratified by Pupil Baseline Slope');
xlabel('Stimulus PSI');
ylabel('Psychometric Performance');
legend(bin_spans, 'location', 'SE');

% Task 10: Psychometric curve stratified by NT slope in each channel

% Define bins for NT slope
generateAdjacentPairs = @(array) [array(1:end-1).' array(2:end).'];
nt_slope_bins = [-inf, 0, inf]; % Define appropriate NT slope bins based on your data
bin_spans = generateAdjacentPairs(nt_slope_bins);
bin_spans = string(bin_spans(:, 1)) + " to " + string(bin_spans(:, 2));
bin_spans = bin_spans';

num_trials = size(datastore, 1);
channel_names = {datastore.photometry_region_ch1{1}, datastore.photometry_region_ch2{1}};

% Create a figure
figure;

% Loop through each channel
for ch = 1:2
    nt_slopes = zeros(num_trials, 1);
    
    % Calculate NT slopes for each trial
    for i = 1:num_trials
        nt_data = datastore.(['photometry_ch' num2str(ch)]){i};

        % Check if nt_data matrix is empty, and if so, skip to the next iteration
        if isempty(nt_data)
            nt_slopes(i) = NaN;
            continue;
        end

        % Calculate sampling rate
        time_diff = nt_data(2, 1) - nt_data(1, 1);
        sampling_rate = 1 / time_diff;

        % Get stimulus time for this trial
        stimulus_time = datastore.stimulus_time(i);

        % Select baseline data (1/2 second before stimulus_time)
        relative_time = nt_data(:, 1) - stimulus_time;
        time_indices = find(relative_time >= (-0.5) & relative_time < 0);
        baseline_data = nt_data(time_indices, 2);
        time = (1:length(time_indices))' / sampling_rate;

        % Fit line to baseline data and extract the slope
        fit_line = polyfit(time, baseline_data, 1);
        nt_slopes(i) = fit_line(1);
    end

    % Map NT slopes to cumulative probability distribution
%     slope_5 = prctile(nt_slopes, 5);
%     slope_95 = prctile(nt_slopes, 95);
%     slope_mean = (slope_5 + slope_95) / 2;
%     slope_std = (slope_95 - slope_5) / (2 * 1.645);
%     cum_prob = normcdf(nt_slopes, slope_mean, slope_std);

    % Bin the cumulative probabilities
    binned = discretize(nt_slopes, nt_slope_bins);

    % Puffs
    puffs = unique(datastore.stimulus_strength); % Assuming stimulus_strength represents puffs

    % Plot psychometric curves for each bin in a subplot
    subplot(2, 1, ch);
    hold on;
    uniquebins = unique(binned(~isnan(binned)));
    for p = 1:numel(uniquebins)
        paradigmData = datastore(binned == uniquebins(p), :);
        % Use the provided function to calculate the psychometric curve and SEM
        psychometric_performance = calculatePsychometricCurvesSEM(...
            paradigmData.stimulus_strength, ...
            paradigmData.go_nogo, ... % Assuming go_nogo is the binary response
            'Phase III', ... % Assuming phase is in column 'phase'
            puffs ...
        );

        % Plot the data with shadedErrorBar
        shadedErrorBar(...
            psychometric_performance(1, :)*10, ... % x-axis (puffs)
            psychometric_performance(2, :), ... % y-axis (psychometric performance)
            psychometric_performance(3, :), ... % error (SEM)
            'lineprops', '-' ...
        );
    end
    hold off;
    title(['10: ' 'Psychometric curve stratified by NT slope' channel_names{ch}]);
    xlabel('Stimulus PSI');
    ylabel('Psychometric Performance');
    legend(bin_spans, 'Location', 'best');
end

% Task 11: Average power spectrum of each channel across hit, miss, CR, FA trials
% over just the two seconds before stimulus was delivered

% Parameters
desired_freq_resolution = 1; % Desired frequency resolution in Hz
trial_types = {'Hit', 'Miss', 'CR', 'FA'};

% Containers for the power spectral densities
psd_all_ch1 = cell(1, 4);
psd_all_ch2 = cell(1, 4);

num_trials = height(datastore);

% Loop through all trials
for i = 1:num_trials
    
    % Check if photometry_ch1 and photometry_ch2 are non-empty
    if ~isempty(datastore.photometry_ch1{i}) && ~isempty(datastore.photometry_ch2{i})
        
        % Extract data before stimulus
        time_values = datastore.photometry_ch1{i}(:, 1);
        sampling_rate = 1 / (time_values(2) - time_values(1));
        N = round(sampling_rate / desired_freq_resolution); % Calculate the number of points
        
        % Find indices for the two seconds before stimulus
        stimulus_time = datastore.stimulus_time(i);
        idxs = find((time_values >= stimulus_time - 2) & (time_values < stimulus_time));
        
        % Extract photometry data before stimulus
        data_before_stimulus_ch1 = datastore.photometry_ch1{i}(idxs, 2);
        data_before_stimulus_ch2 = datastore.photometry_ch2{i}(idxs, 2);
        
        % Calculate Power Spectral Densities
        [Pxx_ch1, f] = periodogram(data_before_stimulus_ch1, rectwin(length(data_before_stimulus_ch1)), N, sampling_rate, 'power');
        [Pxx_ch2, ~] = periodogram(data_before_stimulus_ch2, rectwin(length(data_before_stimulus_ch2)), N, sampling_rate, 'power');
        
        % Categorize by outcome
        outcome = datastore.categorical_outcome(i);
        for tt = 1:4
            if strcmp(outcome, trial_types{tt}) || (tt == 4 && outcome == "FA") || (tt == 3 && outcome == "CR")
                psd_all_ch1{tt} = [psd_all_ch1{tt}; 10*log10(Pxx_ch1)'];
                psd_all_ch2{tt} = [psd_all_ch2{tt}; 10*log10(Pxx_ch2)'];
            end
        end
    end
end

% Plot the Power Spectral Densities
figure;

% Channel 1
subplot(2, 1, 1);
hold on;
for tt = 1:4
    data = psd_all_ch1{tt};
    if ~isempty(data)
        shadedErrorBar(f, mean(data, 1), std(data, 0, 1)./sqrt(size(data, 1)), 'lineprops', '-');
    end
end
hold off;
title(sprintf('11: Power Spectrum for %s Across Trial Types (2 Seconds Before Stimulus)', datastore.photometry_region_ch1{1}));
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (dB/Hz)');
legend(trial_types);

% Channel 2
subplot(2, 1, 2);
hold on;
for tt = 1:4
    data = psd_all_ch2{tt};
    if ~isempty(data)
        shadedErrorBar(f, mean(data, 1), std(data, 0, 1)./sqrt(size(data, 1)), 'lineprops', '-');
    end
end
hold off;
title(sprintf('11: Power Spectrum for %s Across Trial Types (2 Seconds Before Stimulus)', datastore.photometry_region_ch2{1}));
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (dB/Hz)');
legend(trial_types);

% Task 12: Correlation Coefficient Between Multiple Brain Regions Across Hit, Miss, CR, FA Trials

% Parameters
trial_types = {'Hit', 'Miss', 'CR', 'FA'};

% Create a figure
figure;

% Loop through each trial type
for tt = 1:length(trial_types)
    trial_type = trial_types{tt};
    
    % Store time series for current trial type
    time_series_ch1 = [];
    time_series_ch2 = [];
    
    % Loop through rows in datastore
    for i = 1:height(datastore)
        if strcmp(datastore.categorical_outcome(i), trial_type)
            photometry_data_ch1 = datastore.photometry_ch1{i};
            photometry_data_ch2 = datastore.photometry_ch2{i};
            stimulus_time = datastore.stimulus_time(i);
            
            if ~isempty(photometry_data_ch1) && ~isempty(photometry_data_ch2)
                % Convert absolute time to relative time
                rel_time_ch1 = photometry_data_ch1(:, 1) - stimulus_time;
                rel_time_ch2 = photometry_data_ch2(:, 1) - stimulus_time;
                
                % Extract 1.5 seconds before to 5 seconds after stimulus
                indices_ch1 = rel_time_ch1 >= -.5 & rel_time_ch1 <= 0;
                indices_ch2 = rel_time_ch2 >= -.5 & rel_time_ch2 <= 0;
                
                time_series_ch1 = [time_series_ch1, photometry_data_ch1(indices_ch1, 2)];
                time_series_ch2 = [time_series_ch2, photometry_data_ch2(indices_ch2, 2)];
            end
        end
    end
    
    % Calculate correlation matrix
    if ~isempty(time_series_ch1) && ~isempty(time_series_ch2)
        corr_matrix = corr([time_series_ch1(:), time_series_ch2(:)]);
        brain_regions = {datastore.photometry_region_ch1{1}, datastore.photometry_region_ch2{1}};
        
        % Create a subplot for the current trial type
        subplot(2, 2, tt);
        imagesc(corr_matrix);
        colorbar;
        caxis([-1, 1]); % Setting color axis limits to -1 to 1 for correlation
        title(['12: Correlation Matrix for ', trial_types{tt}, ' Trials']);
        set(gca, 'XTick', 1:length(brain_regions), 'XTickLabel', brain_regions, 'YTick', 1:length(brain_regions), 'YTickLabel', brain_regions);
        xtickangle(45);
        
        % Add correlation values as text in the middle of each square
        for i = 1:size(corr_matrix, 1)
            for j = 1:size(corr_matrix, 2)
                text(j, i, sprintf('%.2f', corr_matrix(i, j)), 'HorizontalAlignment', 'center');
            end
        end
    end
end
%%
% Task 13: Average pupil trace aligned at a “whisk”

% Calculate the sample rate from the first non-empty pupil matrix
firstNonEmptyIndex = find(~cellfun(@isempty, datastore.pupil_area), 1);
timeDiff = diff(datastore.pupil_area{firstNonEmptyIndex}(1:2, 1));
pupil_fs = 1 / timeDiff;

% Define the whisk threshold and refractory period
whisk_thresh = pi/2;
refractory_period = 0.3; % 0.3 seconds

% Define pre and post event window
pre_event_window = 1.5; % 1.5 seconds
post_event_window = 5.0; % 5.0 seconds

% Calculate number of samples for pre and post event windows
numPreEventSamples = ceil(pre_event_window * pupil_fs); 
numPostEventSamples = ceil(post_event_window * pupil_fs);

% Initialize a matrix to store pupil traces for each whisk
pupilTraces = [];

% Define window size for calculating moving average
window_size = 500;

% Calculate number of samples for the refractory period
numRefractorySamples = ceil(refractory_period * pupil_fs);

% Loop over each trial
for t = 1:height(datastore)
    pupilData = datastore.pupil_area{t};
    whiskData = datastore.whisker_rad{t};
    
    if ~isempty(pupilData) && ~isempty(whiskData)
        % Mean center the whiskData
        whiskData(:,2) = whiskData(:,2) - mean(whiskData(:,2));

        % Calculate the onset time and 0.5 seconds before the stimulus time
        onset_time = datastore.trial_onset_time(t);
        pre_stimulus_time = datastore.stimulus_time(t) - 0.5;

        % Get the whiskData within the time window
        whiskDataWindow = whiskData(whiskData(:, 1) >= onset_time & whiskData(:, 1) <= pre_stimulus_time, :);

        % Calculate the moving average of the whiskData within the time window
        if ~isempty(whiskDataWindow)
            avg_whiskData = movmean(whiskDataWindow(:, 2), min(window_size, length(whiskDataWindow(:, 2))), 'Endpoints', 'fill');

            % Find the threshold for defining a whisking event as the mean plus 2 standard deviations
            whiskThresh = nanmean(avg_whiskData) + 2 * nanstd(avg_whiskData);

            % Find periods where the whiskData exceeds this threshold
            whiskingEvents = whiskDataWindow(:, 2) > whiskThresh;
            validWhisks = find(whiskingEvents);

            % Remove whisks that fall within the refractory period
            refractoryWhisks = diff(validWhisks) <= numRefractorySamples;
            validWhisks([false; refractoryWhisks]) = [];

            % Extract relevant window around the whisk
            for w = 1:length(validWhisks)
                whiskTime = whiskDataWindow(validWhisks(w), 1);
                
                % Find the index of whiskTime in the pupilData
                [~, whiskIdx] = min(abs(pupilData(:, 1) - whiskTime));
                
                startIndex = max(1, whiskIdx - numPreEventSamples);
                endIndex = min(size(pupilData, 1), whiskIdx + numPostEventSamples);
                
                % Extract pupil area data
                pupilTrace = pupilData(startIndex:endIndex, 2); % Column 2 is the pupil area
                if size(pupilTrace, 1) == numPreEventSamples + numPostEventSamples + 1
                    pupilTraces(:, end+1) = pupilTrace;
                end
            end
        end
    end
end

% Plot all the pupil traces aligned to whisk events
figure;
hold on;
mean_pupilTrace = mean(pupilTraces, 2);
sem_pupilTrace = std(pupilTraces, 0, 2) / sqrt(size(pupilTraces, 2));
plot((-numPreEventSamples:numPostEventSamples) / pupil_fs, mean_pupilTrace, 'color', 'k', 'LineWidth', 2);
fill([(-numPreEventSamples:numPostEventSamples) / pupil_fs, fliplr((-numPreEventSamples:numPostEventSamples) / pupil_fs)], ...
    [mean_pupilTrace' + sem_pupilTrace', fliplr(mean_pupilTrace' - sem_pupilTrace')], ...
    'k', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
hold off;
title('Pupil Traces Aligned to Whisk Events');
xlabel('Time (s) relative to whisk onset');
ylabel('Pupil Area');

%%
% Task 14: Average photometry traces aligned at a “whisk”

% Define the channels
ch1 = 'photometry_ch1';
ch2 = 'photometry_ch2';

% Calculate the sample rate from the first non-empty photometry matrix
firstNonEmptyIndex_ch1 = find(~cellfun(@isempty, datastore.(ch1)), 1);
firstNonEmptyIndex_ch2 = find(~cellfun(@isempty, datastore.(ch2)), 1);

timeDiff_ch1 = diff(datastore.(ch1){firstNonEmptyIndex_ch1}(1:2, 1));
timeDiff_ch2 = diff(datastore.(ch2){firstNonEmptyIndex_ch2}(1:2, 1));

photom_fs_ch1 = 1 / timeDiff_ch1;
photom_fs_ch2 = 1 / timeDiff_ch2;

% Initialize matrices to store photometry traces for each whisk
photomTraces_ch1 = [];
photomTraces_ch2 = [];

% Loop over each trial
for t = 1:height(datastore)
    photomData_ch1 = datastore.(ch1){t};
    photomData_ch2 = datastore.(ch2){t};
    whiskData = datastore.whisker_rad{t};

    if ~isempty(photomData_ch1) && ~isempty(photomData_ch2) && ~isempty(whiskData)
        % Calculate the onset time and 0.5 seconds before the stimulus time
        onset_time = datastore.trial_onset_time(t);
        pre_stimulus_time = datastore.stimulus_time(t) - 0.5;

        % Get the whiskData within the time window
        whiskDataWindow = whiskData(whiskData(:, 1) >= onset_time & whiskData(:, 1) <= pre_stimulus_time, :);

        % Calculate the moving average of the whiskData within the time window
        if ~isempty(whiskDataWindow)
            avg_whiskData = movmean(whiskDataWindow(:, 2), min(window_size, length(whiskDataWindow(:, 2))), 'Endpoints', 'fill');

            % Find the threshold for defining a whisking event as the mean plus 2 standard deviations
            whiskThresh = nanmean(avg_whiskData) + 2 * nanstd(avg_whiskData);

            % Find periods where the whiskData exceeds this threshold
            whiskingEvents = whiskDataWindow(:, 2) > whiskThresh;
            validWhisks = find(whiskingEvents);

            % Remove whisks that fall within the refractory period
            refractoryWhisks = diff(validWhisks) <= numRefractorySamples;
            validWhisks([false; refractoryWhisks]) = [];

            % Extract relevant window around the whisk
            for w = 1:length(validWhisks)
                whiskTime = whiskDataWindow(validWhisks(w), 1);

                % Find the index of whiskTime in the photometry data
                [~, whiskIdx_ch1] = min(abs(photomData_ch1(:, 1) - whiskTime));
                [~, whiskIdx_ch2] = min(abs(photomData_ch2(:, 1) - whiskTime));

                startIndex_ch1 = max(1, whiskIdx_ch1 - numPreEventSamples);
                endIndex_ch1 = min(size(photomData_ch1, 1), whiskIdx_ch1 + numPostEventSamples);

                startIndex_ch2 = max(1, whiskIdx_ch2 - numPreEventSamples);
                endIndex_ch2 = min(size(photomData_ch2, 1), whiskIdx_ch2 + numPostEventSamples);

                % Extract photometry data
                photomTrace_ch1 = photomData_ch1(startIndex_ch1:endIndex_ch1, 2); % Column 2 is the photometry data
                photomTrace_ch2 = photomData_ch2(startIndex_ch2:endIndex_ch2, 2);

                if size(photomTrace_ch1, 1) == numPreEventSamples + numPostEventSamples + 1
                    photomTraces_ch1(:, end+1) = photomTrace_ch1;
                end
                
                if size(photomTrace_ch2, 1) == numPreEventSamples + numPostEventSamples + 1
                    photomTraces_ch2(:, end+1) = photomTrace_ch2;
                end
            end
        end
    end
end

% Plot all the photometry traces aligned to whisk events
figure;
hold on;
mean_photomTrace_ch1 = mean(photomTraces_ch1, 2);
sem_photomTrace_ch1 = std(photomTraces_ch1, 0, 2) / sqrt(size(photomTraces_ch1, 2));
plot((-numPreEventSamples:numPostEventSamples) / photom_fs_ch1, mean_photomTrace_ch1, 'color', 'r', 'LineWidth', 2);
fill([(-numPreEventSamples:numPostEventSamples) / photom_fs_ch1, fliplr((-numPreEventSamples:numPostEventSamples) / photom_fs_ch1)], ...
    [mean_photomTrace_ch1' + sem_photomTrace_ch1', fliplr(mean_photomTrace_ch1' - sem_photomTrace_ch1')], ...
    'r', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
title('Photometry Traces Aligned to Whisk Events (Channel 1)');
xlabel('Time (s) relative to whisk onset');
ylabel('Photometry Trace');

figure;
hold on;
mean_photomTrace_ch2 = mean(photomTraces_ch2, 2);
sem_photomTrace_ch2 = std(photomTraces_ch2, 0, 2) / sqrt(size(photomTraces_ch2, 2));
plot((-numPreEventSamples:numPostEventSamples) / photom_fs_ch2, mean_photomTrace_ch2, 'color', 'b', 'LineWidth', 2);
fill([(-numPreEventSamples:numPostEventSamples) / photom_fs_ch2, fliplr((-numPreEventSamples:numPostEventSamples) / photom_fs_ch2)], ...
    [mean_photomTrace_ch2' + sem_photomTrace_ch2', fliplr(mean_photomTrace_ch2' - sem_photomTrace_ch2')], ...
    'b', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
title('Photometry Traces Aligned to Whisk Events (Channel 2)');
xlabel('Time (s) relative to whisk onset');
ylabel('Photometry Trace');
hold off;

%%
% Task 15: Average Whisker Trace Stratified by Hit, Miss, CR, and FA

% Parameters
trial_types = {'Hit', 'Miss', 'CR', 'FA'};
colors = {'b', 'r', 'g', 'm'};
trace_lengths = [];

% Temp storage for traces
temp_whisker_traces = cell(1, length(trial_types));

% Initialize variable to keep track of whether sampling rate has been determined
sampling_rate_determined = false;

% Loop through rows in datastore to store trace lengths
for i = 1:height(datastore)
    outcome = datastore.categorical_outcome(i);
    whisker_trace = datastore.whisker_rad{i};
    
    % Continue if the whisker trace data is empty
    if isempty(whisker_trace)
        continue;
    end
    
    % Determine the sampling rate from the first non-empty whisker_trace
    if ~sampling_rate_determined && size(whisker_trace, 1) > 1
        sampling_rate = 1/mean(diff(whisker_trace(1:2, 1)));
        sampling_rate_determined = true;
    end
    
    % Convert absolute time to relative time
    stimulus_time = datastore.stimulus_time(i);
    relative_time = whisker_trace(:, 1) - stimulus_time;
    
    % Extract the time window from -1.5 to 5 seconds
    within_window = relative_time >= -1.5 & relative_time <= 5;
    trace_within_window = whisker_trace(within_window, 2)';
    relative_time_window = relative_time(within_window)';
    
    trace_lengths = [trace_lengths, length(trace_within_window)];
    
    % Check if the outcome matches one of the trial types and store the trace
    for tt = 1:length(trial_types)
        if strcmp(outcome, trial_types{tt})
            temp_whisker_traces{tt}{end+1} = trace_within_window;
        end
    end
end

% Determine the median length
median_length = median(trace_lengths);

% Adjust the lengths of the traces
whisker_traces = cell(1, length(trial_types));
for tt = 1:length(trial_types)
    adjusted_traces = [];
    for j = 1:length(temp_whisker_traces{tt})
        single_trace = temp_whisker_traces{tt}{j};
        diff_length = length(single_trace) - median_length;
        if abs(diff_length) <= 1
            if diff_length == 1
                single_trace(end) = []; % remove one sample
            elseif diff_length == -1
                single_trace(end+1) = mean(single_trace); % mean pad
            end
            adjusted_traces = [adjusted_traces; single_trace];
        end
    end
    whisker_traces{tt} = adjusted_traces;
end

% Create time array for x-axis (relative to stimulus)
time_array = linspace(-1.5, 5, median_length);

% Create a figure
figure;

% Plot the average whisker trace for each trial type with SEM
hold on;
for tt = 1:length(trial_types)
    if ~isempty(whisker_traces{tt})
        mean_trace = mean(whisker_traces{tt}, 1);
        sem_trace = std(whisker_traces{tt}, 0, 1) / sqrt(size(whisker_traces{tt}, 1));
        shadedErrorBar(time_array, mean_trace, sem_trace, 'lineprops', {'Color', colors{tt}}, 'patchSaturation', 0.3);
    end
end
hold off;

% Add labels and legend
title('15: Average Whisker Trace Stratified by Trial Type');
xlabel('Time (s) relative to stimulus onset');
ylabel('Whisker Angle (rad)');
legend(trial_types, 'Location', 'best');

% NOT WORKING
% % Task 16: Average Wheel Velocity Trace Stratified by Hit, Miss, CR, and FA
% 
% % Parameters
% trial_types = {'Hit', 'Miss', 'CR', 'FA'};
% colors = {'b', 'r', 'g', 'm'};
% 
% % Temp storage for traces
% temp_wheel_traces = cell(1, length(trial_types));
% relative_time_windows = cell(1, length(trial_types));
% 
% % Loop through rows in datastore to extract the data
% for i = 1:height(datastore)
%     outcome = datastore.categorical_outcome(i);
%     wheel_trace = datastore.wheel_displacement{i};
%     
%     % Continue if the wheel trace data is empty
%     if isempty(wheel_trace)
%         continue;
%     end
%     
%     % Convert absolute time to relative time
%     stimulus_time = datastore.stimulus_time(i);
%     relative_time = wheel_trace(:, 1) - stimulus_time;
%     
%     % Extract the time window from -1.5 to 5 seconds
%     within_window = relative_time >= -1.5 & relative_time <= 5;
%     trace_within_window = wheel_trace(within_window, 2)';
%     relative_time_window = relative_time(within_window)';
%     
%     % Check if the outcome matches one of the trial types and store the trace
%     for tt = 1:length(trial_types)
%         if strcmp(outcome, trial_types{tt})
%             temp_wheel_traces{tt}{end+1} = trace_within_window;
%             relative_time_windows{tt}{end+1} = relative_time_window;
%         end
%     end
% end
% 
% % Create a figure
% figure;
% 
% % Plot the average wheel trace for each trial type
% hold on;
% for tt = 1:length(trial_types)
%     wheel_trace_cells = temp_wheel_traces{tt};
%     time_cells = relative_time_windows{tt};
%     
%     % Concatenate the wheel traces into a matrix
%     min_length = min(cellfun(@length, wheel_trace_cells));
%     wheel_trace_mat = cell2mat(cellfun(@(x) x(1:min_length), wheel_trace_cells, 'UniformOutput', false)');
%     time_mat = cell2mat(cellfun(@(x) x(1:min_length), time_cells, 'UniformOutput', false)');
%     
%     % Compute the mean
%     mean_trace = mean(wheel_trace_mat, 1);
%     mean_time = mean(time_mat, 1);
%     
%     % Plot
%     plot(mean_time, mean_trace, 'Color', colors{tt}, 'DisplayName', trial_types{tt});
% end
% hold off;
% 
% % Add labels and legend
% title('Average Wheel Velocity Trace Stratified by Trial Type');
% xlabel('Time (s) relative to stimulus onset');
% ylabel('Wheel Displacement');
% legend('show');

% Task 17: Psychometric Curve Stratified by Short and XL Inter Stimulus Interval (ISI)

% Filter the ISIs
ISI_data = datastore.ISI; % Assuming ISI_data is an array of ISI values
ISI_values = cell2mat(cellfun(@(x) ~isempty(x) * x, ISI_data, 'UniformOutput', false));

% Separate the ISIs into two groups: < 30 and >= 30
short_ISI_indices = find(ISI_values < 30);
short_ISIs = ISI_values(short_ISI_indices);
long_ISI_indices = ISI_values >= 30;

% Fit distribution on short ISIs (< 30)
ISI_mean = mean(short_ISIs);
ISI_std = std(short_ISIs);

% Calculate cumulative probabilities for short ISIs
cum_prob = normcdf(short_ISIs, ISI_mean, ISI_std);

% Define bins for cum_prob
ISI_bins = [0, .33, .66, 1.0]; % Bins for short ISIs
bin_spans = generateAdjacentPairs(ISI_bins).*100;
bin_spans = string(bin_spans(:, 1)) + "-" + string(bin_spans(:, 2)) + "%";
bin_spans(end+1) = "XL";
bin_spans = bin_spans';

% Bin the cumulative probabilities
binned = discretize(cum_prob, ISI_bins);

uniquebins = unique(binned);

figure;
hold on;

puffs = unique(datastore.stimulus_strength); % Assuming stimulus_strength represents puffs

% Loop through the bins for short ISIs
for p = 1:numel(uniquebins)
    bin_indices = (binned == uniquebins(p));
    original_indices = short_ISI_indices(bin_indices);
    paradigmData = datastore(original_indices, :);

    % Use the provided function to calculate the psychometric curve and SEM
    psychometric_performance = calculatePsychometricCurvesSEM(...
        paradigmData.stimulus_strength, ...
        paradigmData.go_nogo, ... % Assuming go_nogo is the binary response
        'Phase III', ... % Assuming phase is in column 'phase'
        puffs ...
    );

    % Plot the data with shadedErrorBar
    shadedErrorBar(...
        psychometric_performance(1, :)*10, ... % x-axis (puffs)
        psychometric_performance(2, :), ... % y-axis (psychometric performance)
        psychometric_performance(3, :), ...  % error (SEM)
        'lineprops', '-' ...
    );
end

% Now plot the XL group outside the loop
paradigmData = datastore(long_ISI_indices, :);

% Use the provided function to calculate the psychometric curve and SEM
psychometric_performance = calculatePsychometricCurvesSEM(...
    paradigmData.stimulus_strength, ...
    paradigmData.go_nogo, ... % Assuming go_nogo is the binary response
    'Phase III', ... % Assuming phase is in column 'phase'
    puffs ...
);

% Plot the data with shadedErrorBar
shadedErrorBar(...
    psychometric_performance(1, :)*10, ... % x-axis (puffs)
    psychometric_performance(2, :), ... % y-axis (psychometric performance)
    psychometric_performance(3, :), ...  % error (SEM)
    'lineprops', '-' ...
);

hold off;
title('17: Psychometric Curves Stratified by Inter Stimulus Interval (ISI)');
xlabel('Stimulus PSI');
ylabel('Psychometric Performance');
legend(bin_spans);

% Task 18: psychometric curve stratified by short, medium, long time between trial onset and stimulus delivery

% Calculate time difference between trial_onset_time and stimulus_time
trial_onset_time = datastore.trial_onset_time; % Assuming trial_onset_time is a column in datastore
stimulus_time = datastore.stimulus_time; % Assuming stimulus_time is a column in datastore
time_difference = stimulus_time - trial_onset_time;

% Define bins for time_difference
time_bins = [min(time_difference), quantile(time_difference, [1/3]), quantile(time_difference, [2/3]), max(time_difference)];
bin_labels = {'short', 'medium', 'long'};

% Bin the time_difference
binned_times = discretize(time_difference, time_bins);

uniquebins = unique(binned_times);

figure;
hold on;

puffs = unique(datastore.stimulus_strength); % Assuming stimulus_strength represents puffs

% Loop through the bins for short, medium, long time_difference
for p = 1:numel(uniquebins)
    time_indices = (binned_times == uniquebins(p));
    paradigmData = datastore(time_indices, :);

    % Use the provided function to calculate the psychometric curve and SEM
    psychometric_performance = calculatePsychometricCurvesSEM(...
        paradigmData.stimulus_strength, ...
        paradigmData.go_nogo, ... % Assuming go_nogo is the binary response
        'Phase III', ... % Assuming phase is in column 'phase'
        puffs ...
    );

    % Plot the data with shadedErrorBar
    shadedErrorBar(...
        psychometric_performance(1, :)*10, ... % x-axis (puffs)
        psychometric_performance(2, :), ... % y-axis (psychometric performance)
        psychometric_performance(3, :), ...  % error (SEM)
        'lineprops', '-' ...
    );
end

hold off;
title('18: Psychometric Curves Stratified by Time Between Trial Onset and Stimulus Delivery');
xlabel('Stimulus PSI');
ylabel('Psychometric Performance');
legend(bin_labels);

% Task 19: histogram of response times

% Extract response times from the datastore
response_times = datastore.response_time; % Assuming response_time is a column in datastore

% Filter out any invalid or missing data
response_times = response_times(~isnan(response_times));

response_times = response_times(response_times < .8);

% Create a histogram of the response times
figure;
histogram(response_times, 100); % You can also specify the number of bins instead of 'auto'

% Add title and axis labels to the histogram
title('19: Histogram of Response Times');
xlabel('Response Time');
ylabel('Frequency');

% Task 20: Average pupil traces aligned around distractor_times

% Calculate the sample rate from the first non-empty pupil matrix
firstNonEmptyIndex = find(~cellfun(@isempty, datastore.pupil_area), 1);
timeDiff = diff(datastore.pupil_area{firstNonEmptyIndex}(1:2, 1));
pupil_fs = 1 / timeDiff;

% Extract distractor_times
distractorTimes = datastore.distractor_times;

% Initialize average pupil trace matrix
numPrePuffSamples = ceil(1.5 * pupil_fs); % 1.5 seconds before distractor puff
numPostPuffSamples = ceil(5 * pupil_fs); % 5 seconds after distractor puff

figure;
hold on;

% Initialize a matrix to store pupil traces for distractor puffs
pupilTraces = [];

% Loop over each trial
for t = 1:height(datastore)
    pupilData = datastore.pupil_area{t}; % Assuming pupil_area is a cell array of matrices
    
    % Skip if pupilData is empty
    if isempty(pupilData)
        continue;
    end
    
    distractorPuffTimes = distractorTimes{t};
    
    % Loop over distractor puff times in current trial
    for dtime = 1:length(distractorPuffTimes)
        % Find the index of the distractor puff time in the pupilData
        [~, puffIdx] = min(abs(pupilData(:, 1) - distractorPuffTimes(dtime)));
        
        % Extract relevant window around the distractor puff
        startIndex = max(1, puffIdx - numPrePuffSamples);
        endIndex = min(size(pupilData, 1), puffIdx + numPostPuffSamples);
        try
                pupilTraces(:, end+1) = pupilData(startIndex:endIndex, 2); % Column 2 is the pupil area
        catch e
            fprintf(1,'The identifier was:\n%s',e.identifier);
            fprintf(1,'There was an error! The message was:\n%s', e.message);
        end
    end
end

% Compute average pupil trace
avgPupilTrace = mean(pupilTraces, 2);
semPupilTrace = std(pupilTraces, 0, 2) / sqrt(size(pupilTraces, 2)); % Compute SEM

% Plotting the average pupil trace with SEM shaded region
shadedErrorBar((-numPrePuffSamples:numPostPuffSamples) / pupil_fs, avgPupilTrace, semPupilTrace, 'lineprops', '-');

hold off;
title('20: Average Pupil Traces Aligned to Distractor Puff Times');
xlabel('Time (s) relative to distractor puff');
ylabel('Average Pupil Area');

% Task 21: Average NT trace aligned around distractor_times for both photometry channels

% Calculate the sample rate from the first non-empty photometry matrix
firstNonEmptyIndex = find(~cellfun(@isempty, datastore.photometry_ch1), 1);
timeDiff = diff(datastore.photometry_ch1{firstNonEmptyIndex}(1:2, 1));
photometry_fs = 1 / timeDiff;

% Extract distractor_times
distractorTimes = datastore.distractor_times;

% Initialize average NT trace matrix
numPrePuffSamples = ceil(1.5 * photometry_fs); % 1.5 seconds before distractor puff
numPostPuffSamples = ceil(5 * photometry_fs); % 5 seconds after distractor puff

figure;

% Get channel names
channelNames = {datastore.photometry_region_ch1{1}, datastore.photometry_region_ch2{1}};

% Loop over photometry channels
for ch = 1:2
    % Initialize a matrix to store NT traces for distractor puffs
    NTtraces = [];
    
    % Loop over each trial
    for t = 1:height(datastore)
        % Select appropriate photometry channel
        if ch == 1
            photometryData = datastore.photometry_ch1{t};
        else
            photometryData = datastore.photometry_ch2{t};
        end
        
        % Skip if photometryData is empty
        if isempty(photometryData)
            continue;
        end
        
        distractorPuffTimes = distractorTimes{t};
        
        % Loop over distractor puff times in current trial
        for dtime = 1:length(distractorPuffTimes)
            % Find the index of the distractor puff time in the photometryData
            [~, puffIdx] = min(abs(photometryData(:, 1) - distractorPuffTimes(dtime)));
            
            % Extract relevant window around the distractor puff
            startIndex = max(1, puffIdx - numPrePuffSamples);
            endIndex = min(size(photometryData, 1), puffIdx + numPostPuffSamples);
            %NTtraces(:, end+1) = photometryData(startIndex:endIndex, 2); % Column 2 is the NT intensity
            try
                NTtraces(:, end+1) = photometryData(startIndex:endIndex, 2);
            catch e
                fprintf(1,'The identifier was:\n%s',e.identifier);
                fprintf(1,'There was an error! The message was:\n%s', e.message);
            end
        end
    end
    
    % Compute average NT trace
    avgNTtrace = mean(NTtraces, 2);
    semNTtrace = std(NTtraces, 0, 2) / sqrt(size(NTtraces, 2)); % Compute SEM
    
    % Select subplot
    subplot(2, 1, ch);
    hold on;
    
    % Plotting the average NT trace with SEM shaded region
    shadedErrorBar((-numPrePuffSamples:numPostPuffSamples) / photometry_fs, avgNTtrace, semNTtrace, 'lineprops', '-');
    
    title(['21: Average NT Trace Aligned to Distractor Puff Times (', channelNames{ch}, ')']);
    xlabel('Time (s) relative to distractor puff');
    ylabel('Average NT Intensity');
    
    hold off;
end

% Task 22: Psychometric curve stratified by previous trial's categorical outcome

% Extract previous trial outcomes starting from the second trial
previousOutcomes = datastore.previos_trial_categorical_outcome(2:end);

% Convert non-empty cells to strings and keep track of non-empty indices
nonEmptyIdx = ~cellfun(@isempty, previousOutcomes);
previousOutcomes(nonEmptyIdx) = cellfun(@char, previousOutcomes(nonEmptyIdx), 'UniformOutput', false);

% Replace "Delayed FA (CR)" with "CR" and "Near Hit (Miss)" with "Miss"
previousOutcomes(strcmp(previousOutcomes, 'Delayed FA (CR)')) = {'CR'};
previousOutcomes(strcmp(previousOutcomes, 'Near Hit (Miss)')) = {'Miss'};

% Extract unique non-empty previous outcomes
uniquePreviousOutcomes = unique(previousOutcomes(nonEmptyIdx));

% Make sure to only consider non-empty previous outcomes for the data
previousOutcomes = previousOutcomes(nonEmptyIdx);
datastore = datastore(2:end, :); % Adjust the datastore to match previousOutcomes
datastore = datastore(nonEmptyIdx, :);

figure;
hold on;

puffs = unique(datastore.stimulus_strength); % Assuming stimulus_strength represents puffs

for p = 1:numel(uniquePreviousOutcomes)
    previousOutcome = uniquePreviousOutcomes(p);
    paradigmData = datastore(strcmp(previousOutcomes, previousOutcome), :);
    
    % Use the provided function to calculate the psychometric curve and SEM
    psychometric_performance = calculatePsychometricCurvesSEM(...
        paradigmData.stimulus_strength, ...
        paradigmData.go_nogo, ... % Assuming go_nogo is the binary response
        'Phase III', ... % Assuming phase is in column 'phase'
        puffs ...
    );
    
    % Plot the data with shadedErrorBar
    shadedErrorBar(...
        psychometric_performance(1, :)*10, ... % x-axis (puffs)
        psychometric_performance(2, :), ... % y-axis (psychometric performance)
        psychometric_performance(3, :), ...  % error (SEM)
        'lineprops', '-' ...
    );
end

hold off;
title('22: Psychometric Curves Stratified by Previous Outcome');
xlabel('Stimulus PSI');
ylabel('Psychometric Performance');
legend(uniquePreviousOutcomes, 'Location', 'Best');
%%
% Get handles to all open figures
figHandles = findall(0, 'Type', 'figure');

% Iterate through each figure
for i = 1:length(figHandles)
    figure(figHandles(i)); % Bring the i-th figure to focus
    
    % Get the title of the figure
    ax = get(figHandles(i), 'CurrentAxes');
    titleHandle = get(ax, 'Title');
    titleString = get(titleHandle, 'String');
    
    % Remove spaces and colons from the title
    titleString = strrep(titleString, ' ', '');
    titleString = strrep(titleString, ':', '');
    
    % Define the filename based on the title
    filename = fullfile(outputDirectory, [titleString, '.png']);
    
    % Save the figure as an image file
    try
        saveas(figHandles(i), filename);
        fprintf('Figure %d saved as %s\n', i, filename);
    catch exception
        fprintf('Failed to save figure %d: %s\n', i, exception.message);
    end
end




















