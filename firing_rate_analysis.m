%%
load("C:\Users\Gabog\Downloads\3735-R-S1-Npxl_Datastore_created_03-Jul-2023_behaving_no-lfp.mat")

%%
% Load the data
spike_times_cells = Datastore.spike_times;
spike_cluster_group = Datastore.spike_cluster_group;
fsAP = Datastore.fsAP;
stimulus_indices = Datastore.stimulus_index_AP;
session_ids = Datastore.session_id;

% Identify the session ID of the first trial
first_session_id = session_ids{1};

% Identify all trials that belong to the first session
trials_of_first_session = find(cellfun(@(x) strcmp(x, first_session_id), session_ids));

% Define the time range relative to the stimulus time
pre_stimulus_duration = 3; % seconds
post_stimulus_duration = 2; % seconds

% Define the window size
window_size = 0.01; % seconds

% Determine the number of bins before and after the stimulus
num_bins_before = ceil(pre_stimulus_duration / window_size);
num_bins_after = floor(post_stimulus_duration / window_size);

% Create edges for the histogram such that 0 is the left edge of a bin
edges = [-num_bins_before*window_size : window_size : num_bins_after*window_size];

% Identify unique neurons
unique_neurons = unique(spike_cluster_group{1});

% Initialize a matrix to accumulate firing rates
firing_rates_accumulated = zeros(length(unique_neurons), length(edges) - 1);

for trial = trials_of_first_session'
    current_spike_times = double(spike_times_cells{trial}) / fsAP;
    current_neuron_ids = spike_cluster_group{trial};
    stimulus_time_seconds = current_spike_times(min(stimulus_indices{trial})); % Extracting the earliest stimulus time
    
    % Adjust spike times so that stimulus time is the reference (t=0)
    adjusted_spike_times_seconds = current_spike_times - stimulus_time_seconds;

    for idx = 1:length(unique_neurons)
        neuron_id = unique_neurons(idx);
        spikes_of_neuron = adjusted_spike_times_seconds(current_neuron_ids == neuron_id);
        [counts, ~] = histcounts(spikes_of_neuron, edges);
        firing_rates_accumulated(idx, :) = firing_rates_accumulated(idx, :) + counts;
    end
end

% Calculate average firing rates by dividing by the number of trials
average_firing_rates = firing_rates_accumulated / length(trials_of_first_session);

% Visualize the average firing rates using an image
figure;
imagesc(edges(1:end-1), 1:length(unique_neurons), average_firing_rates);
xlabel('Time (seconds relative to stimulus)');
ylabel('Neuron #');
title('Average Firing Rates of Neurons across all Trials of the First Session');
colorbar;
caxis([0, max(average_firing_rates(:))]); % Set color scale to match range of firing rates
%%
% Load the data
spike_times_cells = Datastore.spike_times;
spike_cluster_group = Datastore.spike_cluster_group;
fsAP = Datastore.fsAP;
stimulus_indices = Datastore.stimulus_index_AP;
session_ids = Datastore.session_id;
stimulus_strengths = Datastore.stimulus_strength;
categorical_outcomes = Datastore.categorical_outcome;  % Assuming you have this property

% Identify the session ID of the first trial
first_session_id = session_ids{1};

% Identify all trials that belong to the first session
trials_of_first_session = find(cellfun(@(x) strcmp(x, first_session_id), session_ids));

% Filter trials of the first session to only include "miss" trials
miss_trials_of_first_session = trials_of_first_session(cellfun(@(x) contains(x, 'miss', 'IgnoreCase', true), categorical_outcomes(trials_of_first_session)));

% Identify unique neurons and stimulus strengths
unique_neurons = unique(spike_cluster_group{1});
unique_strengths = unique(stimulus_strengths(miss_trials_of_first_session));

% Define the time range relative to the stimulus time
pre_stimulus_duration = 3; % seconds

% Define the window size
window_size = 0.01; % seconds

% Determine the number of bins before the stimulus
num_bins_before = ceil(pre_stimulus_duration / window_size);

% Create edges for the histogram such that 0 is the left edge of a bin
edges = [-num_bins_before*window_size : window_size : 0];

% Prepare figure and grid layout
figure;
num_strengths = length(unique_strengths);
subplot_rows = 2;
subplot_cols = 3;

for sidx = 1:num_strengths
    strength = unique_strengths(sidx);

    % Initialize a matrix to accumulate firing rates for the current strength
    firing_rates_accumulated = zeros(length(unique_neurons), length(edges) - 1);
    
    % Identify trials with the current strength among the miss trials
    trials_of_current_strength = miss_trials_of_first_session(stimulus_strengths(miss_trials_of_first_session) == strength);
    
    for trial = trials_of_current_strength'
        current_spike_times = double(spike_times_cells{trial}) / fsAP;
        current_neuron_ids = spike_cluster_group{trial};
        stimulus_time_seconds = current_spike_times(min(stimulus_indices{trial})); % Extracting the earliest stimulus time
        
        % Adjust spike times so that stimulus time is the reference (t=0)
        adjusted_spike_times_seconds = current_spike_times - stimulus_time_seconds;

        for idx = 1:length(unique_neurons)
            neuron_id = unique_neurons(idx);
            spikes_of_neuron = adjusted_spike_times_seconds(current_neuron_ids == neuron_id);
            [counts, ~] = histcounts(spikes_of_neuron, edges);
            firing_rates_accumulated(idx, :) = firing_rates_accumulated(idx, :) + counts;
        end
    end

    % Calculate average firing rates by dividing by the number of trials
    average_firing_rates = firing_rates_accumulated / length(trials_of_current_strength);

    % Plot within the grid
    subplot(subplot_rows, subplot_cols, sidx);
    imagesc(edges(1:end-1), 1:length(unique_neurons), average_firing_rates);
    xlabel('Time (seconds relative to stimulus)');
    ylabel('Neuron #');
    title(['Strength: ', num2str(strength)]);
    colorbar;
    caxis([0, max(average_firing_rates(:))]); % Set color scale to match range of firing rates
end
%%
% Load the data
spike_times_cells = Datastore.spike_times;
spike_cluster_group = Datastore.spike_cluster_group;
fsAP = Datastore.fsAP;
stimulus_indices = Datastore.stimulus_index_AP;
session_ids = Datastore.session_id;
stimulus_strengths = Datastore.stimulus_strength;

% Identify the session ID of the first trial
first_session_id = session_ids{1};

% Identify all trials that belong to the first session
trials_of_first_session = find(cellfun(@(x) strcmp(x, first_session_id), session_ids));

% Identify unique neurons and stimulus strengths
unique_neurons = unique(spike_cluster_group{1});
unique_strengths = unique(stimulus_strengths(trials_of_first_session));

% Define the time range relative to the stimulus time
pre_stimulus_duration = 3; % seconds
post_stimulus_duration = 2; % seconds

% Define the window size
window_size = 0.01; % seconds

% Determine the number of bins before and after the stimulus
num_bins_before = ceil(pre_stimulus_duration / window_size);
num_bins_after = floor(post_stimulus_duration / window_size);

% Create edges for the histogram such that 0 is the left edge of a bin
edges = [-num_bins_before*window_size : window_size : num_bins_after*window_size];

for strength = unique_strengths'
    % Initialize a matrix to accumulate firing rates for the current strength
    firing_rates_accumulated = zeros(length(unique_neurons), length(edges) - 1);
    
    % Identify trials with the current strength
    trials_of_current_strength = trials_of_first_session(stimulus_strengths(trials_of_first_session) == strength);
    
    for trial = trials_of_current_strength'
        current_spike_times = double(spike_times_cells{trial}) / fsAP;
        current_neuron_ids = spike_cluster_group{trial};
        stimulus_time_seconds = current_spike_times(min(stimulus_indices{trial})); % Extracting the earliest stimulus time
        
        % Adjust spike times so that stimulus time is the reference (t=0)
        adjusted_spike_times_seconds = current_spike_times - stimulus_time_seconds;

        for idx = 1:length(unique_neurons)
            neuron_id = unique_neurons(idx);
            spikes_of_neuron = adjusted_spike_times_seconds(current_neuron_ids == neuron_id);
            [counts, ~] = histcounts(spikes_of_neuron, edges);
            firing_rates_accumulated(idx, :) = firing_rates_accumulated(idx, :) + counts;
        end
    end

    % Calculate average firing rates by dividing by the number of trials
    average_firing_rates = firing_rates_accumulated / length(trials_of_current_strength);

    % Visualize the average firing rates using an image
    figure;
    imagesc(edges(1:end-1), 1:length(unique_neurons), average_firing_rates);
    xlabel('Time (seconds relative to stimulus)');
    ylabel('Neuron #');
    title(['Average Firing Rates for Stimulus Strength: ', num2str(strength)]);
    colorbar;
    caxis([0, max(average_firing_rates(:))]); % Set color scale to match range of firing rates
end
%%
% Load the data
spike_times_cells = Datastore.spike_times;
spike_cluster_group = Datastore.spike_cluster_group;
fsAP = Datastore.fsAP;
stimulus_indices = Datastore.stimulus_index_AP;
session_ids = Datastore.session_id;
stimulus_strengths = Datastore.stimulus_strength;
categorical_outcomes = Datastore.categorical_outcome;

% Identify the session ID of the first trial
first_session_id = session_ids{1};

% Identify all trials that belong to the first session
trials_of_first_session = find(cellfun(@(x) strcmp(x, first_session_id), session_ids));

% Extract unique outcome categories. Extract content inside parentheses, if any.
unique_outcomes = unique(cellfun(@(x) regexprep(x, '.*\((.*)\).*', '$1'), categorical_outcomes(trials_of_first_session), 'UniformOutput', false));

% Determine number of subplots
num_outcomes = length(unique_outcomes);
num_columns = ceil(num_outcomes / 2);  % 2 rows

% Define the time range relative to the stimulus time
pre_stimulus_duration = 3; % seconds

% Define the window size
window_size = 0.01; % seconds

% Determine the number of bins before the stimulus
num_bins_before = ceil(pre_stimulus_duration / window_size);

% Create edges for the histogram such that 0 is the left edge of a bin
edges = [-num_bins_before*window_size : window_size : 0];

% Create a master figure
figure;

for outcome_idx = 1:num_outcomes
    outcome_str = unique_outcomes{outcome_idx};
    
    % Find trials corresponding to the current outcome
    matching_outcome_indices = cellfun(@(x) contains(x, outcome_str), categorical_outcomes(trials_of_first_session));
    trials_of_current_outcome = trials_of_first_session(matching_outcome_indices);
    
    % Initialize a matrix to accumulate firing rates for the current outcome
    firing_rates_accumulated = zeros(length(unique_neurons), length(edges) - 1);
    
    for trial = trials_of_current_outcome'
        current_spike_times = double(spike_times_cells{trial}) / fsAP;
        current_neuron_ids = spike_cluster_group{trial};
        stimulus_time_seconds = current_spike_times(min(stimulus_indices{trial})); % Extracting the earliest stimulus time
        
        % Adjust spike times so that stimulus time is the reference (t=0)
        adjusted_spike_times_seconds = current_spike_times - stimulus_time_seconds;

        for idx = 1:length(unique_neurons)
            neuron_id = unique_neurons(idx);
            spikes_of_neuron = adjusted_spike_times_seconds(current_neuron_ids == neuron_id);
            [counts, ~] = histcounts(spikes_of_neuron, edges);
            firing_rates_accumulated(idx, :) = firing_rates_accumulated(idx, :) + counts;
        end
    end

    % Calculate average firing rates by dividing by the number of trials
    average_firing_rates = firing_rates_accumulated / length(trials_of_current_outcome);

    % Visualize the average firing rates using an image within a subplot
    subplot(2, num_columns, outcome_idx);
    imagesc(edges(1:end-1), 1:length(unique_neurons), average_firing_rates);
    xlabel('Time (seconds before stimulus)');
    ylabel('Neuron #');
    title(['Outcome: ', outcome_str]);
    colorbar;
    caxis([0, max(average_firing_rates(:))]); % Set color scale to match range of firing rates
end

sgtitle('Average Firing Rates for Different Outcomes');