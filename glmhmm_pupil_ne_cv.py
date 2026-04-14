"""
5-fold CV for pupil+NE GLM-HMM on matched 49-session subset.
Compares pupil-only vs pupil+mPFC+S1 NE as transition+observation drivers.

Schema matches glmhmm_cv_results.csv: model, K, fold, accuracy, roc_auc, pr_auc, bits_per_trial
Output: glmhmm_pupil_ne_cv_results.csv
"""
import sys
import time
sys.path.insert(0, '/Users/sleeper/Projects/Neurodynamic-control-toolbox/NT-GLM-HMM/2_fit_models/fit_global_glmhmm')

import numpy as np
import pandas as pd
import scipy.io as sio
import ssm
from sklearn.model_selection import KFold
from sklearn.metrics import roc_auc_score, average_precision_score
import warnings
warnings.filterwarnings('ignore')

DATA = '/Users/sleeper/Projects/Neurodynamic-control-toolbox/pupil_ne_transitions_data.mat'
OUT = '/Users/sleeper/Projects/Neurodynamic-control-toolbox/glmhmm_pupil_ne_cv_results.csv'

N_EM = 200
N_INIT = 2
C = 2
D = 1
TOL = 1e-4

d = sio.loadmat(DATA)
raw_inputs = d['preprocessed_input']
raw_labels = d['preprocessed_label']
n_sessions = raw_inputs.shape[0]

inputs_full = []
labels = []
for i in range(n_sessions):
    inp = raw_inputs[i, 0]  # (T, 5): pupil, mPFC_NE, S1_NE, stim, bias
    lab = raw_labels[i, 0]
    y = np.array([lab[j, 0].flat[0] for j in range(lab.shape[0])], dtype=int)
    inputs_full.append(inp.astype(float))
    labels.append(y.reshape(-1, 1))

print(f"Data: {n_sessions} sessions, {sum(len(y) for y in labels)} trials")
print(f"Go rate: {np.mean(np.concatenate(labels)):.3f}", flush=True)


def subset_cols(inputs_list, cols):
    return [inp[:, cols] for inp in inputs_list]


def fit_with_restarts(train_y, train_inp, K, M, trans_type, seed_base):
    best_ll = -np.inf
    best_hmm = None
    masks = [np.ones((inp.shape[0], 1)) for inp in train_inp]
    if trans_type == "standard":
        trans_kwargs = {}
    else:
        trans_kwargs = dict(alpha=1, kappa=0)
    for init in range(N_INIT):
        np.random.seed(seed_base + init)
        try:
            hmm = ssm.HMM(
                K, D, M,
                observations="input_driven_obs",
                observation_kwargs=dict(C=C, prior_sigma=2),
                transitions=trans_type,
                transition_kwargs=trans_kwargs,
            )
            lls = hmm.fit(train_y, inputs=train_inp, masks=masks,
                          method="em", num_iters=N_EM, initialize=True, tolerance=TOL)
            if lls[-1] > best_ll:
                best_ll = lls[-1]
                best_hmm = hmm
        except Exception as e:
            print(f"    init {init} failed: {e}", flush=True)
            continue
    return best_hmm


def eval_on_test(hmm, test_y, test_inp, K):
    all_y, all_p = [], []
    test_ll_nats = 0.0
    for inp, lab in zip(test_inp, test_y):
        T = inp.shape[0]
        mask = np.ones((T, 1))
        if K == 1:
            Ez = np.ones((T, 1))
        else:
            Ez, _, ll_sess = hmm.expected_states(lab, inp, mask=mask, tag=None)
        ll_sess = hmm.log_likelihood([lab], inputs=[inp], masks=[mask])
        test_ll_nats += ll_sess
        # GLM per-state prediction: squeeze params to (K, M)
        w = np.asarray(hmm.observations.params).squeeze()
        if w.ndim == 1:
            # K=1 case — single state, shape collapsed
            w = w.reshape(1, -1)
        # For K>=2, should be (K, M); for C=2 sometimes (K, 1, M)
        if w.ndim == 3:
            w = w.reshape(K, -1)
        logits = inp @ w.T  # (T, K)  SSM convention: P(y=0|x) = sigmoid(logits)
        p_go_per_state = 1.0 / (1.0 + np.exp(logits))  # P(y=1|x) = sigmoid(-logits)
        p_go = np.sum(Ez * p_go_per_state, axis=1)  # (T,)
        all_y.append(lab.flatten())
        all_p.append(p_go)
    y = np.concatenate(all_y)
    p = np.concatenate(all_p)
    acc = float(np.mean((p > 0.5).astype(int) == y))
    if len(np.unique(y)) > 1:
        roc = float(roc_auc_score(y, p))
        pr = float(average_precision_score(y, p))
    else:
        roc = np.nan
        pr = np.nan
    bits = float(test_ll_nats / len(y) / np.log(2))
    return acc, roc, pr, bits


configs = [
    # (model_name, K, cols_to_use, trans_type)
    ("Pupil",    1, [0, 3, 4],         "standard"),
    ("Pupil",    2, [0, 3, 4],         "inputdriven"),
    ("Pupil",    3, [0, 3, 4],         "inputdriven"),
    ("Pupil",    4, [0, 3, 4],         "inputdriven"),
    ("Pupil+NE", 2, [0, 1, 2, 3, 4],   "inputdriven"),
    ("Pupil+NE", 3, [0, 1, 2, 3, 4],   "inputdriven"),
    ("Pupil+NE", 4, [0, 1, 2, 3, 4],   "inputdriven"),
]

kf = KFold(n_splits=5, shuffle=True, random_state=42)
session_idx = np.arange(n_sessions)

rows = []
t0_all = time.time()
for (name, K, cols, trans_type) in configs:
    inputs = subset_cols(inputs_full, cols)
    M = len(cols)
    for fold_idx, (train_i, test_i) in enumerate(kf.split(session_idx)):
        t0 = time.time()
        train_y = [labels[i] for i in train_i]
        test_y = [labels[i] for i in test_i]
        train_inp = [inputs[i] for i in train_i]
        test_inp = [inputs[i] for i in test_i]
        seed_base = 1000 * (K + 1) + fold_idx * 17 + (0 if name == "Pupil" else 1)
        hmm = fit_with_restarts(train_y, train_inp, K, M, trans_type, seed_base)
        if hmm is None:
            print(f"{name} K={K} fold={fold_idx+1}  FAILED", flush=True)
            continue
        acc, roc, pr, bits = eval_on_test(hmm, test_y, test_inp, K)
        rows.append(dict(model=name, K=K, fold=fold_idx + 1,
                         accuracy=round(acc, 3),
                         roc_auc=round(roc, 3),
                         pr_auc=round(pr, 3),
                         bits_per_trial=round(bits, 3)))
        dt = time.time() - t0
        print(f"{name} K={K} fold={fold_idx+1}  acc={acc:.3f} roc={roc:.3f} "
              f"pr={pr:.3f} bits={bits:.3f}  ({dt:.1f}s)", flush=True)
        # Save incrementally
        pd.DataFrame(rows).to_csv(OUT, index=False)

print(f"\nTotal wall time: {(time.time()-t0_all)/60:.1f} min")
print(f"Saved: {OUT}")
