"""
Fit the corrected (column-routed) global GLM-HMM at K=3 and regenerate
the params JSON + per-trial state assignments CSV.

Pupil -> transitions only; stim+bias -> observations only.
Outputs (written to repo root):
    glmhmm_K3_params_corrected.json
    glmhmm_K3_state_assignments_corrected.csv
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
N_INITS = 8
N_EM = 250

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
trialnums = [np.asarray(rt[i, 0]).ravel() for i in range(n)]
print(f"{n} sessions, {sum(len(y) for y in labels)} trials")

# ---- fit K=3, keep best of N_INITS ----
best = None
for it in range(N_INITS):
    np.random.seed(it)
    hmm = build_routed_hmm(K, D, M, C=C, prior_sigma=2)
    lls = hmm.fit(labels, inputs=inputs, masks=masks, method="em",
                  num_iters=N_EM, initialize=True, tolerance=1e-4, verbose=0)
    print(f"  init {it}: LL={lls[-1]:.2f}")
    if best is None or lls[-1] > best[0]:
        best = (lls[-1], hmm)
best_ll, hmm = best
print(f"BEST LL={best_ll:.2f}")

# ---- canonical labels ----
# obs weights per state: [stim, bias]; |stim| = perceptual sensitivity.
# NOTE: this ssm fork uses the convention positive logit -> P(no-go), so the
# bias SIGN is not a safe label cue. Label Liberal vs Conservative from the
# empirical within-state response rate instead (convention-independent).
Wobs = hmm.observations.Wk[:, 0, :]      # (K,2) stim,bias
Wpup = hmm.transitions.Ws[:, 0]          # (K,) pupil->transition
stim_w, bias_w = Wobs[:, 0], Wobs[:, 1]

# hard state per trial + empirical response (go) rate per state
resp_cnt = np.zeros(K); state_cnt = np.zeros(K)
hard_states = []
for i in range(n):
    Ez, _, _ = hmm.expected_states(labels[i], input=inputs[i], mask=masks[i])
    z = Ez.argmax(axis=1); hard_states.append(z)
    for t in range(len(z)):
        state_cnt[z[t]] += 1
        resp_cnt[z[t]] += int(labels[i][t, 0] == 1)
resp_rate = resp_cnt / np.maximum(state_cnt, 1)

engaged = int(np.argmax(np.abs(stim_w)))            # most sensitive
others = [k for k in range(K) if k != engaged]
liberal = int(others[int(np.argmax(resp_rate[others]))])      # responds most
conservative = int([k for k in others if k != liberal][0])    # withholds most
label_map = {engaged: "Engaged", liberal: "Liberal", conservative: "Conservative"}
print("labels:", label_map, "| resp_rate:", np.round(resp_rate, 3))

# ---- params JSON ----
A = np.exp(hmm.transitions.log_Ps)
A = A / A.sum(axis=1, keepdims=True)
params = {
    "model": "corrected_routed (pupil->transitions only; stim+bias->observations)",
    "K": K, "log_likelihood": float(best_ll),
    "states": {}
}
for k in range(K):
    params["states"][f"state_{k}"] = {
        "label": label_map[k],
        "obs_stim_weight": float(stim_w[k]),
        "obs_bias_weight": float(bias_w[k]),
        "transition_pupil_weight": float(Wpup[k]),
    }
params["baseline_transition_matrix"] = A.tolist()
params["init_state_probs"] = hmm.init_state_distn.initial_state_distn.tolist()
with open(REPO + 'glmhmm_K3_params_corrected.json', 'w') as f:
    json.dump(params, f, indent=2)
print("wrote glmhmm_K3_params_corrected.json")

# ---- per-trial state assignments ----
rows = ["model,session,trial_number,state,state_label,p_state0,p_state1,p_state2,p_go,actual_choice,pupil_zscore,stim_strength"]
for i in range(n):
    inp, y = inputs[i], labels[i]
    Ez, _, _ = hmm.expected_states(y, input=inp, mask=masks[i])
    logits = hmm.observations.calculate_logits(inp)         # (T,K,C)
    pgo_k = np.exp(logits[:, :, 1])                          # P(go|state k)
    pgo = (Ez * pgo_k).sum(axis=1)
    state = Ez.argmax(axis=1)
    for t in range(inp.shape[0]):
        rows.append(",".join(map(str, [
            "corrected", sessions[i], int(trialnums[i][t]) if t < len(trialnums[i]) else t+1,
            int(state[t]), label_map[int(state[t])],
            f"{Ez[t,0]:.6g}", f"{Ez[t,1]:.6g}", f"{Ez[t,2]:.6g}",
            f"{pgo[t]:.6g}", int(y[t,0]),
            f"{inp[t,0]:.6g}", f"{inp[t,1]:.6g}"])))
with open(REPO + 'glmhmm_K3_state_assignments_corrected.csv', 'w') as f:
    f.write("\n".join(rows) + "\n")
print(f"wrote glmhmm_K3_state_assignments_corrected.csv ({len(rows)-1} trials)")
