% Figure 5. GLM-HMM modeling of behavior. 
% A) Diagram of the GLM-HMM model.
% B) Elbow plot of prediction accuracy vs number of states.
% C) Psychometric curve during the four states. 
% D) Fraction of toal trials during each state.
% E) Posterior state probabilities during an example portion of a session.
% F) Inferred transition matrix for the four-state GLM-HMM model.
% G) Reaction time during the four states.
% H) Decision criterion during the four states.


addpath(genpath('Fig5/'))
Datastore = load('Combined-Datastore_created_14-Jan-2024.mat');

fig5b
fig5c
fig5d
fig5e
fig5f
fig5f_individualAnimals
fig5g
fig5h