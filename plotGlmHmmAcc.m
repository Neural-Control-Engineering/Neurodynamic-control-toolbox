% Plots the average accuracy vs number of HMM states for each 
% version of the model and for each animal.
% Craig Kelley, NEC Lab, 9/9/23

animals_v1 = [3316, 3258, 3133, 200, 199, 198, 197, 196, 180, 167, 152];
animals_v2 = [240, 241, 242, 243]; % version 2 of ssd data 
animals = animals_v2;
ssd_version = 'v2';
% kstates = [2, 3, 4, 5, 6];
kstates = [2,3,4,5];
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
%     'behavior_pupil_combo'};
% data_versions = {'last_trial_behavior_no_bias', ... 
%     'spontaneous_mpfc_s1_pupil_normalized', ... 
%     'last_trial_behavior_drop_stim_no_bias', ...
%     'spontaneous_s1_stim', ...
%     'spontaneous_mpfc_stim', ...
%     'spontaneous_pupil_stim', ...
%     'dynamic_state'};
% data_versions = {'last_trial_behavior_no_bias', ... 
%     'spontaneous_pupil_stim', ...
%     'last_trial_behavior_drop_stim_no_bias', ...
%     'spontaneous_pupil_stim_v2', ...
%     'spontaneous_pupil_stim_1s_v2'
%      };
data_versions = {'last_trial_behavior_no_bias', ... 
    'last_trial_behavior_drop_stim_no_bias', ...
    'spontaneous_pupil_stim_v2', ...
     };
N_folds = 5;

% for animal = animals
%     animalPlot(animal, ssd_version, data_versions, kstates, N_folds, splot);
% end
% fig = animalPlot(animals(1), ssd_version, data_versions, kstates, N_folds)

% fig = allAnimals(animals, ssd_version, data_versions, kstates, N_folds);
% best_fig = combineAnimals(animals, data_versions, kstates, 'best');
all_fig = combineAnimals(animals, data_versions, kstates, 'all');

function fig = combineAnimals(animals, data_versions, kstates, lapse_ver)
    fig = figure('Visible', 'on');
    hold on
    cs = distinguishable_colors(length(data_versions));
    avgs = zeros(1,length(kstates)+1);
    stds = avgs;
    for i = 1:length(data_versions)
        results_dir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ... 
            'v3', data_versions{i});
        fformat = {data_versions{i}, 'state_Python2mat.mat'};
        for k = 1:length(kstates)
            mat = [];
            for animal = animals        
                fname = sprintf('%s%i_%s_%i%s', results_dir, animal, fformat{1}, kstates(k), fformat{2});
                tmp = load(fname);
                mat = [mat; tmp.accuracy];
            end
            avgs(k+1) = mean(mean(mat));
            stds(k+1) = std(reshape(mat, [1,numel(mat)])) / numel(mat);
        end
        accs = [];
        for animal = animals
            results_dir = sprintf('NT-GLM-HMM/data/lapse/%s/Lapse_Model/%i/', ... 
                data_versions{i}, animal);
            results = load(strcat(results_dir, 'results.mat'));
            switch lapse_ver 
                case 'best'
                    accs = [accs; max(results.accuracy)];
                case 'all'
                    accs = [accs; results.accuracy];
            end
        end
        avgs(1) = mean(accs ./ 100) ;
        stds(1) = std(accs ./ 100) / length(accs);
        % keyboard
        errorbar(1:max(kstates), avgs, stds, 'Color', cs(i,:), 'DisplayName', strrep(data_versions{i}, '_', '-'))
        hold on
    end
    xticks(1:max(kstates)); xticklabels({'L.', kstates})
    legend('location', 'southeast')
    xlim([0.75, max(kstates)+0.25])
    xlabel('Model / Number of HMM States', 'FontSize', 14)
    ylabel('Accuracy', 'FontSize', 14)
end

function fig = animalPlot(animal, ssd_version, data_versions, kstates, N_folds)
    % plots accuracy vs number of states for all models versions of single animal 
    fig = figure('Visible', 'on', 'WindowState', 'maximized');
    hold on
    cs = distinguishable_colors(length(data_versions));
    for i = 1:length(data_versions)
        results_dir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ... 
            ssd_version, data_versions{i});
        fformat = {data_versions{i}, 'state_Python2mat.mat'};
        mat = nan(N_folds, length(kstates));
        for k = 1:length(kstates)
            fname = sprintf('%s%i_%s_%i%s', results_dir, animal, fformat{1}, kstates(k), fformat{2});
            tmp = load(fname);
            mat(:,k) = tmp.accuracy';
        end
        errorbar(kstates+(rand()-0.5)/10, mean(mat), std(mat), cs(i,:), 'DisplayName', strrep(data_versions{i}, '_', '-'))
        legend('location', 'southeast')
    end
    title(num2str(animal))
    xlabel('Number of HMM States')
    ylabel('Accuracy')
    xticks(kstates)
end

function fig = allAnimals(animals, ssd_version, data_versions, kstates, N_folds)
    % plots accuracy vs number of states for all versions of the model for all 
    % animals 
    fig = figure('Visible', 'on', 'WindowState', 'maximized');
    tcl = tiledlayout(2,2);
    cs = distinguishable_colors(length(data_versions));
    for a = 1:length(animals)
        animal = animals(a);
        nexttile(tcl)
        hold on
        ebars = zeros(1,length(data_versions));
        for i = 1:length(data_versions)
            results_dir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ... 
                ssd_version, data_versions{i});
            fformat = {data_versions{i}, 'state_Python2mat.mat'};
            mat = nan(N_folds, length(kstates));
            for k = 1:length(kstates)
                fname = sprintf('%s%i_%s_%i%s', results_dir, animal, fformat{1}, kstates(k), fformat{2});
                tmp = load(fname);
                mat(:,k) = tmp.accuracy';
            end
            ebars(i) = errorbar(kstates+(rand()-0.5)/10, mean(mat), std(mat), ...
                "-*", 'Color', cs(i,:), 'LineWidth', 2, ... 
                'DisplayName', strrep(data_versions{i}, '_', '-'));
        end
        title(sprintf('Animal %s', num2str(animal)), FontSize=14)
        xlabel('Number of HMM States', FontSize=14)
        ylabel('Accuracy', FontSize=14)
        xticks(kstates)
        ylim([0.5, 1.0])
    end
    
    hl = legend(ebars);
    hl.Layout.Tile = 'East';
    saveas(fig, sprintf('Analysis/acc_vs_states.svg', animal))
    saveas(fig, sprintf('Analysis/acc_vs_states.png', animal))
    saveas(fig, sprintf('Analysis/acc_vs_states.fig', animal))
end



% %% shuffled data
% results_dir = 'NT-GLM-HMM/results_shuffle_phys/';
% for a = 1:length(animals)
%     mat = nan(N_folds, length(kstates));
%     for k = 1:length(kstates)
%         fname = sprintf('%s%i_%s%i%s', results_dir, animals(a), fformat{1}, kstates(k), fformat{2});
%         tmp = load(fname);
%         mat(:,k) = tmp.accuracy';
%     end
%     errorbar(kstates+(rand()-0.5)/10, mean(mat), std(mat), '--', 'DisplayName', num2str(animals(a)))
% end
% xlabel('K States')
% ylabel('Prediction Accuracy')
% legend('location','southwest')
