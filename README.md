# Neurotransmitter_Exploration

This repository is a collection of code used to analyze pupillometry, fiber photometry recordings of GRABNE, and behavior 
in mice performing a simple tactile signal detection task.  Required data is available on upon request.  To generate all 
figures and analyses from our paper, simply unzip the data and run *allFigures.m*.  Code for running the GLM-HMM model 
are found in *NT-GLM-HMM/* and subfolders.  Specifically, a global model can be trained by running
*NT-GLM-HMM/2_fit_models/fit_global_glmhmm/fit_corrected_global.py*, and models for individual animals
can be trained by running *NT-GLM-HMM/2_fit_models/fit_global_glmhmm/fit_corrected_per_animal.py*.
The section below walks through the full procedure.

## Running the GLM-HMM

The GLM-HMM is fit in Python and its outputs are consumed by MATLAB.  The fit
products are committed at the repository root, so `allFigures.m` regenerates
Figure 6 without refitting; Extended Data Figure 6-1 is drawn by a Python script
(Step 3) from a committed CSV.  Refit only if the underlying data change.

### The model

Baseline pupil drives the **transitions** only; stimulus strength and bias drive
the **observations** (choice) only:

    P(z_t = k | z_{t-1} = j, p_t) = softmax_k( A_jk + v_k * p_t )

Routing the inputs this way is what removes the circularity — pupil defines the
states, so it must not also sit in the choice GLM whose within-state responses
we then analyze.  The routing is implemented in
`NT-GLM-HMM/2_fit_models/fit_global_glmhmm/glm_hmm_routed.py`, which subclasses
`InputDrivenObservations` and `InputDrivenTransitions` so each sub-model slices
its own columns out of the shared input matrix.  See
`NT-GLM-HMM/REVIEWER_MODEL_README.md` for the longer rationale behind the
routing (its *Usage* section describes the superseded `glm_hmm_utils_v2.py`
API; use the scripts below instead).

`glm_hmm_utils_v2.py` is the earlier attempt at this and is **superseded**: its
`M_transition` argument never sliced anything, so pupil entered both sub-models.
Anything in the repository named `*_corrected*` is the routed fit and is what the
paper reports.

### Environment

    conda env create -f NT-GLM-HMM/environment.yml
    conda activate glmhmm

Then install version 0.0.1 of the Linderman lab `ssm` package from
[Ashwood's fork](https://github.com/zashwood/ssm) (`pip install numpy cython`,
then `pip install -e .` from the `ssm` directory).  The cross-validation and
plotting scripts additionally need `scikit-learn`, `pandas`, and `matplotlib`.

The fitting and cross-validation scripts each set a `REPO` constant at the top
to an absolute path -- currently the path on the machine they were run on, so
**point it at your own checkout before running**.  The plotting script uses
relative paths instead and must be run from the repository root.

### Step 1 — build the design matrices (MATLAB)

    Datastore = load('Combined-Datastore_created_14-Jan-2024.mat');
    data = filterTrials(Datastore.Datastore, 'recording_location', 'mPFC-S1');
    data(cellfun(@isempty, data.photometry_ch1),:) = [];

    % Figure 6: pupil -> transitions, stim + bias -> observations
    genHmmGlmData(data, 'pupil_transitions_data.mat', 'pupil_driven_transitions', false);

    % Extended Data 6-1: adds baseline mPFC and S1 NE as transition inputs
    genHmmGlmData(data, 'pupil_ne_transitions_data.mat', 'pupil_ne_driven_transitions', false);

Column layouts (`preprocessed_input`, one cell per session):

| version | transition columns | observation columns |
| --- | --- | --- |
| `pupil_driven_transitions` | 0 = baseline pupil (z-scored within session) | 1 = stim strength, 2 = bias |
| `pupil_ne_driven_transitions` | 0 = pupil, 1 = mPFC NE, 2 = S1 NE (all z-scored) | 3 = stim strength, 4 = bias |

Both `.mat` files are committed, so Step 1 can be skipped unless the data
change.  Pass `true` for the fourth argument to build a within-session shuffled
control.

### Step 2 — fit (Python)

Run from `NT-GLM-HMM/2_fit_models/fit_global_glmhmm/`:

| script | what it does | writes (repo root) |
| --- | --- | --- |
| `fit_corrected_global.py` | K=3 global fit, best of 8 EM restarts | `glmhmm_K3_params_corrected.json`, `glmhmm_K3_state_assignments_corrected.csv` |
| `fit_corrected_per_animal.py` | K=3 per animal, each initialized from the global fit so state *k* means the same thing across animals | `glmhmm_K3_per_animal_params_corrected.json` |
| `cv_corrected_full.py` | session-level 5-fold CV: routed model at K = 1–4, plus a single pupil-in-observations arm at K = 3 for comparison; accuracy, ROC-AUC, PR-AUC, bits/trial | `glmhmm_cv_corrected_full.csv` |
| `cv_pupil_ne_corrected.py` | same splitter and seed, K = 2–4, pupil vs pupil+NE as transition drivers (identical choice GLM in both arms) | `glmhmm_pupil_ne_cv_corrected.csv` |

Run the global fit first — the per-animal script initializes from it.  The two
CV sweeps are the slow steps (3 EM restarts x 200 iterations, for every fold x K
x arm).  Restarts are seeded `np.random.seed(0..N-1)`, so results are
reproducible given the same `.mat` and the same `ssm` build.

`cv_corrected.py` is a reduced version of `cv_corrected_full.py` that emits only
test log-likelihood and accuracy; `cv_corrected_full.py` supersedes it and is
what Figure 6B/6C read.

### Step 3 — figures

Figure 6 is MATLAB.  `Fig6/fig6.m` reads `glmhmm_K3_state_assignments_corrected.csv`
(per-trial state, posterior over states, P(go), pupil, stimulus),
`glmhmm_K3_per_animal_params_corrected.json` (per-animal GLM weights and the
`state_labels` map — Liberal / Conservative / Engaged), and
`glmhmm_cv_corrected_full.csv` (panels 6B and 6C).  It is called from
`allFigures.m` and takes no arguments.

Extended Data Figure 6-1 is Python, run from the repository root (not from the
fitting directory -- it reads its CSV by relative path):

    python plot_pupil_ne_cv_corrected.py    # -> glmhmm_pupil_ne_cv_corrected_figure.svg / .png

### Superseded outputs

Kept for comparison against the pre-correction model; none of these are what the
paper reports.

    glmhmm_K3_state_assignments.csv      glmhmm_cv_results.csv
    glmhmm_cv_corrected_results.csv      glmhmm_pupil_ne_cv_results.csv
    glmhmm_pupil_ne_cv.py                plot_pupil_ne_cv.py
    glm_hmm_utils_v2.py
