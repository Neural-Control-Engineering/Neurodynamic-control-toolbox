function suppFig4a(data, tbounds, alignTo, ver)
    ptiles = [20,40,60,80,100];
    low = prctile(data.pupil_base_before_stimulus, 0);
    cols = distinguishable_colors(length(ptiles));
    s1_baseline = {};
    pfc_baseline = {};
    sesh = {};
    for i = 1:length(ptiles)
        ptile = ptiles(i);
        high = prctile(data.pupil_base_before_stimulus, ptile);
        x = data.pupil_base_before_stimulus >= low & data.pupil_base_before_stimulus <= high;
        low = high;
        tmp = data(x,:);
        [pfc, s1, ~] = avg_photo_traces(tmp, [-0.5, 0], 'stimulus', ver);
        s1_baseline{i} = nanmean(s1,2);
        pfc_baseline{i} = nanmean(pfc,2);
        sesh{i} = tmp.session_id;
    end

    session = vertcat(sesh{1}, sesh{2}, sesh{3}, sesh{4}, sesh{5});
    s1 = vertcat(s1_baseline{1}, s1_baseline{2}, s1_baseline{3}, s1_baseline{4}, s1_baseline{5});
    pfc = vertcat(pfc_baseline{1}, pfc_baseline{2}, pfc_baseline{3}, pfc_baseline{4}, pfc_baseline{5});
    ptiles = vertcat(zeros(size(pfc_baseline{1}))+1, zeros(size(pfc_baseline{2}))+2, zeros(size(pfc_baseline{3}))+3, zeros(size(pfc_baseline{4}))+4, zeros(size(pfc_baseline{5}))+5);
    subject = {};
    for i = 1:length(session)
        subject{i} = session{i}(1:3);
    end

    fig = figure();
    scatter(s1, pfc, 'MarkerFaceColor', [0.5,0.5,0.5], 'MarkerEdgeColor', [1,1,1])
    x = s1;
    y = pfc;
    [FM, S]=polyfit(x(~isnan(x)),y(~isnan(y)),1);
    [FM_vals, delta] = polyval(FM,linspace(min(x),max(x),10), S); 
    hold on; plot(linspace(min(x),max(x),10), FM_vals, 'k--', 'linewidth',2) 
    xlabel('Baseline S1 (z-score)', 'FontSize', 16)
    ylabel('Baseline PFC (z-score)', 'FontSize', 16)    

    T = table(pfc, s1, session, subject',  'VariableNames', {'PFC', 'S1', 'Session', 'Subject'});

    lmeTbl = T(:, {'PFC', 'S1', 'Session', 'Subject'});

    % Make sure response is numeric
    lmeTbl.PFC = double(lmeTbl.PFC);

    % Make predictors categorical
    lmeTbl.S1 = double(lmeTbl.S1);
    lmeTbl.Session  = categorical(lmeTbl.Session);
    lmeTbl.Subject  = categorical(lmeTbl.Subject);
    % lmeTbl.Outcome  = categorical(lmeTbl.Outcome);

    % Remove rows with missing values in any model variable
    badRows = isnan(lmeTbl.PFC) | ...
            isnan(lmeTbl.S1) | ...
            isundefined(lmeTbl.Subject) | ...
            isundefined(lmeTbl.Session);

    lmeTbl(badRows,:) = [];

    % Optional but useful: remove unused category levels
    lmeTbl.Session  = removecats(lmeTbl.Session);
    lmeTbl.Subject  = removecats(lmeTbl.Subject);
    % lmeTbl.Ptile  = removecats(lmeTbl.Ptile);

    fprintf('Baseline PFC NE by Baseline S1 NE LME\n')
    lme = fitlme(lmeTbl, ...
        'PFC ~ S1 + (1|Session) + (1|Subject)')
    anova(lme)

    saveas(fig, 'Figures/suppFig4a.fig')
    saveas(fig, 'Figures/suppFig4a.svg')

end