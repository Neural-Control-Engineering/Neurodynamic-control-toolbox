% Figure 1. Experimental setup and behavioral task. 
% A) Experimental set up. The illustration was created with biorender.com.
% B) Diagram of the tactile detection task.
% C) Response time for each stimulus. Gray lines indicate individual animals. 
% Dark line indicate the average across all session in this figure.
% D) Top: raster plot of the animal’s response around the presentation of tactile stimuli in an example session. 
% Bottom: histgram of licking response within the window of opportunity.
% E) Response probablity for each tactile stimulus.
% F) Perceptual sensitivity associated with tactile stimuli with different intensities.

addpath(genpath('Fig1/'))
Datastore = load('Combined-Datastore_created_14-Jan-2024.mat');
data = filterTrials(Datastore.Datastore, 'recording_location', 'mPFC-S1');
data(cellfun(@isempty, data.photometry_ch1),:) = [];

fig1c(data);
fig1ef(data);