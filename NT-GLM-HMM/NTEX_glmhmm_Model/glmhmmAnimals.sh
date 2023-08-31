#!/usr/bin/bash 
source ~/.bashrc
source ~/anaconda3/etc/profile.d/conda.sh
conda activate glmhmm 
cd ~/Neurodynamic-control-toolbox/NT-GLM-HMM/NTEX_glmhmm_Model/
python3 glm_hmm_model.py --target=../combo/unshuffled/3316_behavior_phys_combo.mat --K_states=3 --results_dir=../combo/unshuffled/results/
python3 glm_hmm_model.py --target=../combo/unshuffled/3258_behavior_phys_combo.mat --K_states=3 --results_dir=../combo/unshuffled/results/
python3 glm_hmm_model.py --target=../combo/unshuffled/3133_behavior_phys_combo.mat --K_states=3 --results_dir=../combo/unshuffled/results/
python3 glm_hmm_model.py --target=../combo/unshuffled/200_behavior_phys_combo.mat --K_states=3 --results_dir=../combo/unshuffled/results/
python3 glm_hmm_model.py --target=../combo/unshuffled/199_behavior_phys_combo.mat --K_states=3 --results_dir=../combo/unshuffled/results/
python3 glm_hmm_model.py --target=../combo/unshuffled/198_behavior_phys_combo.mat --K_states=3 --results_dir=../combo/unshuffled/results/
python3 glm_hmm_model.py --target=../combo/unshuffled/197_behavior_phys_combo.mat --K_states=3 --results_dir=../combo/unshuffled/results/
python3 glm_hmm_model.py --target=../combo/unshuffled/196_behavior_phys_combo.mat --K_states=3 --results_dir=../combo/unshuffled/results/
python3 glm_hmm_model.py --target=../combo/unshuffled/180_behavior_phys_combo.mat --K_states=3 --results_dir=../combo/unshuffled/results/
python3 glm_hmm_model.py --target=../combo/unshuffled/167_behavior_phys_combo.mat --K_states=3 --results_dir=../combo/unshuffled/results/
python3 glm_hmm_model.py --target=../combo/unshuffled/152_behavior_phys_combo.mat --K_states=3 --results_dir=../combo/unshuffled/results/
# python3 glm_hmm_model.py --target=../spontaneous/normalized/3316_spon_photo_pupil_norm.mat --K_states=3 --results_dir=../spontaneous/normalized/results/
# python3 glm_hmm_model.py --target=../spontaneous/normalized/3258_spon_photo_pupil_norm.mat --K_states=3 --results_dir=../spontaneous/normalized/results/
# python3 glm_hmm_model.py --target=../spontaneous/normalized/3133_spon_photo_pupil_norm.mat --K_states=3 --results_dir=../spontaneous/normalized/results/
# python3 glm_hmm_model.py --target=../spontaneous/normalized/200_spon_photo_pupil_norm.mat --K_states=3 --results_dir=../spontaneous/normalized/results/
# python3 glm_hmm_model.py --target=../spontaneous/normalized/199_spon_photo_pupil_norm.mat --K_states=3 --results_dir=../spontaneous/normalized/results/
# python3 glm_hmm_model.py --target=../spontaneous/normalized/198_spon_photo_pupil_norm.mat --K_states=3 --results_dir=../spontaneous/normalized/results/
# python3 glm_hmm_model.py --target=../spontaneous/normalized/197_spon_photo_pupil_norm.mat --K_states=3 --results_dir=../spontaneous/normalized/results/
# python3 glm_hmm_model.py --target=../spontaneous/normalized/196_spon_photo_pupil_norm.mat --K_states=3 --results_dir=../spontaneous/normalized/results/
# python3 glm_hmm_model.py --target=../spontaneous/normalized/180_spon_photo_pupil_norm.mat --K_states=3 --results_dir=../spontaneous/normalized/results/
# python3 glm_hmm_model.py --target=../spontaneous/normalized/167_spon_photo_pupil_norm.mat --K_states=3 --results_dir=../spontaneous/normalized/results/
# python3 glm_hmm_model.py --target=../spontaneous/normalized/152_spon_photo_pupil_norm.mat --K_states=3 --results_dir=../spontaneous/normalized/results/
# python3 glm_hmm_model.py --target=../spon_data_drop_stim/3316_spon_photo_pupil_drop_stim.mat --K_states=3 --results_dir=../spon_data_drop_stim/results/
# python3 glm_hmm_model.py --target=../spon_data_drop_stim/3258_spon_photo_pupil_drop_stim.mat --K_states=3 --results_dir=../spon_data_drop_stim/results/
# python3 glm_hmm_model.py --target=../spon_data_drop_stim/3133_spon_photo_pupil_drop_stim.mat --K_states=3 --results_dir=../spon_data_drop_stim/results/
# python3 glm_hmm_model.py --target=../spon_data_drop_stim/200_spon_photo_pupil_drop_stim.mat --K_states=3 --results_dir=../spon_data_drop_stim/results/
# python3 glm_hmm_model.py --target=../spon_data_drop_stim/199_spon_photo_pupil_drop_stim.mat --K_states=3 --results_dir=../spon_data_drop_stim/results/
# python3 glm_hmm_model.py --target=../spon_data_drop_stim/198_spon_photo_pupil_drop_stim.mat --K_states=3 --results_dir=../spon_data_drop_stim/results/
# python3 glm_hmm_model.py --target=../spon_data_drop_stim/197_spon_photo_pupil_drop_stim.mat --K_states=3 --results_dir=../spon_data_drop_stim/results/
# python3 glm_hmm_model.py --target=../spon_data_drop_stim/196_spon_photo_pupil_drop_stim.mat --K_states=3 --results_dir=../spon_data_drop_stim/results/
# python3 glm_hmm_model.py --target=../spon_data_drop_stim/180_spon_photo_pupil_drop_stim.mat --K_states=3 --results_dir=../spon_data_drop_stim/results/
# python3 glm_hmm_model.py --target=../spon_data_drop_stim/167_spon_photo_pupil_drop_stim.mat --K_states=3 --results_dir=../spon_data_drop_stim/results/
# python3 glm_hmm_model.py --target=../spon_data_drop_stim/152_spon_photo_pupil_drop_stim.mat --K_states=3 --results_dir=../spon_data_drop_stim/results/
# python3 glm_hmm_model.py --target=../prev_behavior/drop_stim/3316_last_trial_behavior_drop_stim.mat --K_states=3 --results_dir=../prev_behavior/drop_stim/results/
# python3 glm_hmm_model.py --target=../prev_behavior/drop_stim/3258_last_trial_behavior_drop_stim.mat --K_states=3 --results_dir=../prev_behavior/drop_stim/results/
# python3 glm_hmm_model.py --target=../prev_behavior/drop_stim/3133_last_trial_behavior_drop_stim.mat --K_states=3 --results_dir=../prev_behavior/drop_stim/results/
# python3 glm_hmm_model.py --target=../prev_behavior/drop_stim/200_last_trial_behavior_drop_stim.mat --K_states=3 --results_dir=../prev_behavior/drop_stim/results/
# python3 glm_hmm_model.py --target=../prev_behavior/drop_stim/199_last_trial_behavior_drop_stim.mat --K_states=3 --results_dir=../prev_behavior/drop_stim/results/
# python3 glm_hmm_model.py --target=../prev_behavior/drop_stim/198_last_trial_behavior_drop_stim.mat --K_states=3 --results_dir=../prev_behavior/drop_stim/results/
# python3 glm_hmm_model.py --target=../prev_behavior/drop_stim/197_last_trial_behavior_drop_stim.mat --K_states=3 --results_dir=../prev_behavior/drop_stim/results/
# python3 glm_hmm_model.py --target=../prev_behavior/drop_stim/196_last_trial_behavior_drop_stim.mat --K_states=3 --results_dir=../prev_behavior/drop_stim/results/
# python3 glm_hmm_model.py --target=../prev_behavior/drop_stim/180_last_trial_behavior_drop_stim.mat --K_states=3 --results_dir=../prev_behavior/drop_stim/results/
# python3 glm_hmm_model.py --target=../prev_behavior/drop_stim/167_last_trial_behavior_drop_stim.mat --K_states=3 --results_dir=../prev_behavior/drop_stim/results/
# python3 glm_hmm_model.py --target=../prev_behavior/drop_stim/152_last_trial_behavior_drop_stim.mat --K_states=3 --results_dir=../prev_behavior/drop_stim/results/
# python3 glm_hmm_model.py --target=../prev_behavior/unshuffled/3316_last_trial_behavior.mat --K_states=3 --results_dir=../prev_behavior/unshuffled/
# python3 glm_hmm_model.py --target=../prev_behavior/unshuffled/3258_last_trial_behavior.mat --K_states=3 --results_dir=../prev_behavior/unshuffled/
# python3 glm_hmm_model.py --target=../prev_behavior/unshuffled/3133_last_trial_behavior.mat --K_states=3 --results_dir=../prev_behavior/unshuffled/
# python3 glm_hmm_model.py --target=../prev_behavior/unshuffled/200_last_trial_behavior.mat --K_states=3 --results_dir=../prev_behavior/unshuffled/
# python3 glm_hmm_model.py --target=../prev_behavior/unshuffled/199_last_trial_behavior.mat --K_states=3 --results_dir=../prev_behavior/unshuffled/
# python3 glm_hmm_model.py --target=../prev_behavior/unshuffled/198_last_trial_behavior.mat --K_states=3 --results_dir=../prev_behavior/unshuffled/
# python3 glm_hmm_model.py --target=../prev_behavior/unshuffled/197_last_trial_behavior.mat --K_states=3 --results_dir=../prev_behavior/unshuffled/
# python3 glm_hmm_model.py --target=../prev_behavior/unshuffled/196_last_trial_behavior.mat --K_states=3 --results_dir=../prev_behavior/unshuffled/
# python3 glm_hmm_model.py --target=../prev_behavior/unshuffled/180_last_trial_behavior.mat --K_states=3 --results_dir=../prev_behavior/unshuffled/
# python3 glm_hmm_model.py --target=../prev_behavior/unshuffled/167_last_trial_behavior.mat --K_states=3 --results_dir=../prev_behavior/unshuffled/
# python3 glm_hmm_model.py --target=../prev_behavior/unshuffled/152_last_trial_behavior.mat --K_states=3 --results_dir=../prev_behavior/unshuffled/
# python3 glm_hmm_model.py --target=../animal_data_v2/243_spon_photo_pupil_v2.mat --K_states=5 --results_dir=../results_v2/
# python3 glm_hmm_model.py --target=../animal_data_v2/242_spon_photo_pupil_v2.mat --K_states=5 --results_dir=../results_v2/
# python3 glm_hmm_model.py --target=../animal_data_v2/241_spon_photo_pupil_v2.mat --K_states=5 --results_dir=../results_v2/
# python3 glm_hmm_model.py --target=../animal_data_v2/240_spon_photo_pupil_v2.mat --K_states=5 --results_dir=../results_v2/
# python3 glm_hmm_model.py --target=../animal_data_v2/243_spon_photo_pupil_v2.mat --K_states=4 --results_dir=../results_v2/
# python3 glm_hmm_model.py --target=../animal_data_v2/242_spon_photo_pupil_v2.mat --K_states=4 --results_dir=../results_v2/
# python3 glm_hmm_model.py --target=../animal_data_v2/241_spon_photo_pupil_v2.mat --K_states=4 --results_dir=../results_v2/
# python3 glm_hmm_model.py --target=../animal_data_v2/240_spon_photo_pupil_v2.mat --K_states=4 --results_dir=../results_v2/
# python3 glm_hmm_model.py --target=../animal_data_v2/243_spon_photo_pupil_v2.mat --K_states=3 --results_dir=../results_v2/
# python3 glm_hmm_model.py --target=../animal_data_v2/242_spon_photo_pupil_v2.mat --K_states=3 --results_dir=../results_v2/
# python3 glm_hmm_model.py --target=../animal_data_v2/241_spon_photo_pupil_v2.mat --K_states=3 --results_dir=../results_v2/
# python3 glm_hmm_model.py --target=../animal_data_v2/240_spon_photo_pupil_v2.mat --K_states=3 --results_dir=../results_v2/
# python3 glm_hmm_model.py --target=../animal_data_v2/243_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_v2/
# python3 glm_hmm_model.py --target=../animal_data_v2/242_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_v2/
# python3 glm_hmm_model.py --target=../animal_data_v2/241_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_v2/
# python3 glm_hmm_model.py --target=../animal_data_v2/240_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_v2/
# python3 glm_hmm_model.py --target=../animal_data/3316_spon_photo_pupil_v2.mat --K_states=5
# python3 glm_hmm_model.py --target=../animal_data/3258_spon_photo_pupil_v2.mat --K_states=5
# python3 glm_hmm_model.py --target=../animal_data/3133_spon_photo_pupil_v2.mat --K_states=5
# python3 glm_hmm_model.py --target=../animal_data/200_spon_photo_pupil_v2.mat --K_states=5
# python3 glm_hmm_model.py --target=../animal_data/199_spon_photo_pupil_v2.mat --K_states=5
# python3 glm_hmm_model.py --target=../animal_data/198_spon_photo_pupil_v2.mat --K_states=5
# python3 glm_hmm_model.py --target=../animal_data/197_spon_photo_pupil_v2.mat --K_states=5
# python3 glm_hmm_model.py --target=../animal_data/196_spon_photo_pupil_v2.mat --K_states=5
# python3 glm_hmm_model.py --target=../animal_data/180_spon_photo_pupil_v2.mat --K_states=5
# python3 glm_hmm_model.py --target=../animal_data/167_spon_photo_pupil_v2.mat --K_states=5
# python3 glm_hmm_model.py --target=../animal_data/152_spon_photo_pupil_v2.mat --K_states=5
# python3 glm_hmm_model.py --target=../animal_data/3316_spon_photo_pupil_v2.mat --K_states=2
# python3 glm_hmm_model.py --target=../animal_data/3258_spon_photo_pupil_v2.mat --K_states=2
# python3 glm_hmm_model.py --target=../animal_data/3133_spon_photo_pupil_v2.mat --K_states=2
# python3 glm_hmm_model.py --target=../animal_data/200_spon_photo_pupil_v2.mat --K_states=2
# python3 glm_hmm_model.py --target=../animal_data/199_spon_photo_pupil_v2.mat --K_states=2
# python3 glm_hmm_model.py --target=../animal_data/198_spon_photo_pupil_v2.mat --K_states=2
# python3 glm_hmm_model.py --target=../animal_data/197_spon_photo_pupil_v2.mat --K_states=2
# python3 glm_hmm_model.py --target=../animal_data/196_spon_photo_pupil_v2.mat --K_states=2
# python3 glm_hmm_model.py --target=../animal_data/180_spon_photo_pupil_v2.mat --K_states=2
# python3 glm_hmm_model.py --target=../animal_data/167_spon_photo_pupil_v2.mat --K_states=2
# python3 glm_hmm_model.py --target=../animal_data/152_spon_photo_pupil_v2.mat --K_states=2
# python3 glm_hmm_model.py --target=../animal_data/3316_spon_photo_pupil_v2.mat --K_states=3
# python3 glm_hmm_model.py --target=../animal_data/3258_spon_photo_pupil_v2.mat --K_states=3
# python3 glm_hmm_model.py --target=../animal_data/3133_spon_photo_pupil_v2.mat --K_states=3
# python3 glm_hmm_model.py --target=../animal_data/200_spon_photo_pupil_v2.mat --K_states=3
# python3 glm_hmm_model.py --target=../animal_data/199_spon_photo_pupil_v2.mat --K_states=3
# python3 glm_hmm_model.py --target=../animal_data/198_spon_photo_pupil_v2.mat --K_states=3
# python3 glm_hmm_model.py --target=../animal_data/197_spon_photo_pupil_v2.mat --K_states=3
# python3 glm_hmm_model.py --target=../animal_data/196_spon_photo_pupil_v2.mat --K_states=3
# python3 glm_hmm_model.py --target=../animal_data/180_spon_photo_pupil_v2.mat --K_states=3
# python3 glm_hmm_model.py --target=../animal_data/167_spon_photo_pupil_v2.mat --K_states=3
# python3 glm_hmm_model.py --target=../animal_data/152_spon_photo_pupil_v2.mat --K_states=3
# python3 glm_hmm_model.py --target=../animal_data/3316_spon_photo_pupil_v2.mat --K_states=4
# python3 glm_hmm_model.py --target=../animal_data/3258_spon_photo_pupil_v2.mat --K_states=4
# python3 glm_hmm_model.py --target=../animal_data/3133_spon_photo_pupil_v2.mat --K_states=4
# python3 glm_hmm_model.py --target=../animal_data/200_spon_photo_pupil_v2.mat --K_states=4
# python3 glm_hmm_model.py --target=../animal_data/199_spon_photo_pupil_v2.mat --K_states=4
# python3 glm_hmm_model.py --target=../animal_data/198_spon_photo_pupil_v2.mat --K_states=4
# python3 glm_hmm_model.py --target=../animal_data/197_spon_photo_pupil_v2.mat --K_states=4
# python3 glm_hmm_model.py --target=../animal_data/196_spon_photo_pupil_v2.mat --K_states=4
# python3 glm_hmm_model.py --target=../animal_data/180_spon_photo_pupil_v2.mat --K_states=4
# python3 glm_hmm_model.py --target=../animal_data/167_spon_photo_pupil_v2.mat --K_states=4
# python3 glm_hmm_model.py --target=../animal_data/152_spon_photo_pupil_v2.mat --K_states=4
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/3316_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/3258_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/3133_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/200_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/199_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/198_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/197_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/196_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/180_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/167_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/152_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/3258_spon_photo_pupil_v2.mat --K_states=3 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/3133_spon_photo_pupil_v2.mat --K_states=3 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/200_spon_photo_pupil_v2.mat --K_states=3 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/199_spon_photo_pupil_v2.mat --K_states=3 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/198_spon_photo_pupil_v2.mat --K_states=3 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/197_spon_photo_pupil_v2.mat --K_states=3 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/196_spon_photo_pupil_v2.mat --K_states=3 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/180_spon_photo_pupil_v2.mat --K_states=3 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/167_spon_photo_pupil_v2.mat --K_states=3 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/152_spon_photo_pupil_v2.mat --K_states=3 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/3258_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/3133_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/200_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/199_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/198_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/197_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/196_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/180_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/167_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/152_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/3316_spon_photo_pupil_v2.mat --K_states=3 --results_dir=../results_shuffle_phys/
# python3 glm_hmm_model.py --target=../animal_data_v1_shuffle/3316_spon_photo_pupil_v2.mat --K_states=2 --results_dir=../results_shuffle_phys/
