"""
5-fold cross-validated model comparison for the CORRECTED column-routed
GLM-HMM, emitting the SAME schema as the legacy glmhmm_cv_results.csv
(model, K, fold, accuracy, roc_auc, pr_auc, bits_per_trial).

Why: Fig6/fig6.m panels 6B (accuracy vs K) and 6C (ROC-AUC vs K) read
glmhmm_cv_results.csv, which holds the OLD pre-correction fits (model=='New',
pupil in the observation GLM). glmhmm_cv_corrected_results.csv could not
replace it because it only carries test_ll_per_trial and test_acc. This script
produces the missing ROC-AUC / PR-AUC for the corrected model so 6B/6C can be
regenerated from it.

Writes: glmhmm_cv_corrected_full.csv

Craig Kelley & Tim Lantin, NEC Lab
"""
import sys
sys.path.insert(0, '/Users/sleeper/Projects/Neurodynamic-control-toolbox/NT-GLM-HMM/2_fit_models/fit_global_glmhmm')
import numpy as np, scipy.io as sio, ssm, csv
from sklearn.model_selection import KFold
from sklearn.metrics import roc_auc_score, average_precision_score
import warnings; warnings.filterwarnings('ignore')
from glm_hmm_routed import build_routed_hmm

REPO = '/Users/sleeper/Projects/Neurodynamic-control-toolbox/'
d = sio.loadmat(REPO + 'pupil_transitions_data.mat')
ri, rl = d['preprocessed_input'], d['preprocessed_label']
n = ri.shape[0]
inputs = [ri[i, 0] for i in range(n)]
labels = [np.array([rl[i, 0][j, 0].flat[0] for j in range(rl[i, 0].shape[0])],
                   dtype=int).reshape(-1, 1) for i in range(n)]
C, D = 2, 1
N_EM, N_INIT = 200, 3


def fit_eval(K, kind, tr_in, tr_y, te_in, te_y):
    tr_m = [np.ones((x.shape[0], 1)) for x in tr_in]
    M = tr_in[0].shape[1]
    best_ll, best = -np.inf, None
    for init in range(N_INIT):
        np.random.seed(init)
        if kind == "corrected":
            hmm = build_routed_hmm(K, D, M, C=C, prior_sigma=2)
        else:  # pupil-in-obs: full input to both
            hmm = ssm.HMM(K, D, M, observations="input_driven_obs",
                          observation_kwargs=dict(C=C, prior_sigma=2),
                          transitions="inputdriven",
                          transition_kwargs=dict(alpha=1, kappa=0))
        lls = hmm.fit(tr_y, inputs=tr_in, masks=tr_m, method="em",
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
    # both classes must be present for AUC to be defined
    if len(np.unique(yv)) < 2:
        roc, pr = float('nan'), float('nan')
    else:
        roc = float(roc_auc_score(yv, p))
        pr = float(average_precision_score(yv, p))
    bits = (tot_ll / n_tr) / np.log(2.0)
    return acc, roc, pr, bits


kf = KFold(n_splits=5, shuffle=True, random_state=42)
out = [("model", "K", "fold", "accuracy", "roc_auc", "pr_auc", "bits_per_trial")]
configs = [("corrected", k) for k in (1, 2, 3, 4)] + [("pupil_in_obs", 3)]
for kind, K in configs:
    for f, (tr, te) in enumerate(kf.split(np.arange(n))):
        acc, roc, pr, bits = fit_eval(
            K, kind, [inputs[i] for i in tr], [labels[i] for i in tr],
            [inputs[i] for i in te], [labels[i] for i in te])
        out.append((kind, K, f, round(acc, 5), round(roc, 5), round(pr, 5), round(bits, 5)))
        print(f"{kind:14s} K={K} fold={f} acc={acc:.4f} roc={roc:.4f} "
              f"pr={pr:.4f} bits={bits:.4f}", flush=True)

with open(REPO + 'glmhmm_cv_corrected_full.csv', 'w', newline='') as fh:
    csv.writer(fh).writerows(out)

import collections
agg = collections.defaultdict(list)
for r in out[1:]:
    agg[(r[0], r[1])].append(r[3:])
print("\n=== CV summary (mean over folds) ===")
print(f"{'model':14s}{'K':>3}{'acc':>9}{'roc_auc':>10}{'pr_auc':>9}{'bits':>10}")
for (kind, K), v in agg.items():
    a = np.array(v, dtype=float)
    print(f"{kind:14s}{K:>3}{a[:,0].mean():>9.4f}{a[:,1].mean():>10.4f}"
          f"{a[:,2].mean():>9.4f}{a[:,3].mean():>10.4f}")
print("wrote glmhmm_cv_corrected_full.csv")
