%% plot_glmhmm_comparison.m
% Generates separate .fig files for each metric from glmhmm_cv_results.csv
% 4 subplots: Accuracy, ROC-AUC, PR-AUC, Bits/trial

%% Load data
T = readtable('glmhmm_cv_results.csv');

models = unique(T.model, 'stable');
Ks = unique(T.K);
metrics = {'accuracy', 'roc_auc', 'pr_auc', 'bits_per_trial'};
titles = {'Accuracy', 'ROC-AUC', 'PR-AUC', 'Log-likelihood (bits/trial)'};
ylabels = {'Accuracy', 'AUC', 'AUC', 'bits/trial'};

colors = struct('Original', [0.2 0.4 0.8], 'New', [0.9 0.3 0.2]);

%% Generate one .fig per metric
for m = 1:length(metrics)
    fig = figure('Name', titles{m}, 'Position', [100 100 500 400]);
    hold on;
    
    for mi = 1:length(models)
        model = models{mi};
        idx = strcmp(T.model, model);
        sub = T(idx, :);
        
        k_vals = unique(sub.K);
        means = zeros(size(k_vals));
        sems = zeros(size(k_vals));
        
        for ki = 1:length(k_vals)
            vals = sub.(metrics{m})(sub.K == k_vals(ki));
            means(ki) = mean(vals);
            sems(ki) = std(vals) / sqrt(length(vals));
        end
        
        c = colors.(model);
        errorbar(k_vals, means, sems, '-o', ...
            'Color', c, 'MarkerFaceColor', c, 'MarkerSize', 7, ...
            'LineWidth', 1.5, 'CapSize', 8, ...
            'DisplayName', model);
    end
    
    xlabel('Number of states (K)');
    ylabel(ylabels{m});
    title(titles{m});
    legend('Location', 'best');
    set(gca, 'XTick', Ks, 'FontSize', 12);
    box on; grid on;
    hold off;
    
    % Save as .fig
    fname = sprintf('glmhmm_%s.fig', metrics{m});
    savefig(fig, fname);
    fprintf('Saved %s\n', fname);
    
    % Also save as .png
    fname_png = sprintf('glmhmm_%s.png', metrics{m});
    exportgraphics(fig, fname_png, 'Resolution', 300);
    fprintf('Saved %s\n', fname_png);
end

fprintf('\nDone. Generated 4 .fig + 4 .png files.\n');
