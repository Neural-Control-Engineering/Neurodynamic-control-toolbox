function [behavior] = fetch_phase_0_w_stim_behavior(Data,start_buffer,end_buffer)

%%% Data.Tones.data is composed of 7 columns which record:
%       1. Trial onset tone (1 indicates tone occurs)
%       2. Punishment log (only value is 2 in this phase, correponds to
%          licking after distractor
%       3. Reward log (2 is used in this phase for an automatic, large
%          when a 40 psi stimulus puff is delivered
%       4. Timeout Log (not used in tasks that don't integrate data from
%          the wheel
%       5. PrStim Out - Voltage sent to give stimulus puff for each trial -
%          for phase I it has two values, 0 (for 0 psi) and 4 (for 40 psi)
%       6. Air Puff: 0 = no puff; 1 = stimulation coupled with a distractor
%          -1 = distractor puff only; -2 means a punishment puff; -3 =
%          0 psi stimulation coupled with a distractor
%       7. Time
%%%


% Only 6 of the variables from Tones are used in this phase + 1
% column from Data.Licks, we will summarize them all below, but
% need to keep track of where to put them
vars = 7;
column = 1;

% Column 1
% Find the index where a trial onset tone is recorded and the corresponding
% session time (value should always be recorded as 1)
trial_start_index = find(Data.Data.Tones.data(:,1)==1);
trial_start_time = zeros(length(trial_start_index),vars);
trial_start_time(:,column) = ones(length(trial_start_index),1);
trial_start_time(:,vars) = Data.Data.Tones.data(trial_start_index,7);
column = column + 1;

% Column 2
% Find the index where a punishment for licking after a distractor occured
% and the corresponding session time (only value is 2 in phase I)
punishment_index = find(Data.Data.Tones.data(:,2)==2);
punishment_time = zeros(length(punishment_index),vars);
punishment_time(:,column) = ones(length(punishment_index),1);
punishment_time(:,vars) = Data.Data.Tones.data(punishment_index,7);
column = column + 1;

% Column 3
% Find the index where a reward tone is given automatically after a
% stimulus puff is delivered (only value is 2 in phase I)
reward_index = find(Data.Data.Tones.data(:,3)==2);
reward_time = zeros(length(reward_index),vars);
reward_time(:,column) = ones(length(reward_index),1);
reward_time(:,vars) = Data.Data.Tones.data(reward_index,7);
column = column + 1;

% Column 4 and 5
% Find the index where type of puff delivered is recorded and the strength
% of stimulus
stim_index = find(Data.Data.Tones.data(:,6)==1 | Data.Data.Tones.data(:,6)==-3);
stim_time = zeros(length(stim_index),vars);
stim_time(:,column) = Data.Data.Tones.data(stim_index,5);
stim_time(:,vars) = Data.Data.Tones.data(stim_index,7);
column = column + 1;

stim_time(:,column) = Data.Data.Tones.data(stim_index,6);
column = column + 1;

distractor_index = find(Data.Data.Tones.data(:,6)==-1);
distractor_time = zeros(length(distractor_index),vars);
distractor_time(:,column) = ones(length(distractor_index),1);
distractor_time(:,vars) = Data.Data.Tones.data(distractor_index,7);

% Column 6
% Find where the animal licks and the associated time stamp
lick_index = find(Data.Data.Licks.data(:,1)==1);
lick_time = zeros(length(lick_index),vars);
lick_time(:,column) = Data.Data.Licks.data(lick_index,1);
lick_time(:,vars) = Data.Data.Licks.data(lick_index,2);

% Define behavior structure (each element has a list of times for all
% events in a given session.
behavior.trial_onset_tone(:,1) = trial_start_time(trial_start_time(:,vars)>=start_buffer & trial_start_time(:,vars)<=trial_start_time(end,vars)-end_buffer,vars)-start_buffer;

if ~isempty(punishment_time)
    behavior.punishment_times(:,1) = punishment_time(punishment_time(:,vars)>=behavior.trial_onset_tone(1)+start_buffer & punishment_time(:,vars)<=punishment_time(end,vars)-end_buffer,vars)-start_buffer;
else
    behavior.punishment_times = [];
end

if ~isempty(reward_time) 
    behavior.reward_times(:,1) = reward_time(reward_time(:,vars)>=behavior.trial_onset_tone(1)+start_buffer & reward_time(:,vars)<=reward_time(end,vars)-end_buffer,vars)-start_buffer;
else
    behavior.reward_times = [];
end

behavior.stim_strength(:,1) = stim_time(stim_time(:,vars)>=behavior.trial_onset_tone(1)+start_buffer & stim_time(:,vars)<=stim_time(end,vars)-end_buffer,4);
behavior.stim_times(:,1) = stim_time(stim_time(:,vars)>=behavior.trial_onset_tone(1)+start_buffer & stim_time(:,vars)<=stim_time(end,vars)-end_buffer,vars)-start_buffer;
if ~isempty(lick_time)
    behavior.lick_times(:,1) = lick_time(lick_time(:,vars)>=behavior.trial_onset_tone(1)+start_buffer & lick_time(:,vars)<=lick_time(end,vars)-end_buffer,vars)-start_buffer;
else
    behavior.lick_times = [];
end
%behavior.distractor_times(:,1) = distractor_time(distractor_time(:,vars)>=behavior.trial_onset_tone(1)+start_buffer & distractor_time(:,vars)<=distractor_time(end,vars)-end_buffer,vars)-start_buffer;

% Add wheel displacement values
Data.Data.SelfInit.data(Data.Data.SelfInit.data(:,2)==0,2) = NaN;
behavior.wheel_displacement(:,1) = downsample(Data.Data.SelfInit.data(Data.Data.SelfInit.data(:,4)>=start_buffer & Data.Data.SelfInit.data(:,4)<=Data.Data.SelfInit.data(end,4)-end_buffer,4),10)-start_buffer;
behavior.wheel_displacement(:,2) = downsample(Data.Data.SelfInit.data(Data.Data.SelfInit.data(:,4)>=start_buffer & Data.Data.SelfInit.data(:,4)<=Data.Data.SelfInit.data(end,4)-end_buffer,2),10);
