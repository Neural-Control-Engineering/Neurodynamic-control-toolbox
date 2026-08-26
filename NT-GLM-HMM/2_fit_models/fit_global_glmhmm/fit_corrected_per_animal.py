"""
Fit the corrected (column-routed) GLM-HMM at K=3 separately for each animal.

Pupil -> transitions only; stim+bias -> observations only.

The superseded glmhmm_K3_per_animal_params.json (deleted in 7fc7bb0) was fit
with glm_hmm_utils_v2.py, which fed [pupil, stim, bias] to BOTH sub-models --
its observation_weights therefore contained a pupil term, which is exactly the
circularity the eNeuro reviewer raised. This script replaces it.

Each animal is initialized from the global corrected fit so that state k means
the same thing across animals (EM is local, so states do not permute away from
that initialization -- verified post-hoc below and reported per animal).

Outputs (repo root):
    glmhmm_K3_per_animal_params_corrected.json

Craig Kelley & Tim Lantin, NEC Lab
"""
import sys, json
import os
_HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(_HERE, '..', '..', '..')) + os.sep
sys.path.insert(0, _HERE)
import numpy as np
import scipy.io as sio
import warnings; warnings.filterwarnings('ignore')
from glm_hmm_routed import build_routed_hmm

K, D, C, M = 3, 1, 2, 3
N_INITS = 8      # matches fit_corrected_global.py
N_EM = 250
N_EM_ANIMAL = 250

# ---- load ----
d = sio.loadmat(REPO + 'pupil_transitions_data.mat')
ri, rl, rs, rt = (d['preprocessed_input'], d['preprocessed_label'],
                  d['preprocessed_session'], d['preprocessed_trial_number'])
n = ri.shape[0]
inputs = [ri[i, 0] for i in range(n)]
labels = [np.array([rl[i, 0][j, 0].flat[0] for j in range(rl[i, 0].shape[0])],
                   dtype=int).reshape(-1, 1) for i in range(n)]
masks = [np.ones((x.shape[0], 1)) for x in inputs]


def _sess(i):
    s = rs[i, 0]
    return str(s[0]) if hasattr(s, '__len__') and len(s) else str(s)


sessions = [_sess(i) for i in range(n)]
animals = [s.split('-')[0] for s in sessions]
uniq_animals = sorted(set(animals))
print(f"{n} sessions, {sum(len(y) for y in labels)} trials, "
      f"{len(uniq_animals)} animals: {uniq_animals}")

# ---- global fit (same procedure as fit_corrected_global.py) ----
best = None
for it in range(N_INITS):
    np.random.seed(it)
    hmm = build_routed_hmm(K, D, M, C=C, prior_sigma=2)
    lls = hmm.fit(labels, inputs=inputs, masks=masks, method="em",
                  num_iters=N_EM, initialize=True, tolerance=1e-4, verbose=0)
    print(f"  global init {it}: LL={lls[-1]:.2f}")
    if best is None or lls[-1] > best[0]:
        best = (lls[-1], hmm)
global_ll, ghmm = best
print(f"GLOBAL BEST LL={global_ll:.2f}")

# canonical state labels from the global fit (same rule as the global script:
# Engaged = largest |stim|; Liberal vs Conservative by empirical response rate,
# because in this ssm fork a positive logit favours no-go so bias sign is not
# a safe cue)
gWobs = ghmm.observations.Wk[:, 0, :]
gstim = gWobs[:, 0]
resp_cnt = np.zeros(K); state_cnt = np.zeros(K)
for i in range(n):
    Ez, _, _ = ghmm.expected_states(labels[i], input=inputs[i], mask=masks[i])
    z = Ez.argmax(axis=1)
    for t in range(len(z)):
        state_cnt[z[t]] += 1
        resp_cnt[z[t]] += int(labels[i][t, 0] == 1)
g_resp = resp_cnt / np.maximum(state_cnt, 1)

engaged = int(np.argmax(np.abs(gstim)))
others = [k for k in range(K) if k != engaged]
liberal = int(others[int(np.argmax(g_resp[others]))])
conservative = int([k for k in others if k != liberal][0])
label_map = {engaged: "Engaged", liberal: "Liberal", conservative: "Conservative"}
print("global labels:", label_map, "| resp_rate:", np.round(g_resp, 3))

# snapshot global params for per-animal initialization
G = dict(
    Wk=np.array(ghmm.observations.Wk, copy=True),
    Ws=np.array(ghmm.transitions.Ws, copy=True),
    log_Ps=np.array(ghmm.transitions.log_Ps, copy=True),
    log_pi0=np.array(ghmm.init_state_distn.log_pi0, copy=True),
)

# ---- per-animal fits ----
out = {
    "description": ("Per-animal corrected GLM-HMM (K=3): baseline pupil drives "
                    "ONLY the transition softmax, stimulus+bias drive ONLY the "
                    "choice GLM. Initialized from the global corrected fit. "
                    "Replaces glmhmm_K3_per_animal_params.json, whose "
                    "observation weights contained a pupil term (circular)."),
    "config": {"K": K, "C": C, "M_full": M, "obs_inputs": ["stim", "bias"],
               "transition_inputs": ["pupil"], "N_em_iters": N_EM_ANIMAL,
               "prior_sigma": 2.0, "init": "global corrected fit",
               "global_log_likelihood": float(global_ll)},
    "state_labels": {f"state_{k}": label_map[k] for k in range(K)},
    "animals": {},
}

for a in uniq_animals:
    idx = [i for i in range(n) if animals[i] == a]
    a_inputs = [inputs[i] for i in idx]
    a_labels = [labels[i] for i in idx]
    a_masks = [masks[i] for i in idx]
    n_tr = sum(len(y) for y in a_labels)

    hmm = build_routed_hmm(K, D, M, C=C, prior_sigma=2)
    hmm.observations.Wk = np.array(G['Wk'], copy=True)
    hmm.transitions.Ws = np.array(G['Ws'], copy=True)
    hmm.transitions.log_Ps = np.array(G['log_Ps'], copy=True)
    hmm.init_state_distn.log_pi0 = np.array(G['log_pi0'], copy=True)

    lls = hmm.fit(a_labels, inputs=a_inputs, masks=a_masks, method="em",
                  num_iters=N_EM_ANIMAL, initialize=False, tolerance=1e-4,
                  verbose=0)

    Wobs = hmm.observations.Wk[:, 0, :]        # (K,2) stim,bias
    Wpup = hmm.transitions.Ws[:, 0]            # (K,) pupil -> transitions
    A = np.exp(hmm.transitions.log_Ps)
    A = A / A.sum(axis=1, keepdims=True)

    # post-hoc check that states did not permute away from the global init
    r_cnt = np.zeros(K); s_cnt = np.zeros(K)
    for j, i in enumerate(idx):
        Ez, _, _ = hmm.expected_states(a_labels[j], input=a_inputs[j],
                                       mask=a_masks[j])
        z = Ez.argmax(axis=1)
        for t in range(len(z)):
            s_cnt[z[t]] += 1
            r_cnt[z[t]] += int(a_labels[j][t, 0] == 1)
    a_resp = r_cnt / np.maximum(s_cnt, 1)
    a_engaged = int(np.argmax(np.abs(Wobs[:, 0])))
    aligned = bool(a_engaged == engaged)

    out["animals"][a] = {
        "n_sessions": len(idx), "n_trials": int(n_tr),
        "observation_weights": {
            f"state_{k}": {"stim": float(Wobs[k, 0]), "bias": float(Wobs[k, 1])}
            for k in range(K)},
        "transition_pupil_weight": {f"state_{k}": float(Wpup[k])
                                    for k in range(K)},
        "transition_matrix_at_u0": A.tolist(),
        "state_response_rate": {f"state_{k}": float(a_resp[k])
                                for k in range(K)},
        "state_trial_count": {f"state_{k}": int(s_cnt[k]) for k in range(K)},
        "log_likelihood": float(lls[-1]),
        "per_trial_log_likelihood": float(lls[-1] / n_tr),
        "n_em_iters": int(len(lls)),
        "states_aligned_with_global": aligned,
    }
    flag = "" if aligned else "   <-- STATE PERMUTED vs global init"
    print(f"  {a}: {len(idx)} sess {n_tr} tr  LL={lls[-1]:.2f} "
          f"({lls[-1]/n_tr:.4f}/trial)  {len(lls)} EM iters  "
          f"aligned={aligned}{flag}")
    print(f"       stim={np.round(Wobs[:,0],2)} bias={np.round(Wobs[:,1],2)} "
          f"pupil_trans={np.round(Wpup,3)}")

with open(REPO + 'glmhmm_K3_per_animal_params_corrected.json', 'w') as f:
    json.dump(out, f, indent=2)
print("wrote glmhmm_K3_per_animal_params_corrected.json")
