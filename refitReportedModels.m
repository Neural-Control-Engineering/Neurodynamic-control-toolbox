% Refits the models whose degrees of freedom the manuscript reports
% incompletely, and fits the continuous/quadratic arousal models requested in
% the first round of review ("analyses using continuous linear and quadratic
% pupil size predictors ... this applies to the GRABne signals too").
%
% No plotting and no per-session psychometric loops. An earlier attempt drove
% the figure functions directly so the specifications would be identical to the
% published ones; it spent 28 minutes inside fig2g -- an
% RT ~ Pupil + (1|Session) + (1|Subject) fit on ~6,300 rows -- without
% finishing, so this fits the models directly instead.
%
% VALIDATION OUTCOME. Because these are refits, each model with a published F
% was checked against it before its degrees of freedom were used:
%
%   REPRODUCES (DF2 = 6232 substituted into the text):
%     fig2b  baseline pupil ~ response   F(1,6232)=82.54  vs published 82.5
%     fig4g  baseline mPFC NE ~ response F(1,6232)=0.423  vs published 0.43
%     fig4a  baseline S1 NE ~ response   F(1,6232)=0.716  vs published 0.73
%
%   DOES NOT REPRODUCE (left alone in the manuscript):
%     fig1c  RT ~ stimulus       F(1,3470)=91.4  vs published F(5)=0.75
%     fig2g  RT ~ pupil quintile F(4,3467)=2.19  vs published F(4)=3.9
%     fig4e  RT ~ S1 NE quintile F(4,3467)=1.66  vs published F(4)=9.9
%     fig4k  RT ~ mPFC quintile  F(4,3467)=0.28  vs published F(4)=1.3
%     fig5b  S1 NE ~ pupil quint F(4,6229)=12.87 vs published F(4)=15.3
%     fig5b  mPFC ~ pupil quint  F(4,6229)=16.92 vs published F(4)=23.5
%
% The failures are specification differences here, not errors in the paper: the
% figure functions treat stimulus intensity as categorical, subset to response
% trials for reaction time, and derive quintile edges from a precomputed
% Datastore column. Anyone completing the remaining degrees of freedom should
% take them from anova(lme), which prints DF1 and DF2, inside each function.
%
% WHERE THESE DF ENDED UP, AND WHAT STILL NEEDS CHECKING. The DF2 = 6232 above
% was substituted into four places in the Results, but this script only ever fit
% three of them:
%
%   OK   para 57  baseline pupil ~ response      F(1,6232)=82.5  -> fig2b here
%   OK   para 63  baseline S1 NE ~ response      F(1,6232)=0.73  -> fig4a here
%   OK   para 64  baseline mPFC NE ~ response    F(1,6232)=0.43  -> fig4g here
%   NO   para 61  S1-mPFC correlation ~ response F(1,6232)=9.2   -- never fit
%                 here; that DF2 was carried over from the models above and
%                 should be taken from anova(lme) in fig3d instead.
%
% Separately, para 58 reports F(3,6230) = 260.9 for the baseline-corrected
% dilation comparison (Extended Data Fig 2-1). That model lives in
% SupplementalFigs/suppFig1.m, not here; only its DF2 traces to this
% extraction. It is also the one result of the group that depends on the
% evoked-measure definition, and suppFig1.m now computes dilation as max minus
% baseline, so its F should be re-read from that function's own output. The
% three models above are unaffected -- their DV is the mean over the 0.5 s
% pre-stimulus window, which is what the Methods specifies for a baseline.
%
% Note also: this extraction yields n = 6,234 trials, while Tables 1-3 report
% 6,323, so every DF2 above is roughly 89 trials short of the tables'. The
% trial filter that produces 6,323 is the one to reconcile against.
%
% (An earlier version of this comment flagged the no-stimulus trials -- CR + FA
% = 854, or 13.7% of the data -- against a Methods statement of 40% catch
% trials. The manuscript now states 14%, so that discrepancy is resolved.)
%
% No local functions: run() evaluates in the caller's context, where R2018a
% rejects function definitions.
try
    % cd('D:\eneuro_rerun');
    % addpath(genpath('D:\eneuro_rerun'));
    addpath(genpath('./'))

    Datastore = load('Combined-Datastore_created_14-Jan-2024.mat');
    data = filterTrials(Datastore.Datastore, 'recording_location', 'mPFC-S1');
    data(cellfun(@isempty, data.photometry_ch1),:) = [];
    alignTo = 'stimulus';

    outcomes = {'Hit','Miss','CR','FA'};
    isResp   = [1 0 0 1];

    pupil=[]; s1=[]; mpfc=[]; resp=[]; outc=[]; stim=[]; rt=[]; sess={}; subj={};
    for o = 1:4
        otmp = filterTrials(data, 'categorical_outcome', outcomes{o});
        if isempty(otmp); continue; end
        [p, pt]   = avg_pupil_traces(otmp, [-0.6, 0], alignTo);
        [m, s, ~] = avg_photo_traces(otmp, [-0.5, 0], alignTo, 'z-score');
        pupil = [pupil; nanmean(p(:, pt > -0.5 & pt < 0), 2)];
        mpfc  = [mpfc;  nanmean(m, 2)];
        s1    = [s1;    nanmean(s, 2)];
        resp  = [resp;  repmat(isResp(o), size(otmp,1), 1)];
        outc  = [outc;  repmat(o, size(otmp,1), 1)];
        stim  = [stim;  otmp.stimulus_strength .* 10];
        rt    = [rt;    otmp.response_time];
        sid   = string(otmp.session_id);
        sess  = [sess; cellstr(sid)];
        subj  = [subj; cellstr(extractBefore(sid, '-'))];
    end
    fprintf('n trials = %d, sessions = %d\n', numel(resp), numel(unique(sess)));
    for o = 1:4
        fprintf('  %-4s n = %d\n', outcomes{o}, sum(outc==o));
    end
    fprintf('\n');

    S = categorical(sess); U = categorical(subj);

    % --- quintiles, computed inline ---------------------------------------
    Q = nan(numel(pupil), 3);
    src = [pupil, mpfc, s1];
    for v = 1:3
        x = src(:,v);
        e = prctile(x, [20 40 60 80]);
        q = ones(size(x));
        for k = 1:4, q(x > e(k)) = k+1; end
        q(isnan(x)) = NaN;
        Q(:,v) = q;
    end
    qp = Q(:,1); qm = Q(:,2); qs = Q(:,3);

    % --- the ten single-df statistics -------------------------------------
    specs = {
      'fig1c  RT ~ stimulus intensity', ...
        table(rt, stim, S, U, 'VariableNames', {'RT','Stimulus','Session','Subject'}), ...
        'RT ~ Stimulus + (1|Session) + (1|Subject)';
      'fig2b  baseline pupil ~ response', ...
        table(pupil, categorical(resp), S, U, 'VariableNames', {'Baseline','Response','Session','Subject'}), ...
        'Baseline ~ Response + (1|Session) + (1|Subject)';
      'fig2g  RT ~ baseline pupil quintile', ...
        table(rt, categorical(qp), S, U, 'VariableNames', {'RT','Pupil','Session','Subject'}), ...
        'RT ~ Pupil + (1|Session) + (1|Subject)';
      'fig4a  baseline S1 NE ~ response', ...
        table(s1, categorical(resp), S, U, 'VariableNames', {'Baseline','Response','Session','Subject'}), ...
        'Baseline ~ Response + (1|Session) + (1|Subject)';
      'fig4g  baseline mPFC NE ~ response', ...
        table(mpfc, categorical(resp), S, U, 'VariableNames', {'Baseline','Response','Session','Subject'}), ...
        'Baseline ~ Response + (1|Session) + (1|Subject)';
      'fig4e  RT ~ baseline S1 NE quintile', ...
        table(rt, categorical(qs), S, U, 'VariableNames', {'RT','NE','Session','Subject'}), ...
        'RT ~ NE + (1|Session) + (1|Subject)';
      'fig4k  RT ~ baseline mPFC NE quintile', ...
        table(rt, categorical(qm), S, U, 'VariableNames', {'RT','NE','Session','Subject'}), ...
        'RT ~ NE + (1|Session) + (1|Subject)';
      'fig5b  baseline S1 NE ~ pupil quintile', ...
        table(s1, categorical(qp), S, U, 'VariableNames', {'NE','Pupil','Session','Subject'}), ...
        'NE ~ Pupil + (1|Session) + (1|Subject)';
      'fig5b  baseline mPFC NE ~ pupil quintile', ...
        table(mpfc, categorical(qp), S, U, 'VariableNames', {'NE','Pupil','Session','Subject'}), ...
        'NE ~ Pupil + (1|Session) + (1|Subject)';
    };

    for i = 1:size(specs,1)
        fprintf('##### %s\n', specs{i,1});
        try
            lme = fitlme(specs{i,2}, specs{i,3});
            a = anova(lme);
            for r = 1:size(a,1)
                nm = char(a.Term{r});
                if strcmp(nm,'(Intercept)'); continue; end
                fprintf('   %-12s F(%d,%d) = %.4g,  p = %.4g\n', nm, ...
                        a.DF1(r), a.DF2(r), a.FStat(r), a.pValue(r));
            end
        catch ME
            fprintf('   FAILED: %s\n', ME.message);
        end
        fprintf('\n');
    end

    % --- continuous + quadratic arousal (R1 reviewer 2) --------------------
    qnames = {'baseline pupil area','baseline mPFC NE','baseline S1 NE'};
    for v = 1:3
        x = src(:,v);
        T = table(double(resp), stim, x, x.^2, S, U, ...
              'VariableNames', {'Response','Stimulus','X','X2','Session','Subject'});
        T(isnan(T.Stimulus) | isnan(T.X), :) = [];
        fprintf('##### quadratic: %s (n = %d)\n', qnames{v}, height(T));
        try
            g = fitglme(T, 'Response ~ Stimulus + X + X2 + (1|Session) + (1|Subject)', ...
                        'Distribution','Binomial','Link','logit');
            C = g.Coefficients;
            for r = 1:size(C,1)
                fprintf('   %-12s b = %+8.4f  SE %.4f  t = %+7.3f  p = %.4g\n', ...
                    char(C.Name{r}), C.Estimate(r), C.SE(r), C.tStat(r), C.pValue(r));
            end
            b = C.Estimate; nm = C.Name;
            i1 = find(strcmp(nm,'X')); i2 = find(strcmp(nm,'X2'));
            if ~isempty(i1) && ~isempty(i2) && b(i2)~=0
                fprintf('   vertex at z = %.3f\n', -b(i1)/(2*b(i2)));
            end
        catch ME
            fprintf('   FAILED: %s\n', ME.message);
        end
        fprintf('\n');
    end

    fprintf('ALL DONE\n');
catch ME
    fprintf('CAUGHT ERROR:\n'); disp(getReport(ME));
end
exit
