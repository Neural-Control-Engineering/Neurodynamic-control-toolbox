"""
Column-routed GLM-HMM: pupil drives ONLY transitions, stimulus+bias drive
ONLY observations.

Background
----------
The previous "pupil-driven transitions" model (glm_hmm_utils_v2.py) built a
single ssm.HMM with a shared 3-column input [pupil, stim, bias] fed to BOTH
the InputDrivenObservations and the InputDrivenTransitions. The M_transition
argument was never used to slice anything, so baseline pupil entered the
choice (observation) GLM as well as the transition GLM. That does NOT remove
the circularity the eNeuro reviewer raised (pupil defines states, then pupil
is analyzed within those states).

This module routes inputs to each sub-model explicitly:
    - Observations (stim, bias)  -> input columns [1, 2]   (pupil EXCLUDED)
    - Transitions  (pupil)       -> input column  [0]

The HMM still receives the full [pupil, stim, bias] input; the subclasses
slice their own columns internally, so ssm's shared-input plumbing is
respected.

Craig Kelley & Tim Lantin, NEC Lab
"""
import autograd.numpy as np
from ssm.observations import InputDrivenObservations
from ssm.transitions import InputDrivenTransitions


# Column layout of the shared input matrix [pupil, stim, bias]
PUPIL_COLS = [0]      # -> transitions
OBS_COLS = [1, 2]     # stim, bias -> observations


class StimBiasObservations(InputDrivenObservations):
    """Choice GLM that sees only stim+bias columns (ignores pupil col 0)."""

    def __init__(self, K, D, M_full, C=2, prior_sigma=2, obs_cols=OBS_COLS):
        self.obs_cols = list(obs_cols)
        self.M_full = M_full
        # parent's M is the number of OBSERVATION regressors actually used
        super(StimBiasObservations, self).__init__(
            K, D, M=len(self.obs_cols), C=C, prior_sigma=prior_sigma)

    def calculate_logits(self, input):
        return super(StimBiasObservations, self).calculate_logits(
            input[:, self.obs_cols])

    def sample_x(self, z, xhist, input=None, tag=None, with_noise=True):
        if input is not None and input.ndim == 2:
            input = input[:, self.obs_cols]
        return super(StimBiasObservations, self).sample_x(
            z, xhist, input, tag, with_noise)


class PupilTransitions(InputDrivenTransitions):
    """Transition GLM driven only by baseline pupil (input col 0)."""

    def __init__(self, K, D, M_full, alpha=1, kappa=0, trans_cols=PUPIL_COLS):
        self.trans_cols = list(trans_cols)
        self.M_full = M_full
        super(PupilTransitions, self).__init__(
            K, D, M=len(self.trans_cols), alpha=alpha, kappa=kappa)

    def log_transition_matrices(self, data, input, mask, tag):
        return super(PupilTransitions, self).log_transition_matrices(
            data, input[:, self.trans_cols], mask, tag)


def build_routed_hmm(K, D, M_full, C=2, prior_sigma=2,
                     transition_alpha=1, transition_kappa=0):
    """
    Construct an ssm.HMM whose observations use stim+bias and whose
    transitions use pupil only. The HMM is built with the full input
    dimensionality, then its observation/transition objects are replaced
    with the column-routed subclasses.
    """
    import ssm
    hmm = ssm.HMM(K, D, M_full,
                  observations="input_driven_obs",
                  observation_kwargs=dict(C=C, prior_sigma=prior_sigma),
                  transitions="inputdriven",
                  transition_kwargs=dict(alpha=transition_alpha,
                                         kappa=transition_kappa))
    hmm.observations = StimBiasObservations(
        K, D, M_full, C=C, prior_sigma=prior_sigma)
    hmm.transitions = PupilTransitions(
        K, D, M_full, alpha=transition_alpha, kappa=transition_kappa)
    return hmm
