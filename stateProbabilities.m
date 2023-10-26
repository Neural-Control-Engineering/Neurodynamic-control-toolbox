% script for plotting probabilit of each hmm state on every trial 
% for all animals and versions of the model 
% Craig Kelley, NEC Lab, 9/8/23

data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
animals = fetchAnimals(data);
data(cellfun(@isempty, data.photometry_ch1),:) = [];
ssd_version = 'v2';
kstates = [2, 3, 4, 5, 6];
% data_versions = {'last_trial_behavior_no_bias', ... 
%     'spontaneous_mpfc_s1_pupil_normalized', ... 
%     'last_trial_behavior_drop_stim_no_bias', ...
%     'behavior_pupil_mpfc_s1_combo', ... 
%     'behavior_pupil_mpfc_combo', ... 
%     'behavior_pupil_s1_combo', ...
%     'spontaneous_mpfc_s1_pupil_drop_stim', ...
%     'behavior_mpfc_s1_combo', ...
%     'behavior_mpfc_combo', ...
%     'behavior_s1_combo', ...
%     'behavior_pupil_combo', ...
%     'spontaneous_pupil_stim', ...
%     'spontaneous_mpfc_stim', ...
%     'spontaneous_s1_stim'};
% data_versions = {'dynamic_state'};
data_versions = {'last_trial_behavior_no_bias', ... 
    'spontaneous_mpfc_stim', ...
    'spontaneous_s1_stim', ...
    'spontaneous_pupil_stim'};
% data = rmDiscrepantTrials(data);
tls = {'Prev. Trial Behavior + Stim. Strength', 'mPFC NE + Stim. Strength', 'S1 NE + Stim. Strength', 'Pupil Area + Stim. Strength'};
animals_v1 = [3316, 3258, 3133, 200, 199, 198, 197, 196, 180, 167, 152];
animals_v2 = [240, 241, 242, 243];
animals = animals_v2;

animal = 241;
k = 5;
probVsTrialAllVers(data_versions, animal, k, tls)

% for dv = 1:length(data_versions)
%     data_ver = data_versions{dv};
%     fformat = {data_ver, 'state_Python2mat.mat'};
%     results_dir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ssd_version, data_ver);
%     outdir = strcat(results_dir, 'figures/state_prob_by_trial/');
%     if ~exist(outdir, 'dir')
%         mkdir(outdir)
%     end
%     for animal = animals
%         for k = kstates
%             fname = sprintf('%s%i_%s_%i%s', results_dir, animal, fformat{1}, k, fformat{2});
%             plotProbVsTrial(fname, animal, k, outdir)
%         end
%     end
% end

function plotProbVsTrial(fname, animal, k, outdir)
    results = load(fname);
    cols = distinguishable_colors(k);
    fig = figure('Visible', 'off', 'WindowState', 'maximized');
    hold on
    for i = 1:k 
        plot(1:size(results.states_probs,1), results.states_probs(:,i), 'Color', cols(i,:), 'DisplayName', sprintf('State %i',i-1))
    end
    legend()
    ylabel('p(state)')
    xlabel('Trial Number')
    saveas(fig, sprintf('%sanimal%i_%istates.svg', outdir, animal, k))
    saveas(fig, sprintf('%sanimal%i_%istates.png', outdir, animal, k))
    saveas(fig, sprintf('%sanimal%i_%istates.fig', outdir, animal, k))
    close()
end

function probVsTrialAllVers(data_versions, animal, k, tls)
    fig = figure('Visible', 'on', 'WindowState', 'maximized');
    ssd_version = 'v2';
    for dv = 1:length(data_versions)
        data_ver = data_versions{dv};
        fformat = {data_ver, 'state_Python2mat.mat'};
        results_dir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ssd_version, data_ver);
        fname = sprintf('%s%i_%s_%i%s', results_dir, animal, fformat{1}, k, fformat{2});
        results = load(fname);
        cols = distinguishable_colors(k);
        subplot(length(data_versions), 1, dv)
        hold on
        for i = 1:k 
            plot(1:size(results.states_probs,1), results.states_probs(:,i), 'Color', cols(i,:), 'DisplayName', sprintf('State %i',i-1))
        end
        legend()
        ylabel('P(state)', 'FontSize', 14)
        xlabel('Trial Number', 'FontSize', 14)
        title(tls{dv}, 'FontSize', 16, 'FontWeight', 'bold')
    end
end