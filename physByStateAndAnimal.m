% function psychCurvesByStateAndAnimal(data, animals, outdir)
% fformat = {'spon_photo_pupil_v2_', 'state_Python2mat.mat'};
% results_dir = 'NT-GLM-HMM/results_v1/';
% outdir = 'Analysis/phys_by_glm_states_v1/';
fformat = {'last_trial_behavior_', 'state_Python2mat.mat'};
% results_dir = 'NT-GLM-HMM/results_v2/';
results_dir = 'NT-GLM-HMM/prev_behavior/unshuffled/';
outdir = 'Analysis/phys_by_glm_states_prev_behavior/';
animals = [3316, 3258, 3133, 200, 199, 198, 197, 196, 180, 167, 152];
% animals = [240, 241, 242, 243];
% kstates = [2,3,4,5];
kstates = [3];

if ~exist(outdir, 'dir')
    mkdir(outdir)
end

for a = animals
    tmp = filterTrials(data, 'animal', num2str(a));
    for k = kstates
        filename = sprintf('%s%i_%s%i%s', results_dir, a, fformat{1}, k, fformat{2});
        plot_phys_by_states(filename, tmp, num2str(a), outdir)
    end
end




