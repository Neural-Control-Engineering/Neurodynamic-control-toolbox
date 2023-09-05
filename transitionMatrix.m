ssd_version = 'v2';
kstates = [2, 3, 4, 5, 6];
data_versions = {'last_trial_behavior_no_bias', ... 
    'spontaneous_mpfc_s1_pupil_normalized', ... 
    'last_trial_behavior_drop_stim_no_bias', ...
    'behavior_pupil_mpfc_s1_combo', ... 
    'behavior_pupil_mpfc_combo', ... 
    'behavior_pupil_s1_combo', ...
    'spontaneous_mpfc_s1_pupil_drop_stim', ...
    'behavior_mpfc_s1_combo', ...
    'behavior_mpfc_combo', ...
    'behavior_s1_combo', ...
    'behavior_pupil_combo'};
animals_v1 = [3316, 3258, 3133, 200, 199, 198, 197, 196, 180, 167, 152];
animals_v2 = [240, 241, 242, 243];

p = gcp('nocreate');
if isempty(p)
    parpool(11)
end

parfor dv = 1:length(data_versions)
    data_ver = data_versions{dv};
    base_path = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ssd_version, data_ver);
    folds = 0:4;
    for animal = animals_v2
        fig = plotTransitions(base_path, animal, data_ver, kstates, folds);
        if ~exist(strcat(base_path,'figures/'), 'dir')
            mkdir(strcat(base_path,'figures/'))
        end
        saveas(fig, strcat(base_path,'figures/','animal_',num2str(animal),'.svg'))
        saveas(fig, strcat(base_path,'figures/','animal_',num2str(animal),'.fig'))
        saveas(fig, strcat(base_path,'figures/','animal_',num2str(animal),'.png'))
    end
end

function fig = plotTransitions(base_path, animal, data_ver, kstates, folds)

    fig = figure('Visible', 'off');
    tlc = tiledlayout(1, length(kstates));
    tlc.TileSpacing = 'compact';

    for k = kstates 
        mat = zeros(k,k,length(folds));
        for f = folds
            fname = sprintf('%s%i_%s_%istate_%ifold_params.mat', base_path, animal, data_ver, k, f);
            params = load(fname);
            mat(:,:,f+1) = exp(reshape(params.params{2},[k,k]));
        end
        nexttile(tlc)
        imagesc(0:k-1, 0:k-1, mean(mat,3))
        axis square
        xticks(0:k-1)
        yticks(0:k-1)
        colorbar()
        title(sprintf('%i States', k))
        clim([0,1])
        xtickangle(0)
    end
end
