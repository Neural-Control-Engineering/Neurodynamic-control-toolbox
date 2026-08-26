"""
Extended Data Figure 6-1, refit on the CORRECTED column-routed GLM-HMM.

Why this exists
---------------
The April 2026 version (glmhmm_pupil_ne_cv.py) built a plain ssm.HMM with
`input_driven_obs` + `inputdriven` transitions and fed ONE shared input matrix
to both sub-models. Its own docstring says so: "Compares pupil-only vs
pupil+mPFC+S1 NE as transition+observation drivers." Three consequences:

  1. The "pupil-only" control arm carried baseline pupil in the OBSERVATION
     GLM -- i.e. the circular model the eNeuro reviewer objected to, and the
     one the revised Methods explicitly says we do not use.
  2. NE entered the observation GLM as well, so the comparison did not test
     "NE as an additional TRANSITION predictor", which is what the Results
     paragraph claims.
  3. Stimulus and bias were also driving the transitions in both arms, which
     no version of the Methods describes.

This refit routes columns explicitly, so both arms share an identical choice
GLM and differ ONLY in what drives the transitions -- which is the comparison
the paragraph actually claims:

    input matrix: [pupil, mPFC_NE, S1_NE, stim, bias]   (cols 0..4)

    arm "pupil"     obs=[3,4]  trans=[0]
    arm "pupil_ne"  obs=[3,4]  trans=[0,1,2]

Session-level 5-fold CV, same splitter/seed as cv_corrected_full.py so the
numbers sit on the same footing as Figure 6B/6C.

Writes: glmhmm_pupil_ne_cv_corrected.csv

Craig Kelley & Tim Lantin, NEC Lab
"""
import csv
import sys
import time

import os
_HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(_HERE, '..', '..', '..')) + os.sep
sys.path.insert(0, _HERE)
import numpy as np
import scipy.io as sio
from sklearn.model_selection import KFold
from sklearn.metrics import roc_auc_score, average_precision_score
import warnings
warnings.filterwarnings('ignore')
from glm_hmm_routed import build_routed_hmm

DATA = REPO + 'pupil_ne_transitions_data.mat'
OUT = REPO + 'glmhmm_pupil_ne_cv_corrected.csv'

# [pupil, mPFC_NE, S1_NE, stim, bias]
OBS = [3, 4]
ARMS = {'pupil': [0], 'pupil_ne': [0, 1, 2]}

C, D = 2, 1
N_EM, N_INIT = 200, 3

d = sio.loadmat(DATA)
ri, rl = d['preprocessed_input'], d['preprocessed_label']
n = ri.shape[0]
inputs = [ri[i, 0].astype(float) for i in range(n)]
labels = [np.array([rl[i, 0][j, 0].flat[0] for j in range(rl[i, 0].shape[0])],
                   dtype=int).reshape(-1, 1) for i in range(n)]
M = inputs[0].shape[1]
assert M == 5, f'expected 5 input columns, got {M}'
print(f'Data: {n} sessions, {sum(len(y) for y in labels)} trials, {M} input columns')
print(f'Go rate: {np.mean(np.concatenate(labels)):.3f}', flush=True)


def fit_eval(K, trans_cols, tr_in, tr_y, te_in, te_y):
    tr_m = [np.ones((x.shape[0], 1)) for x in tr_in]
    best_ll, best = -np.inf, None
    for init in range(N_INIT):
        np.random.seed(init)
        hmm = build_routed_hmm(K, D, M, C=C, prior_sigma=2,
                               obs_cols=OBS, trans_cols=trans_cols)
        lls = hmm.fit(tr_y, inputs=tr_in, masks=tr_m, method='em',
                      num_iters=N_EM, initialize=True, tolerance=1e-4, verbose=0)
        if lls[-1] > best_ll:
            best_ll, best = lls[-1], hmm

    tot_ll, n_tr = 0.0, 0
    all_p, all_y = [], []
    for inp, y in zip(te_in, te_y):
        m = np.ones((inp.shape[0], 1))
        tot_ll += best.log_likelihood([y], inputs=[inp], masks=[m])
        Ez, _, _ = best.expected_states(y, input=inp, mask=m)
        pgo = (Ez * np.exp(best.observations.calculate_logits(inp)[:, :, 1])).sum(1)
        all_p.append(pgo)
        all_y.append(y[:, 0])
        n_tr += len(y)
    p = np.concatenate(all_p)
    yv = np.concatenate(all_y)
    acc = float(((p > 0.5).astype(int) == yv).mean())
    if len(np.unique(yv)) < 2:
        roc, pr = float('nan'), float('nan')
    else:
        roc = float(roc_auc_score(yv, p))
        pr = float(average_precision_score(yv, p))
    bits = (tot_ll / n_tr) / np.log(2.0)
    return acc, roc, pr, bits


kf = KFold(n_splits=5, shuffle=True, random_state=42)
out = [('model', 'K', 'fold', 'accuracy', 'roc_auc', 'pr_auc', 'bits_per_trial')]
t0 = time.time()
for arm, trans_cols in ARMS.items():
    for K in (2, 3, 4):
        for f, (tr, te) in enumerate(kf.split(np.arange(n))):
            acc, roc, pr, bits = fit_eval(
                K, trans_cols,
                [inputs[i] for i in tr], [labels[i] for i in tr],
                [inputs[i] for i in te], [labels[i] for i in te])
            out.append((arm, K, f, round(acc, 5), round(roc, 5),
                        round(pr, 5), round(bits, 5)))
            print(f'{arm:9s} K={K} fold={f} acc={acc:.4f} roc={roc:.4f} '
                  f'pr={pr:.4f} bits={bits:.4f}', flush=True)
            with open(OUT, 'w', newline='') as fh:
                csv.writer(fh).writerows(out)

print(f'\nTotal wall time: {(time.time()-t0)/60:.1f} min')

import collections
agg = collections.defaultdict(list)
for r in out[1:]:
    agg[(r[0], r[1])].append(r[3:])
print('\n=== CV summary (mean over folds) ===')
print(f"{'model':10s}{'K':>3}{'acc':>9}{'roc_auc':>10}{'pr_auc':>9}{'bits':>10}")
for (arm, K), v in sorted(agg.items()):
    a = np.array(v, dtype=float)
    print(f'{arm:10s}{K:>3}{a[:,0].mean():>9.4f}{a[:,1].mean():>10.4f}'
          f'{a[:,2].mean():>9.4f}{a[:,3].mean():>10.4f}')
print('wrote', OUT)
