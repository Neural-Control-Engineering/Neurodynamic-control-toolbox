function fig4i(data, tbounds, alignTo, ver)
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
        [pfc, ~, t] = avg_photo_traces(stmp, [tbounds(1), tbounds(2)], alignTo, ver);
        pfc = pfc(:,2:end-1);
        t = t(2:end-1);
        b =  nanmean(pfc(:,(t > -0.5 & t < 0)),2);
        % e = nanmean(pfc(:,(t > 0 & t < 2)),2);
        e = max(pfc(:,(t > 0 & t < 2)),[],2);
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
    plot(baselines, dilations, 'o', 'MarkerFaceColor', [0.5,0.5,0.5], 'MarkerEdgeColor', [1,1,1], 'MarkerSize', 3)
    x = baselines;
    y = dilations;
    mdl = fitlm(x, y)
    [FM, S]=polyfit(x(~isnan(x)),y(~isnan(y)),1);
    [FM_vals, delta] = polyval(FM,linspace(min(x),max(x),10), S); 
    hold on; plot(linspace(min(x),max(x),10), FM_vals, 'k--', 'linewidth',2) 
    xlabel('Baseline NE in S1 (z-score)', 'FontSize', 16)
    ylabel('Stimulus Evoked Increase in NE (z-score)', 'FontSize', 16)
    xlim([-2.5,5.1])
    % saveas(fig, 'Figures/fig2e.fig')
    % saveas(fig, 'Figures/fig2e.svg')

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

    x_min = -2; %min(baselines);
    x_max = 5; %max(baselines);
    x = linspace(x_min, x_max, 100)';
    animals = fetchAnimals(data);
    fig = figure(); hold on;
    tl = tiledlayout(2,4);
    for s = 1:length(stim_strengths)
        axs(s) = nexttile;
        hold on 
        ss = stim_strengths(s);
        for r = 0:1
            y = [];
            % tbl = table(x, repmat(ss, size(x)), repmat(r,size(x)), subj', sesh', 'VariableNames', {'Baseline', 'Stimulus', 'Response', 'Subject', 'Session'});
            for a = 1:length(animals)
                sessions = unique(data(contains(data.session_id, strcat(num2str(animals(a)), '-R')),:).session_id);
                for h = 1:length(sessions)
                    subj = {};
                    sesh = {};
                    for i = 1:length(x)
                        subj{i} = sessions{h}(1:3);
                        sesh{i} = sessions{h};
                    end
                    tbl = table(x, repmat(ss, size(x)), repmat(r,size(x)), subj', sesh', 'VariableNames', {'Baseline', 'Stimulus', 'Response', 'Subject', 'Session'});
                    % Make predictors categorical
                    tbl.Baseline = double(tbl.Baseline);
                    tbl.Stimulus = categorical(tbl.Stimulus);
                    tbl.Response = categorical(tbl.Response);
                    tbl.Session  = categorical(tbl.Session);
                    tbl.Subject  = categorical(tbl.Subject);
                    % Remove rows with missing values in any model variable
                    badRows = isundefined(tbl.Stimulus) | ...
                            isnan(tbl.Baseline) | ...
                            isundefined(tbl.Response) | ...
                            isundefined(tbl.Subject) | ...
                            isundefined(tbl.Session);
                    tbl(badRows,:) = [];
                    % Optional but useful: remove unused category levels
                    tbl.Stimulus = removecats(tbl.Stimulus);
                    tbl.Response = removecats(tbl.Response);
                    tbl.Session  = removecats(tbl.Session);
                    tbl.Subject  = removecats(tbl.Subject);
                    y = [y; predict(lme, tbl)'];
                end
            end
            if r
                % semshade(y, 0.3, cols(s,:), cols(s,:), x, 1, '', '-');
                % plot(baselines(responses == r & stimuli == ss), dilations(responses == r & stimuli == ss), 'o', 'Color', cols(s,:))
                plot(x, mean(y), '-', 'Color', cols(s,:), 'LineWidth', 2)
            else
                % semshade(y, 0.3, cols(s,:), cols(s,:), x, 1, '', '--');
                % plot(baselines(responses == r & stimuli == ss), dilations(responses == r & stimuli == ss), 'x', 'Color', cols(s,:))
                plot(x, mean(y), ':', 'Color', cols(s,:), 'LineWidth', 2)
            end
        end
        xlim([-2,5])
    end
 

end