function [behavior] = fetch_phase_0_behavior(Data,start_buffer,end_buffer)

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

% Calculate lick times (spontaneous licks) during phase 0
lick_times = Data.Data.Licks.data((Data.Data.Licks.data(:,2) >= start_buffer) & (Data.Data.Licks.data(:,2) <= Data.Data.Licks.data(end,2) - end_buffer),:);
lick_times = lick_times(lick_times(:,1)==1,2);

% Define behavior structure (each element has a list of times for all
% events in a given session.
behavior.trial_onset_tone = [];
behavior.punishment_times = [];
behavior.reward_times = [];
behavior.stim_strength = [];
behavior.stim_times = [];
behavior.lick_times = lick_times;



