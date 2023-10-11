% Plots the average accuracy vs number of HMM states for each 
% version of the model and for each animal.
% Craig Kelley, NEC Lab, 9/9/23

animals_v1 = [3316, 3258, 3133, 200, 199, 198, 197, 196, 180, 167, 152];
animals_v2 = [240, 241, 242, 243]; % version 2 of ssd data 
animals = animals_v2;
ssd_version = 'v2';
kstates = [2, 3, 4, 5, 6];
data_versions = {'last_trial_behavior_no_bias', ... 
    'spontaneous_mpfc_stim', ...
    'spontaneous_s1_stim', ...
    'spontaneous_pupil_stim'};
N_folds = 5;
animal = 240;
k = 4;
animalPlot(animal, ssd_version, data_versions, k, N_folds);


function fig = animalPlot(animal, ssd_version, data_versions, k, N_folds)
    % plots accuracy vs number of states for all models versions of single animal 
    fig = figure('Visible', 'on', 'WindowState', 'maximized');
    hold on
    cs = distinguishable_colors(length(data_versions));
    for i = 1:length(data_versions)
        results_dir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ... 
            ssd_version, data_versions{i});
        fformat = {data_versions{i}, 'state_Python2mat.mat'};
        fname = sprintf('%s%i_%s_%i%s', results_dir, animal, fformat{1}, k, fformat{2});
        tmp = load(fname);
        mat = tmp.accuracy';
        % end
        errorbar(i, mean(mat), std(mat), 'Color', 'k', 'LineWidth', 2, 'DisplayName', strrep(data_versions{i}, '_', '-'))
        hold on
        bar(i, mean(mat), 'FaceColor', 'k', 'EdgeColor', 'k');
        data_versions{i} = strrep(data_versions{i}, '_', '-');
    end
    title(num2str(animal))
    xlabel('Model Inputs')
    ylabel('Accuracy')
    xticks(1:length(data_versions))
    xticklabels(data_versions)
    xtickangle(45)
end

% function fig = allAnimals(animals, ssd_version, data_versions, kstates, N_folds)
%     % plots accuracy vs number of states for all versions of the model for all 
%     % animals 
%     fig = figure('Visible', 'on', 'WindowState', 'maximized');
%     tcl = tiledlayout(2,2);
%     cs = distinguishable_colors(length(data_versions));
%     for a = 1:length(animals)
%         animal = animals(a);
%         nexttile(tcl)
%         hold on
%         ebars = zeros(1,length(data_versions));
%         for i = 1:length(data_versions)
%             results_dir = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ... 
%                 ssd_version, data_versions{i});
%             fformat = {data_versions{i}, 'state_Python2mat.mat'};
%             mat = nan(N_folds, length(kstates));
%             for k = 1:length(kstates)
%                 fname = sprintf('%s%i_%s_%i%s', results_dir, animal, fformat{1}, kstates(k), fformat{2});
%                 tmp = load(fname);
%                 mat(:,k) = tmp.accuracy';
%             end
%             ebars(i) = errorbar(kstates+(rand()-0.5)/10, mean(mat), std(mat), ...
%                 "-*", 'Color', cs(i,:), 'LineWidth', 2, ... 
%                 'DisplayName', strrep(data_versions{i}, '_', '-'));
%         end
%         title(sprintf('Animal %s', num2str(animal)), FontSize=14)
%         xlabel('Number of HMM States', FontSize=14)
%         ylabel('Accuracy', FontSize=14)
%         xticks(kstates)
%         ylim([0.5, 1.0])
%     end
    
%     hl = legend(ebars);
%     hl.Layout.Tile = 'East';
%     saveas(fig, sprintf('Analysis/acc_vs_states.svg', animal))
%     saveas(fig, sprintf('Analysis/acc_vs_states.png', animal))
%     saveas(fig, sprintf('Analysis/acc_vs_states.fig', animal))
% end



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
