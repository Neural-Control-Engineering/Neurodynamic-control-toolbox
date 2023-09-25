data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
animals = fetchAnimals(data);
data(cellfun(@isempty, data.photometry_ch1),:) = [];
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
    'behavior_pupil_combo', ...
    'dynamic_state'};
animals_v1 = [3316, 3258, 3133, 200, 199, 198, 197, 196, 180, 167, 152];
animals_v2 = [240, 241, 242, 243];

% features = {'stimulus strenghth', ...
%             'previous response', ...
%             'previous reward'};

% features = {'pupil area', ... 
%             'ch1 before stim', ... 
%             'ch2 before stim', ... 
%             'stimulus strength'};
features = {'Pupil', ... 
            'dPupil/dt', ...
            'd2Pupil/dt2', ...
            'Ch1', ... 
            'dCh1/dt', ... 
            'd2Ch1/dt2', ... 
            'Ch2', ... 
            'dCh2/dt', ... 
            'd2Ch2/dt2', ... 
            'stimulus strength'};

% p = gcp('nocreate');
% if isempty(p)
%     parpool(11)
% end

% for dv = 1:length(data_versions)
% dv = 2;
% data_ver = data_versions{dv};
% dv = 2;
data_ver = data_versions{end};
fformat = {data_ver, 'state_Python2mat.mat'};
results_dir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ssd_version, data_ver);
% for animal = animals_v2
animal = animals_v2(1);
outdir = strcat(results_dir, 'figures/weights/');
if ~exist(outdir, 'dir')
    mkdir(outdir)
end
% for k = kstates
k = kstates(1);
fname = sprintf('%s%i_%s_%i%s', results_dir, animal, fformat{1}, k, fformat{2});
results = load(fname);
n_features = size(results.glm_params{1,1},3);
weights = nan(k, n_features, 5);
for i = 1:5
    w = reshape(results.hmm_params{i,3},[k, n_features]);
    for ik = 1:k
        weights(ik, :, i) = w(ik,:);
    end
end

fig = figure('Visible', 'on');
cols = distinguishable_colors(n_features);
ticks = [];
labels = [];
for ik = 1:k
    hold on
    errorbar([1:n_features] + ik*20, mean(abs(weights(ik,:,:)), 3), std(abs(weights(ik,:,:)), [], 3), '.', 'Color', 'k', 'LineWidth', 2)
    bar([1:n_features] + ik*20, mean(abs(weights(ik,:,:)),3), 'k') %, 'FaceColor', cols(ik,:), 'EdgeColor', cols(ik,:))
    ticks = [ticks, [1:n_features] + ik*20];
    labels = [labels, features]
    xtickangle(45)
end
xticks(ticks)
xticklabels(labels)
a = get(gca,'XTickLabel');
set(gca,'XTickLabel',a,'fontsize',14)
% xlabel('Feature')
% ylabel('Weight')
% xlim([0.5, n_features+.5])
% xticks(1:n_features)



%         fig = plotTransitions(base_path, animal, data_ver, kstates, folds);
%         if ~exist(strcat(base_path,'figures/'), 'dir')
%             mkdir(strcat(base_path,'figures/'))
%         end
%         saveas(fig, strcat(base_path,'figures/','animal_',num2str(animal),'.svg'))
%         saveas(fig, strcat(base_path,'figures/','animal_',num2str(animal),'.fig'))
%         saveas(fig, strcat(base_path,'figures/','animal_',num2str(animal),'.png'))
%     end
% end

function fig = plotWeights(fname, animal, data_ver, kstates, folds)

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
