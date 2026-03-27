# Pupil-Driven Transitions GLM-HMM

Addresses eNeuro reviewer comment requesting a model similar to
Hulsey et al. (2024), where state dynamics are linked to baseline
pupil-linked arousal.

## The Problem (Circularity)

**Original model:**
- Baseline pupil + stimulus → choice (within each state)
- States transition via fixed/sticky matrix
- Then we analyze pupil dynamics *within* states that pupil helped define
- **Circular:** pupil defines states → pupil analyzed within those states

**Reviewer's requested model:**
- Baseline pupil → state transitions (which behavioral mode)
- Stimulus → choice (within each state)
- **Not circular:** pupil determines state, then task-evoked responses analyzed within states

## Architecture

```
                    ┌─────────────────┐
  baseline pupil ──>│  Transitions    │──> State at time t
                    │  (inputdriven)  │
                    └─────────────────┘
                            │
                            v
                    ┌─────────────────┐
  stimulus + bias ──>│  Observations  │──> Choice (go/no-go)
                    │  (input_driven) │
                    └─────────────────┘
```

## Go/No-Go Compatibility

Hulsey et al. used a non-forced 2AFC task (3 categories: left, right, miss).
Our task is go/no-go (2 categories: respond, withhold).

The SSM framework handles this via the `C` parameter:
- Hulsey: `C=3`
- Ours: `C=2`

No structural changes needed — the GLM-HMM architecture is task-agnostic.

## Files Modified

### `genHmmGlmData.m`
Two new preprocessing versions:

**`'pupil_driven_transitions'`** (recommended):
```
Column 0: baseline pupil (z-scored)  → transitions
Column 1: stimulus strength           → observations
Column 2: ones (bias)                 → observations
```

**`'pupil_ne_driven_transitions'`** (extended):
```
Column 0: baseline pupil (z-scored)   → transitions
Column 1: baseline mPFC NE (z-scored) → transitions
Column 2: baseline S1 NE (z-scored)   → transitions
Column 3: stimulus strength            → observations
Column 4: ones (bias)                  → observations
```

### `NT-GLM-HMM/2_fit_models/fit_global_glmhmm/glm_hmm_utils_v2.py`
New fitting utilities with `use_input_driven_transitions` parameter.

## Usage

### Step 1: Preprocess data (MATLAB)
```matlab
load('your_datastore.mat', 'data');

% Pupil-only transitions
genHmmGlmData(data, 'pupil_transitions_data.mat', 'pupil_driven_transitions', false);

% Or pupil + NE transitions
genHmmGlmData(data, 'pupil_ne_transitions_data.mat', 'pupil_ne_driven_transitions', false);
```

### Step 2: Fit model (Python)
```python
from glm_hmm_utils_v2 import launch_glm_hmm_job

# Pupil-driven transitions (M_transition=1 for pupil only)
launch_glm_hmm_job(inpt, y, session, mask, session_fold_lookup,
                   K, D, C, N_em_iters, transition_alpha, prior_sigma,
                   fold, iter, global_fit, init_param_file, save_dir,
                   M_transition=1,
                   use_input_driven_transitions=True)

# For pupil + NE transitions (M_transition=3)
launch_glm_hmm_job(..., M_transition=3, use_input_driven_transitions=True)

# Original model (for comparison)
launch_glm_hmm_job(..., use_input_driven_transitions=False)
```

### Step 3: Verify
After fitting, check that:
1. Transition weights correlate with pupil (high pupil → engaged state)
2. Observation weights show stimulus driving choice within states
3. States are interpretable as arousal-linked behavioral modes

## How InputDrivenTransitions Works

From SSM's `transitions.py`:
```python
class InputDrivenTransitions(StickyTransitions):
    # log_Ps = log_Ps + input @ Ws.T
    # Ws shape: (K, M_transition)
```

The transition probability at time t depends on:
- Base transition matrix (learned)
- Plus input-dependent modulation: `pupil[t] * Ws`

High pupil → bias toward engaged state transitions.
Low pupil → bias toward disengaged/lapse state transitions.

## References
- Hulsey et al. (2024) - Pupil-linked arousal drives behavioral states
- Ashwood et al. (2022) - GLM-HMM framework
- Linderman Lab SSM package v0.0.1
