"""
5-fold cross-validated model comparison for the CORRECTED column-routed
GLM-HMM. Two purposes:
  (1) Confirm K=3 is the optimal number of states (test log-likelihood / acc).
  (2) Show that routing pupil OUT of the observation GLM (corrected model)
      does not cost predictive performance vs the model that keeps pupil in
      the observations ("pupil-in-obs"), i.e. removing the circularity is free.
Writes: glmhmm_cv_corrected_results.csv
"""
import sys
import os
_HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(_HERE, '..', '..', '..')) + os.sep
sys.path.insert(0, _HERE)
import numpy as np, scipy.io as sio, ssm, csv
from sklearn.model_selection import KFold
import warnings; warnings.filterwarnings('ignore')
from glm_hmm_routed import build_routed_hmm

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
            init_flag = True
        else:  # pupil-in-obs: full input to both, inputdriven transitions
            hmm = ssm.HMM(K, D, M, observations="input_driven_obs",
                          observation_kwargs=dict(C=C, prior_sigma=2),
                          transitions="inputdriven",
                          transition_kwargs=dict(alpha=1, kappa=0))
            init_flag = True
        lls = hmm.fit(tr_y, inputs=tr_in, masks=tr_m, method="em",
                      num_iters=N_EM, initialize=init_flag, tolerance=1e-4, verbose=0)
        if lls[-1] > best_ll:
            best_ll, best = lls[-1], hmm
    # test log-likelihood (total) and per-trial accuracy
    tot_ll, n_tr, correct = 0.0, 0, 0
    for inp, y in zip(te_in, te_y):
        m = np.ones((inp.shape[0], 1))
        tot_ll += best.log_likelihood([y], inputs=[inp], masks=[m])
        Ez, _, _ = best.expected_states(y, input=inp, mask=m)
        pgo = (Ez * np.exp(best.observations.calculate_logits(inp)[:, :, 1])).sum(1)
        correct += int(((pgo > 0.5).astype(int) == y[:, 0]).sum())
        n_tr += len(y)
    return tot_ll / n_tr, correct / n_tr   # bits/trial (nat), accuracy


kf = KFold(n_splits=5, shuffle=True, random_state=42)
out = [("model", "K", "fold", "test_ll_per_trial", "test_acc")]
configs = [("corrected", k) for k in (1, 2, 3, 4)] + [("pupil_in_obs", 3)]
for kind, K in configs:
    for f, (tr, te) in enumerate(kf.split(np.arange(n))):
        ll, acc = fit_eval(K, kind, [inputs[i] for i in tr], [labels[i] for i in tr],
                           [inputs[i] for i in te], [labels[i] for i in te])
        out.append((kind, K, f, round(ll, 5), round(acc, 5)))
        print(f"{kind:14s} K={K} fold={f} ll/trial={ll:.4f} acc={acc:.4f}", flush=True)

with open(REPO + 'glmhmm_cv_corrected_results.csv', 'w', newline='') as fh:
    csv.writer(fh).writerows(out)

# summary
import collections
agg = collections.defaultdict(list)
for r in out[1:]:
    agg[(r[0], r[1])].append((r[3], r[4]))
print("\n=== CV summary (mean over folds) ===")
print(f"{'model':14s}{'K':>3}{'ll/trial':>11}{'acc':>9}")
for (kind, K), v in agg.items():
    lls = [x[0] for x in v]; accs = [x[1] for x in v]
    print(f"{kind:14s}{K:>3}{np.mean(lls):>11.4f}{np.mean(accs):>9.4f}")
print("wrote glmhmm_cv_corrected_results.csv")
