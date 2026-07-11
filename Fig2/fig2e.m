function fig2e(data, tbounds, alignTo)
    stim_strengths = unique(data.stimulus_strength);
    cols = distinguishable_colors(length(stim_strengths)+1);
    % tmp = filterTrials(data, 'categorical_outcome', 'Hit');
    dilations = [];
    baselines = [];
    stimuli = [];
    sessions = {};
    subjects = {};
    responses = [];
    for s = 1:length(stim_strengths)
        stmp = filterTrials(data, 'stim_strength', stim_strengths(s));
        [pupil, t] = avg_pupil_traces(stmp, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
        pupil = pupil(:,2:end-1);
        t = t(2:end-1);
        b =  nanmean(pupil(:,(t > -0.5 & t < 0)),2);
        e = nanmean(pupil(:,(t > 0 & t < 6)),2);
        d = e - b;
        baselines = [baselines; b];
        dilations = [dilations; d];
        stimuli = [stimuli; zeros(size(b)) + stim_strengths(s)];
        sessions = vertcat(sessions, stmp.session_id);
        for t = 1:size(stmp,1)
            if strcmp(stmp(t,:).categorical_outcome{1}, 'Hit') | strcmp(stmp(t,:).categorical_outcome{1}, 'FA')
                responses = [responses; 1];
            else
                responses = [responses; 0];
            end
            subjects = vertcat(subjects, stmp(t,:).session_id{1}(1:3));
        end
        % plot(b, e, 'o', 'MarkerFaceColor', cols(s,:), 'MarkerSize', 2.0)
        % hold on
    end
    fig = figure();
    scatter(baselines, dilations, 'MarkerFaceColor', [0.5,0.5,0.5], 'MarkerEdgeColor', [1,1,1])
    x = baselines;
    y = dilations;
    mdl = fitlm(x, y)
    [FM, S]=polyfit(x(~isnan(x)),y(~isnan(y)),1);
    [FM_vals, delta] = polyval(FM,linspace(min(x),max(x),10), S); 
    hold on; plot(linspace(min(x),max(x),10), FM_vals, 'k--', 'linewidth',2) 
    xlabel('Baseline Pupil Area (z-score)', 'FontSize', 16)
    ylabel('Pupil Dilation (z-score)', 'FontSize', 16)
    xlim([-2.5,5.1])
    saveas(fig, 'Figures/fig2e.fig')
    saveas(fig, 'Figures/fig2e.svg')

    T = table(dilations, baselines, responses, stimuli, sessions, subjects,  'VariableNames', {'Dilation', 'Baseline', 'Response', 'Stimulus', 'Session', 'Subject'});

    lmeTbl = T(:, {'Dilation', 'Baseline','Stimulus','Response','Session', 'Subject'});

    % Make sure response is numeric
    lmeTbl.Dilation = double(lmeTbl.Dilation);

    % Make predictors categorical
    lmeTbl.Baseline = double(lmeTbl.Baseline);
    lmeTbl.Stimulus = categorical(lmeTbl.Stimulus);
    lmeTbl.Response = categorical(lmeTbl.Response);
    lmeTbl.Session  = categorical(lmeTbl.Session);
    lmeTbl.Subject  = categorical(lmeTbl.Subject);

    % Remove rows with missing values in any model variable
    badRows = isnan(lmeTbl.Dilation) | ...
            isundefined(lmeTbl.Stimulus) | ...
            isnan(lmeTbl.Baseline) | ...
            isundefined(lmeTbl.Response) | ...
            isundefined(lmeTbl.Subject) | ...
            isundefined(lmeTbl.Session);

    lmeTbl(badRows,:) = [];

    % Optional but useful: remove unused category levels
    lmeTbl.Stimulus = removecats(lmeTbl.Stimulus);
    lmeTbl.Response = removecats(lmeTbl.Response);
    lmeTbl.Session  = removecats(lmeTbl.Session);
    lmeTbl.Subject  = removecats(lmeTbl.Subject);

    lme = fitlme(lmeTbl, ...
        'Dilation ~ Stimulus*Response*Baseline + (1|Session) + (1|Subject)');
    
    anova(lme)

    keyboard 

end