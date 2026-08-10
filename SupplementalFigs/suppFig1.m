function suppFig1(data, tbounds, alignTo)
    % Reviewer (R1) asked us to regress trial-wise baseline pupil size OUT of
    % trial-wise evoked pupil responses and run the test on the residuals.
    %
    % The previous version did not do that. It fit the baseline->dilation model
    % on Hit trials only and then called predict(mdl, d), passing the dilation
    % where the predictor (baseline) belongs, so the "residual" was an affine
    % rescaling of the dilation itself with no baseline removed. It also had no
    % test in the file at all -- it stopped at a keyboard breakpoint, so the
    % reported ANOVA was run by hand and was not reproducible from this repo.
    %
    % This version pools the regression across all four outcomes, residualises
    % trial-wise, and runs the test in code.

    if ~exist('alignTo', 'var')
        alignTo = 'stimulus';
    end

    outcomes = {'Hit', 'Miss', 'CR', 'FA'};
    outcome_names = {'Hit', 'Miss', 'Correct Rejection', 'False Alarm'};

    baselines = [];
    dilations = [];
    group = [];
    sess = {};
    subj = {};
    for o = 1:length(outcomes)
        otmp = filterTrials(data, 'categorical_outcome', outcomes{o});
        if isempty(otmp)
            continue
        end
        [pupil, t] = avg_pupil_traces(otmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
        pupil = pupil(:,2:end-1);
        t = t(2:end-1);
        b = nanmean(pupil(:,(t > -0.5 & t < 0)), 2);
        e = max(pupil(:,(t > 0 & t < 6)), [], 2);
        d = e - b;
        baselines = [baselines; b];
        dilations = [dilations; d];
        group = [group; repmat(o, numel(d), 1)];
        % avg_pupil_traces returns one row per input trial, so these stay aligned.
        % animal id is the first field of session_id (see fetchAnimals.m)
        sid = string(otmp.session_id);
        sess = [sess; cellstr(sid)];
        subj = [subj; cellstr(extractBefore(sid, '-'))];
    end

    % --- residualise: regress trial-wise baseline out of trial-wise evoked ---
    ok = ~isnan(baselines) & ~isnan(dilations);
    mdl = fitlm(baselines(ok), dilations(ok));
    fprintf('\nBaseline -> dilation regression (pooled across outcomes, n = %i trials):\n', sum(ok));
    disp(mdl)

    resid = nan(size(dilations));
    resid(ok) = dilations(ok) - predict(mdl, baselines(ok));

    residuals = cell(1, length(outcomes));
    for o = 1:length(outcomes)
        residuals{o} = resid(group == o & ok);
    end

    % --- test on the residuals (what the reviewer asked for) ---
    fprintf('\nANOVA on baseline-residualised evoked pupil dilation, by trial outcome:\n');
    [p_anova, tbl_anova, stats_anova] = anova1(resid(ok), group(ok), 'off');
    disp(tbl_anova)
    fprintf('ANOVA(outcome) on residuals: F(%i,%i) = %.3f, p = %.4g\n', ...
        tbl_anova{2,3}, tbl_anova{3,3}, tbl_anova{2,5}, p_anova);
    fprintf('\nTukey-Kramer post hoc:\n');
    c = multcompare(stats_anova, 'Display', 'off');
    for i = 1:size(c,1)
        fprintf('  %-18s vs %-18s  diff %7.4f  p = %.4g\n', ...
            outcome_names{c(i,1)}, outcome_names{c(i,2)}, c(i,4), c(i,6));
    end

    % --- same contrast as a mixed model, matching the LME approach used
    %     elsewhere in the revision (random intercepts for subject + session) ---
    try
        tblLME = table(resid(ok), categorical(group(ok)), categorical(sess(ok)), ...
                       categorical(subj(ok)), ...
                       'VariableNames', {'Residual', 'Outcome', 'Session', 'Subject'});
        lme = fitlme(tblLME, 'Residual ~ 1 + Outcome + (1|Session) + (1|Subject)');
        lme0 = fitlme(tblLME, 'Residual ~ 1 + (1|Session) + (1|Subject)');
        fprintf('\nLinear mixed-effects model (random intercepts: session, subject):\n');
        disp(lme)
        fprintf('\nLikelihood ratio test vs intercept-only:\n');
        disp(compare(lme0, lme))
    catch ME
        fprintf('LME skipped: %s\n', ME.message);
    end

    % --- figure ---
    fig = figure();
    bar(1:4, cellfun(@nanmean, residuals), 'FaceColor', [0.5,0.5,0.5]);
    hold on
    errorbar(1:4, cellfun(@nanmean, residuals), cellfun(@ste, residuals), 'k.')
    plot(xlim, [0 0], 'k:')
    xticks(1:4)
    xticklabels(outcome_names)
    xtickangle(45)
    ylabel('Baseline-Residualised Pupil Dilation', 'FontSize', 16)
    xlabel('Trial Outcome', 'FontSize', 16)
    set(fig, 'PaperPositionMode', 'auto')
    saveas(fig, 'Figures/suppFig1.fig')
    saveas(fig, 'Figures/suppFig1.svg')

end
