"""
Quick predictive accuracy check for pupil-driven transitions GLM-HMM.
5-fold CV over sessions. Compares:
  1. Bias-only baseline (predict majority class)
  2. GLM (no hidden states, K=1)
  3. Sticky GLM-HMM (original, K=2,3)
  4. Input-driven transitions GLM-HMM (reviewer model, K=2,3)
"""
import sys
sys.path.insert(0, '/Users/sleeper/Projects/Neurodynamic-control-toolbox/NT-GLM-HMM/2_fit_models/fit_global_glmhmm')

import numpy as np
import scipy.io as sio
import ssm
from sklearn.model_selection import KFold
import warnings
warnings.filterwarnings('ignore')

# ── Load data ──
d = sio.loadmat('/Users/sleeper/Projects/Neurodynamic-control-toolbox/pupil_transitions_data.mat')
raw_inputs = d['preprocessed_input']
raw_labels = d['preprocessed_label']

n_sessions = raw_inputs.shape[0]

# Parse into lists of arrays
inputs_list = []
labels_list = []
for i in range(n_sessions):
    inp = raw_inputs[i, 0]  # (n_trials, 3): [pupil, stim, bias]
    lab = raw_labels[i, 0]
    # Unwrap nested cell labels
    y = np.array([lab[j, 0].flat[0] for j in range(lab.shape[0])], dtype=int)
    inputs_list.append(inp)
    labels_list.append(y.reshape(-1, 1))

print(f"Data: {n_sessions} sessions, {sum(len(y) for y in labels_list)} trials")
print(f"Go rate: {np.mean(np.concatenate(labels_list)):.3f}")
print()

# ── Cross-validation ──
kf = KFold(n_splits=5, shuffle=True, random_state=42)
session_indices = np.arange(n_sessions)

N_EM = 200
C = 2  # go/no-go
D = 1
results = {}

models_to_test = [
    ("Bias only",          None, None),
    ("GLM (K=1)",          1, "sticky"),
    ("Sticky K=2",         2, "sticky"),
    ("Sticky K=3",         3, "sticky"),
    ("InputDriven K=2",    2, "inputdriven"),
    ("InputDriven K=3",    3, "inputdriven"),
]

for model_name, K, trans_type in models_to_test:
    fold_accs = []
    fold_lls = []
    
    for fold_idx, (train_idx, test_idx) in enumerate(kf.split(session_indices)):
        train_inputs = [inputs_list[i] for i in train_idx]
        train_labels = [labels_list[i] for i in train_idx]
        test_inputs = [inputs_list[i] for i in test_idx]
        test_labels = [labels_list[i] for i in test_idx]
        
        if K is None:
            # Bias only: predict training go-rate
            go_rate = np.mean(np.concatenate(train_labels))
            pred = 1 if go_rate > 0.5 else 0
            acc = np.mean(np.concatenate(test_labels) == pred)
            fold_accs.append(acc)
            fold_lls.append(np.nan)
            continue
        
        M = train_inputs[0].shape[1]  # 3
        
        # Build masks (all valid)
        train_masks = [np.ones((inp.shape[0], 1)) for inp in train_inputs]
        test_masks = [np.ones((inp.shape[0], 1)) for inp in test_inputs]
        
        if trans_type == "inputdriven":
            trans_kwargs = dict(alpha=1, kappa=0)
        else:
            trans_kwargs = dict(alpha=1, kappa=0)
        
        best_ll = -np.inf
        best_hmm = None
        
        # Run 3 random initializations, keep best
        for init in range(3):
            np.random.seed(fold_idx * 100 + init)
            try:
                hmm = ssm.HMM(K, D, M,
                              observations="input_driven_obs",
                              observation_kwargs=dict(C=C, prior_sigma=2),
                              transitions=trans_type,
                              transition_kwargs=trans_kwargs)
                
                lls = hmm.fit(train_labels, inputs=train_inputs,
                             masks=train_masks, method="em",
                             num_iters=N_EM, initialize=True, tolerance=1e-4)
                
                if lls[-1] > best_ll:
                    best_ll = lls[-1]
                    best_hmm = hmm
            except Exception as e:
                print(f"  [{model_name}] fold {fold_idx} init {init} failed: {e}")
                continue
        
        if best_hmm is None:
            fold_accs.append(np.nan)
            fold_lls.append(np.nan)
            continue
        
        # Predict on test set
        correct = 0
        total = 0
        test_ll = 0
        for inp, lab in zip(test_inputs, test_labels):
            # Get most likely states
            states = best_hmm.most_likely_states(lab, input=inp)
            # Get observation log likelihoods for each choice
            log_likes = best_hmm.observations.log_likelihoods(lab, inp, mask=np.ones((len(lab), 1)), tag=None)
            test_ll += np.sum(log_likes[np.arange(len(states)), states])
            
            # Predict: for each trial, which choice is more likely given state & input?
            obs_params = best_hmm.observations.params  # (K, D, M, C-1) or similar
            for t in range(len(lab)):
                k = states[t]
                # GLM prediction: P(y=1|x,state=k)
                w = best_hmm.observations.params[k]  # weights for state k
                logits = inp[t] @ w.T  # (C-1,) for C=2 this is (1,)
                p_go = 1 / (1 + np.exp(-logits.flat[0]))
                pred = 1 if p_go > 0.5 else 0
                correct += (pred == lab[t, 0])
                total += 1
        
        fold_accs.append(correct / total)
        fold_lls.append(test_ll)
    
    mean_acc = np.nanmean(fold_accs)
    std_acc = np.nanstd(fold_accs)
    results[model_name] = (mean_acc, std_acc, fold_accs)
    print(f"{model_name:25s}  acc = {mean_acc:.3f} ± {std_acc:.3f}  folds: {[f'{a:.3f}' for a in fold_accs]}")

print("\n=== Summary ===")
for name, (m, s, _) in sorted(results.items(), key=lambda x: -x[1][0]):
    print(f"  {name:25s}  {m:.3f} ± {s:.3f}")
