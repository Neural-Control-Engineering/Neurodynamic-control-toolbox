#!/usr/bin/bash 
source ~/.bashrc
source ~/anaconda3/etc/profile.d/conda.sh
conda activate glmhmm 
cd ~/Neurodynamic-control-toolbox/NT-GLM-HMM/NTEX_glmhmm_Model/

datavers=('last_trial_behavior_no_bias' \
'spontaneous_mpfc_s1_pupil_normalized' \
'last_trial_behavior_drop_stim_no_bias' \
'behavior_pupil_mpfc_s1_combo' \
'behavior_pupil_mpfc_combo' \
'behavior_pupil_s1_combo' \
'spontaneous_mpfc_s1_pupil_drop_stim' \
'behavior_pupil_combo' \
'behavior_mpfc_combo' \
'behavior_s1_combo' \
'behavior_mpfc_s1_combo')

animals=(240 241 242 243)
K_states=(2 3 4 5 6)
for animal in ${animals[@]}; do 
    echo $animal
    for dataver in ${datavers[@]}; do
        echo $dataver
        for K in ${K_states[@]}; do
            echo "$K states"
            python3 glm_hmm_model.py --target=../data/v2/$dataver/unshuffled/"$animal"_"$dataver".mat --K_states=$K --results_dir=../data/v2/"$dataver"/unshuffled/results/
        done
    done
done