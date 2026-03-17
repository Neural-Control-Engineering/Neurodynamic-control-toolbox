function fig5b(animals, data_versions, kstates)
    all_fig = combineAnimals(animals, data_versions, kstates, 'all');
    saveas(all_fig, 'Figures/fig5b.fig')
    saveas(all_fig, 'Figures/fig5b.svg')
end

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
            try
                results = load(strcat(results_dir, 'results.mat'));
            catch
                results_dir = sprintf('NT-GLM-HMM/data/lapse/v3/%s/Lapse_Model/%i/', ... 
                    data_versions{i}, animal);
                results = load(strcat(results_dir, 'results.mat'));
            end
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
        errorbar(1:max(kstates), avgs, stds, 'Color', cs(i,:), 'DisplayName', strrep(data_versions{i}, '_', '-'), 'LineWidth', 2)
        hold on
    end
    xticks(1:max(kstates)); xticklabels({'L.', kstates})
    leg = legend('location', 'southeast');
    title(leg, 'Model Inputs')
    xlim([0.75, max(kstates)+0.25])
    xlabel('Model / Number of states', 'FontSize', 14)
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
    xlabel('Number of states')
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
        xlabel('Number of states', FontSize=14)
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
