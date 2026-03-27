"""
GLM-HMM utilities with pupil-driven state transitions.

Addresses eNeuro reviewer comment requesting a model similar to
Hulsey et al. (2024), where state dynamics are linked to baseline
pupil-linked arousal rather than having arousal as a direct predictor
of choice.

Architecture:
    - Transitions: InputDrivenTransitions (baseline pupil -> which state)
    - Observations: InputDrivenObservations (stimulus -> choice within state)

This eliminates circularity: pupil determines behavioral state,
then task-evoked pupil/NE dynamics are analyzed within those states.

Craig Kelley & Tim Lantin, NEC Lab
Based on original glm_hmm_utils.py by Craig Kelley
"""
import sys
import ssm
import autograd.numpy as np
import autograd.numpy.random as npr


# =============================================================================
# Data loading utilities (unchanged from original)
# =============================================================================

def load_data(animal_file):
    container = np.load(animal_file, allow_pickle=True)
    data = [container[key] for key in container]
    inpt = data[0]
    y = data[1]
    session = data[2]
    return inpt, y, session


def load_cluster_arr(cluster_arr_file):
    container = np.load(cluster_arr_file, allow_pickle=True)
    data = [container[key] for key in container]
    cluster_arr = data[0]
    return cluster_arr


def load_glm_vectors(glm_vectors_file):
    container = np.load(glm_vectors_file)
    data = [container[key] for key in container]
    loglikelihood_train = data[0]
    recovered_weights = data[1]
    return loglikelihood_train, recovered_weights


def load_global_params(global_params_file):
    container = np.load(global_params_file, allow_pickle=True)
    data = [container[key] for key in container]
    global_params = data[0]
    return global_params


def load_session_fold_lookup(file_path):
    container = np.load(file_path, allow_pickle=True)
    data = [container[key] for key in container]
    session_fold_lookup_table = data[0]
    return session_fold_lookup_table


def load_animal_list(file):
    container = np.load(file, allow_pickle=True)
    data = [container[key] for key in container]
    animal_list = data[0]
    return animal_list


def partition_data_by_session(inpt, y, mask, session):
    """Partition inpt, y, mask by session."""
    inputs = []
    datas = []
    indexes = np.unique(session, return_index=True)[1]
    unique_sessions = [session[index] for index in sorted(indexes)]
    counter = 0
    masks = []
    for sess in unique_sessions:
        idx = np.where(session == sess)[0]
        counter += len(idx)
        inputs.append(inpt[idx, :])
        datas.append(y[idx, :])
        masks.append(mask[idx, :])
    assert counter == inpt.shape[0], "not all trials assigned to session!"
    return inputs, datas, masks


def create_violation_mask(violation_idx, T):
    """Return indices of nonviolations and a Boolean mask."""
    mask = np.array([i not in violation_idx for i in range(T)])
    nonviolation_idx = np.arange(T)[mask]
    mask = mask + 0
    assert len(nonviolation_idx) + len(violation_idx) == T, \
        "violation and non-violation idx do not include all data!"
    return nonviolation_idx, np.expand_dims(mask, axis=1)


# =============================================================================
# Model fitting - pupil-driven transitions
# =============================================================================

def fit_glm_hmm(datas, inputs, masks, K, D, M, C, N_em_iters,
                transition_alpha, prior_sigma, global_fit,
                params_for_initialization, save_title,
                M_transition=1, use_input_driven_transitions=True):
    """
    Fit GLM-HMM with optional pupil-driven state transitions.

    Parameters
    ----------
    datas : list of arrays
        Choice data per session. Each element shape (n_trials, 1).
    inputs : list of arrays
        Input features per session. Each element shape (n_trials, M).
        Expected column layout when use_input_driven_transitions=True:
            - Columns 0 to M_transition-1: transition inputs (e.g., pupil)
            - Remaining columns: observation inputs (e.g., stimulus + bias)
    masks : list of arrays
        Violation masks per session.
    K : int
        Number of hidden states.
    D : int
        Observation dimensionality (1 for single choice).
    M : int
        Total number of input columns.
    C : int
        Number of choice categories (2 for go/no-go).
    N_em_iters : int
        Maximum EM iterations.
    transition_alpha : float
        Dirichlet concentration parameter for transitions.
    prior_sigma : float
        Prior standard deviation for observation weights.
    global_fit : bool
        If True, initialize from GLM weights. If False, from global params.
    params_for_initialization : array
        Parameters for initialization.
    save_title : str
        Path to save results.
    M_transition : int
        Number of input columns that drive transitions.
        Default 1 (just pupil). Set to 3 for pupil + mPFC + S1.
    use_input_driven_transitions : bool
        If True, use InputDrivenTransitions (pupil -> states).
        If False, use StickyTransitions (original behavior).
    """
    if use_input_driven_transitions:
        transition_type = "inputdriven"
        transition_kwargs = dict(alpha=transition_alpha, kappa=0)
        print(f"=== Fitting GLM-HMM with INPUT-DRIVEN TRANSITIONS ===")
        print(f"    Transition inputs: first {M_transition} column(s)")
        print(f"    Observation inputs: all {M} columns")
        print(f"    States: {K}, Categories: {C}")
    else:
        transition_type = "sticky"
        transition_kwargs = dict(alpha=transition_alpha, kappa=0)
        print(f"=== Fitting GLM-HMM with STICKY TRANSITIONS (original) ===")
        print(f"    All {M} columns drive observations")
        print(f"    States: {K}, Categories: {C}")

    sys.stdout.flush()

    # --- Build the model ---
    this_hmm = ssm.HMM(K, D, M,
                        observations="input_driven_obs",
                        observation_kwargs=dict(C=C, prior_sigma=prior_sigma),
                        transitions=transition_type,
                        transition_kwargs=transition_kwargs)

    # --- Initialize parameters ---
    if global_fit:
        # Initialize observation weights from GLM fit + noise
        glm_vectors_repeated = np.tile(params_for_initialization, (K, 1, 1))
        glm_vectors_with_noise = glm_vectors_repeated + np.random.normal(
            0, 0.2, glm_vectors_repeated.shape)
        this_hmm.observations.params = glm_vectors_with_noise
    else:
        # Initialize from global GLM-HMM parameters
        this_hmm.params = params_for_initialization

    # --- Fit ---
    lls = this_hmm.fit(datas,
                       inputs=inputs,
                       masks=masks,
                       method="em",
                       num_iters=N_em_iters,
                       initialize=False,
                       tolerance=10**-4)

    # --- Save ---
    np.savez(save_title, this_hmm.params, lls)
    print(f"    Final LL: {lls[-1]:.4f} after {len(lls)} iterations")
    sys.stdout.flush()
    return this_hmm, lls


def launch_glm_hmm_job(inpt, y, session, mask, session_fold_lookup_table,
                        K, D, C, N_em_iters, transition_alpha, prior_sigma,
                        fold, iter, global_fit, init_param_file,
                        save_directory, M_transition=1,
                        use_input_driven_transitions=True):
    """
    Launch a single GLM-HMM fitting job.

    Parameters
    ----------
    M_transition : int
        Number of input columns driving state transitions.
        For 'pupil_driven_transitions': M_transition=1
        For 'pupil_ne_driven_transitions': M_transition=3
    use_input_driven_transitions : bool
        True for reviewer model, False for original model.
    """
    print("Starting inference with K = " + str(K) + "; Fold = " + str(fold) +
          "; Iter = " + str(iter))
    sys.stdout.flush()

    sessions_to_keep = session_fold_lookup_table[np.where(
        session_fold_lookup_table[:, 1] != fold), 0]
    idx_this_fold = [str(sess) in sessions_to_keep for sess in session]
    this_inpt = inpt[idx_this_fold, :]
    this_y = y[idx_this_fold, :]
    this_session = session[idx_this_fold]
    this_mask = mask[idx_this_fold]

    # Replace violation markers
    this_y[np.where(this_y == -1), :] = 1

    inputs, datas, masks = partition_data_by_session(
        this_inpt, this_y, this_mask, this_session)

    # Load initialization parameters
    if global_fit:
        _, params_for_initialization = load_glm_vectors(init_param_file)
    else:
        params_for_initialization = load_global_params(init_param_file)

    M = this_inpt.shape[1]
    npr.seed(iter)

    fit_glm_hmm(datas, inputs, masks,
                K, D, M, C, N_em_iters,
                transition_alpha, prior_sigma,
                global_fit, params_for_initialization,
                save_title=save_directory + 'glm_hmm_raw_parameters_itr_' +
                           str(iter) + '.npz',
                M_transition=M_transition,
                use_input_driven_transitions=use_input_driven_transitions)
