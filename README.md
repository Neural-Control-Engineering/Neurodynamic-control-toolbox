# Neurotransmitter_Exploration

This repository is a collection of code used to analyze pupillometry, fiber photometry recordings of GRABNE, and behavior 
in mice performing a simple tactile signal detection task.  Required data is available on upon request.  To generate all 
figures and analyses from our paper, simply unzip the data and run *allFigures.m*.  Code for running the GLM-HMM model 
are found in *NT-GLM-HMM/* and subfolders.  Specifically, a global model can be trained by running *NT-GLM-HMM/2_fit_models/fit_global_glmhmm/fit_corrected_global.py*,
and models for individual animals can be trained by running *NT-GLM-HMM/2_fit_models/fit_global_glmhmm/git_corrected_per_animal.py*.