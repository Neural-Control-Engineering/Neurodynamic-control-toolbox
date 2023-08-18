"""Copy of Model_based_on_mat.ipynb, but setup to train the model with metrics from 
photometry data of the previous trial
Craig Kelley, NEC Lab, 8/16/23"""

import time
start_time = time.time()
import scipy.io
import pickle
from sklearn.utils import shuffle
from datetime import datetime
import sys
import matplotlib.pyplot as plt
import ssm
import autograd.numpy as np
from LapseModel_ntex import lapse_model
from lapse_utils_ntex import get_parmin, get_parmax, get_parstart, fit_lapse_multiple_init, \
    calculate_predictive_acc_lapse_model
from glm_utils_ntex import fit_glm, calculate_predictive_acc_glm, \
    plot_input_vectors, append_zeros, fit_glm_multiple_init
from glm_hmm_utils_ntex import calculate_predictive_acc_glmhmm_ntex_parted, \
    fit_glmhmm_multiple_init, get_posterior_states_labels, get_posterior_states_labels_parted
from plotting_utils_ntex import plot_glmhmm_weights
import multiprocessing

# target = '../../glmhmm_example_trimmed_v2.mat'
target = '/home/craig/ntex/GLM_HMM_Data/preprocessed_data/preprocessed_240_241_242_243_Datastore_created_26-Mar-2023.mat'

loaded = scipy.io.loadmat(target)
loaded_mat_keys = loaded.keys()
print(loaded_mat_keys)
input = loaded["preprocessed_input"]
label = loaded["preprocessed_label"]

input_compatible = [x[0] for x in input]
label_compatible = [np.array([[y[0][0][0]] for y in x[0]]).astype(int) for x in label ]

input_shuffled, y_shuffled = shuffle(input_compatible, label_compatible,
                                   random_state=66)

fold = 5
C = 2  # number of output types/categories here with only two: response or not
D = 1  # dimension of data (observations)
transition_alpha = 1  # Hyperparameter
prior_sigma = 100  # Hyperparameter
K_states = 3  # Number of states you wish to observe

n_init = 5 # number of times for independent runs in which the one with the best predictive acc would be selected out
N_em_iters = 500  # number of max iterations for the expectation-maximization algorithm, which is set to prevent non-converging situation
global_fit = True  # If global_fit true, use GLM parameter as initial params for glmhmm
# If global_fit false, pretrained glmhmm params are needed and used as as initial params for glmhmm


# get time now and result storing path to saving data such as the trained glmhmm parameters
results_dir = '../results/'
N_property = len(input_shuffled[0][0])
M_GLM = N_property-1  # Number of inputs for each trial for the model
# Since GLM model already has the bias colum, so remove this column before feeding to it, which is column 4
input_index_glm = list(range(0, M_GLM))
M_HMM = N_property  # Number of inputs for each trial for the model
input_index_hmm = list(range(0, M_HMM))

data_size = len(input_shuffled)
Acc_GLM_5fold = []
# Param_GLM_5fold = []
# Acc_HMM_5fold = []
# Param_HMM_5fold = []

manager = multiprocessing.Manager()
return_dict = manager.dict()
input_data = [(input_shuffled, y_shuffled, M_GLM, M_HMM, C, D, i) for i in range(fold)]

def train(inputs):
    # parse inputs
    input_shuffled = inputs[0]
    y_shuffled = inputs[1]
    M_GLM = inputs[2]
    M_HMM = inputs[3]
    C = inputs[4]
    D = inputs[5]
    j = inputs[6]
    input_this_test_hmm = [
        x[:, input_index_hmm]
        for c, x in enumerate(input_shuffled)
        if j*len(input_shuffled)/fold <= c <= (j+1)*len(input_shuffled)/fold]
    y_this_test_hmm = [
        x[:, :]
        for c, x in enumerate(y_shuffled)
        if j*len(input_shuffled)/fold <= c <= (j+1)*len(input_shuffled)/fold]
    input_this_train_hmm = [
        x[:, input_index_hmm]
        for c, x in enumerate(input_shuffled)
        if c < j*len(input_shuffled)/fold or c > (j+1)*len(input_shuffled)/fold]
    y_this_train_hmm = [
        x[:, :]
        for c, x in enumerate(y_shuffled)
        if c < j*len(input_shuffled)/fold or c > (j+1)*len(input_shuffled)/fold]
    
    # get glm training and test set, for glm training, the data should not be parted, that concatenaed
    input_this_test_glm = []
    input_this_train_glm = []
    y_this_test_glm = []
    y_this_train_glm = []
    for c, x in enumerate(input_shuffled):
        if j*len(input_shuffled)/ fold <= c <= (j + 1)*len(input_shuffled)/ fold:
            if len(input_this_test_glm) == 0:
                input_this_test_glm = x[:, input_index_glm]
                y_this_test_glm = y_shuffled[c]
            else:
                input_this_test_glm = np.concatenate((
                    input_this_test_glm, x[:, input_index_glm]))
                y_this_test_glm = np.concatenate((
                    y_this_test_glm, y_shuffled[c]))
        else:
            if len(input_this_train_glm) == 0:
                input_this_train_glm = x[:, input_index_glm]
                y_this_train_glm = y_shuffled[c]
            else:
                input_this_train_glm = np.concatenate((
                    input_this_train_glm, x[:, input_index_glm]))
                y_this_train_glm = np.concatenate((
                    y_this_train_glm, y_shuffled[c]))
    # run GLM model training
    best_param_glm, best_acc_glm = fit_glm_multiple_init(
        input_this_train_glm, y_this_train_glm,
        input_this_test_glm, y_this_test_glm,
        M_GLM, C, n_init)
    # return_dict['Param_GLM_5fold'] = return_dict['Param_GLM_5fold'] + best_param_glm
    # return_dict['Param_GLM_5fold'] = return_dict['Param_GLM_5fold'] + best_acc_glm
    tmp_dict = {}
    tmp_dict['Param_GLM_5fold'] = [best_param_glm, best_acc_glm]


    # start GLM HMM training
    now = datetime.now()
    time_str = now.strftime("%Y-%m-%d-%H%M%S")
    weights_glmhmm_example, acc_glmhmm_example = fit_glmhmm_multiple_init(
        input_this_train_hmm, y_this_train_hmm,
        input_this_test_hmm, y_this_test_hmm,
        [np.ones([len(x), 1]) for x in y_this_train_hmm],
        # this parameter provides a function to exclude some trials, if you want to use all trials,
        # create a matrix of ones in the same shape as the y dataset
        K_states, D, M_HMM, C, N_em_iters, transition_alpha,
        prior_sigma, global_fit, best_param_glm,
        'training_cache/glmhmm_' + time_str,
        n_init, partition=True)
    tmp_dict['Param_HMM_5fold'] =  weights_glmhmm_example
    tmp_dict['Acc_HMM_5fold'] =  acc_glmhmm_example
    return_dict[j] = tmp_dict
    
pool = multiprocessing.Pool()
pool.map(train, input_data)

Acc_HMM_5fold = [return_dict[key]['Acc_HMM_5fold'] for key in return_dict.keys()]
Param_HMM_5fold = [return_dict[key]['Param_HMM_5fold'] for key in return_dict.keys()]
Param_GLM_5fold = [return_dict[key]['Param_GLM_5fold'] for key in return_dict.keys()]

# Best_param = Param_HMM_5fold[Acc_HMM_5fold.index(max(Acc_HMM_load))]
Best_param = Param_HMM_5fold[Acc_HMM_5fold.index(max(Acc_HMM_5fold))]
K_states = 3
#input_compatible
#label_compatible
# states_probs: for each trial what is its probability in state1, state2 and so on
# predicted_states: basically find the max one among the states_probs for each trial
# predicted_response_prob: the predicted probability of response
# predicted_label: If predicted_response_prob > 50, labeled as response trial, otherwise no-response trial
states_probs, predicted_states, predicted_label, predicted_response_prob = \
    get_posterior_states_labels_parted(
        input_compatible, label_compatible,
        Best_param, K_states, range(K_states))

results_dir = '../results/'
time_str =  datetime.now().strftime("%Y-%m-%d-%H%M%S")
np.savez(results_dir+'predicted_states_and_labels_24x_NEmice_' + time_str + '.npz',
         states_probs,
         predicted_states,
         predicted_response_prob,
         predicted_label
         )
# result_dir_2matlab = "/mnt/g/My Drive/#Projects/Project_Neurotransmitter-Exploration/GLM_HMM_Data/GLM_HMM_processed_result/"
result_dir_2matlab = "./"
scipy.io.savemat(result_dir_2matlab+'predicted_states_and_labels_24x_NEmice_Python2mat' + time_str +'.mat',
                 dict(
                     states_probs = states_probs,
                     predicted_states = predicted_states,
                     predicted_response_prob = predicted_response_prob,
                     predicted_label = predicted_label,
                 ))

# result_dir_2matlab = "/mnt/g/My Drive/#Projects/Project_Neurotransmitter-Exploration/GLM_HMM_Data/GLM_HMM_processed_result/"
result_dir_2matlab = "./"
scipy.io.savemat(result_dir_2matlab+'predicted_states_and_labels_24x_NEmice_Python2mat' + time_str +'.mat',
                 dict(
                     states_probs = states_probs,
                     predicted_states = predicted_states,
                     predicted_response_prob = predicted_response_prob,
                     predicted_label = predicted_label,
                 ))

# train(input_data[0])


# for j in range(fold):
#     # get hmm training and test set, for hmm training, the data should be parted into sessions
#     input_this_test_hmm = [
#         x[:, input_index_hmm]
#         for c, x in enumerate(input_shuffled)
#         if j*len(input_shuffled)/fold <= c <= (j+1)*len(input_shuffled)/fold]
#     y_this_test_hmm = [
#         x[:, :]
#         for c, x in enumerate(y_shuffled)
#         if j*len(input_shuffled)/fold <= c <= (j+1)*len(input_shuffled)/fold]
#     input_this_train_hmm = [
#         x[:, input_index_hmm]
#         for c, x in enumerate(input_shuffled)
#         if c < j*len(input_shuffled)/fold or c > (j+1)*len(input_shuffled)/fold]
#     y_this_train_hmm = [
#         x[:, :]
#         for c, x in enumerate(y_shuffled)
#         if c < j*len(input_shuffled)/fold or c > (j+1)*len(input_shuffled)/fold]

#     # get glm training and test set, for glm training, the data should not be parted, that concatenaed
#     input_this_test_glm = []
#     input_this_train_glm = []
#     y_this_test_glm = []
#     y_this_train_glm = []
#     for c, x in enumerate(input_shuffled):
#         if j*len(input_shuffled)/ fold <= c <= (j + 1)*len(input_shuffled)/ fold:
#             if len(input_this_test_glm) == 0:
#                 input_this_test_glm = x[:, input_index_glm]
#                 y_this_test_glm = y_shuffled[c]
#             else:
#                 input_this_test_glm = np.concatenate((
#                     input_this_test_glm, x[:, input_index_glm]))
#                 y_this_test_glm = np.concatenate((
#                     y_this_test_glm, y_shuffled[c]))
#         else:
#             if len(input_this_train_glm) == 0:
#                 input_this_train_glm = x[:, input_index_glm]
#                 y_this_train_glm = y_shuffled[c]
#             else:
#                 input_this_train_glm = np.concatenate((
#                     input_this_train_glm, x[:, input_index_glm]))
#                 y_this_train_glm = np.concatenate((
#                     y_this_train_glm, y_shuffled[c]))

#     # run GLM model training
#     best_param_glm, best_acc_glm = fit_glm_multiple_init(
#         input_this_train_glm, y_this_train_glm,
#         input_this_test_glm, y_this_test_glm,
#         M_GLM, C, n_init)
#     Param_GLM_5fold.append(best_param_glm)
#     Param_GLM_5fold.append(best_acc_glm)

#     # start GLM HMM training
#     now = datetime.now()
#     time_str = now.strftime("%Y-%m-%d-%H%M%S")
#     weights_glmhmm_example, acc_glmhmm_example = fit_glmhmm_multiple_init(
#         input_this_train_hmm, y_this_train_hmm,
#         input_this_test_hmm, y_this_test_hmm,
#         [np.ones([len(x), 1]) for x in y_this_train_hmm],
#         # this parameter provides a function to exclude some trials, if you want to use all trials,
#         # create a matrix of ones in the same shape as the y dataset
#         K_states, D, M_HMM, C, N_em_iters, transition_alpha,
#         prior_sigma, global_fit, best_param_glm,
#         'training_cache/glmhmm_' + time_str,
#         n_init, partition=True)
#     Param_HMM_5fold.append(weights_glmhmm_example)
#     Acc_HMM_5fold.append(acc_glmhmm_example)
# print(Acc_HMM_5fold)

# plt.plot(Acc_HMM_5fold)
# plt.savefig('accuracy_vs_fold.png')

print("--- %s seconds ---" % (time.time() - start_time))
                                