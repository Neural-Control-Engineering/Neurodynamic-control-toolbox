clc;clear all; close all;
paths = setPaths('Project_Neurotransmitter-Exploration');
target_DStore = '240_241_242_243_Datastore_created_26-Mar-2023.mat';
load_path = fullfile(paths.all_data_path,'Datastores',target_DStore);
load(load_path)
temp  = gather(Datastore(:,5));
all_nonempty_index = find(~cellfun(@isempty,temp));
all_trial_number = cell2mat( ...
    fetch_Dstore_with_indices(Datastore,6,all_nonempty_index));
all_session_number = cell2mat( ...
    fetch_Dstore_with_indices(Datastore,5,all_nonempty_index));
all_session_ID = fetch_Dstore_with_indices(Datastore,1,all_nonempty_index);
all_phase = fetch_Dstore_with_indices(Datastore,4,all_nonempty_index);


%% 
%
all_previous_outcome = fetch_Dstore_with_indices(Datastore,16,all_nonempty_index);
all_stim_strength = fetch_Dstore_with_indices(Datastore,10,all_nonempty_index);
all_psy_curve = fetch_Dstore_with_indices(Datastore,47,all_nonempty_index);
all_gonogo = fetch_Dstore_with_indices(Datastore,13,all_nonempty_index);

Hitrate_20Psi = cellfun(@(y)y(2,end),all_psy_curve(:,1));

%%
lg_phase = ([all_phase{:,1}] == "Phase III")'; %!!
lg_performance = (Hitrate_20Psi > 0.5);
lg_toprocess = lg_phase & lg_performance;

toprocess_session_ID = all_session_ID(lg_toprocess,1);
toprocess_trial_number = all_trial_number(lg_toprocess,1);
toprocess_previous_outcome = all_previous_outcome(lg_toprocess,1);
toprocess_stim_strength = all_stim_strength(lg_toprocess,1);
toprocess_gonogo = all_gonogo(lg_toprocess,1);

empty_previous_outcome = find(cellfun(@isempty, toprocess_previous_outcome));
empty_previous_outcome(end+1) = numel(toprocess_previous_outcome);
%%
preprocessed_input = cell(numel(empty_previous_outcome)-1,1);
preprocessed_label = cell(numel(empty_previous_outcome)-1,1);
preprocessed_session = cell(numel(empty_previous_outcome)-1,1);
preprocessed_trial_number = cell(numel(empty_previous_outcome)-1,1);
% preprocessed_record = 
for i = 1:numel(empty_previous_outcome)-1
    start_index =empty_previous_outcome(i)+1;
    end_index = empty_previous_outcome(i+1)-1;
    matrix_this = zeros(end_index-start_index+1,4);
    matrix_this(:, 4) = 1;
    matrix_this(:, 1) = [toprocess_stim_strength{start_index:end_index}]/2;
    temp = toprocess_previous_outcome(start_index:end_index);
    last_rewardstate = ([temp{:}] == "Hit")';
    last_gonogo = ([temp{:}] == "Hit")' | ([temp{:}] == "FA")';
    matrix_this(:, 2) = last_gonogo;
    matrix_this(:, 3) = last_rewardstate;
    preprocessed_input{i} = matrix_this;
    preprocessed_label{i} = toprocess_gonogo(start_index:end_index);
    preprocessed_session{i} = toprocess_session_ID{start_index};
    preprocessed_trial_number{i} = toprocess_trial_number(start_index:end_index)';
end

%%
save_path = fullfile(paths.all_data_path,'GLM_HMM_Data','preprocessed_data',strcat('preprocessed_',target_DStore));
save(save_path,"preprocessed_input","preprocessed_label","preprocessed_session","preprocessed_trial_number")