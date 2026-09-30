function suppFig4a(data, tbounds, alignTo, ver)
    ptiles = [20,40,60,80,100];
    [pupil, t] = avg_pupil_traces(data, [tbounds(1)-0.1, tbounds(2)+0.1], alignTo);
    pupil = pupil(:,2:end-1);
    t = t(2:end-1);
    b =  nanmean(pupil(:,(t > -0.5 & t < 0)),2);
    e = max(pupil(:,(t > 0 & t < 6)),[],2);
    dilations = e - b;
    low = prctile(dilations, 0);
    cols = distinguishable_colors(length(ptiles));
    s1_baseline = {};
    pfc_baseline = {};
    sesh = {};
    for i = 1:length(ptiles)
        ptile = ptiles(i);
        high = prctile(dilations, ptile);
        x = dilations >= low & dilations <= high;
        low = high;
        tmp = data(x,:);
        [pfc, s1, t] = avg_photo_traces(tmp, [tbounds(1), tbounds(2)], alignTo, ver);
        pfc = pfc(:,2:end-1);
        t = t(2:end-1);
        b =  nanmean(pfc(:,(t > -0.5 & t < 0)),2);
        e = max(pfc(:,(t > 0 & t < 2)),[],2);
        d = e - b;
        pfc_baseline{i} = d;
        pfc = pfc(:,2:end-1);
        t = t(2:end-1);
        b =  nanmean(pfc(:,(t > -0.5 & t < 0)),2);
        e = max(pfc(:,(t > 0 & t < 2)),[],2);
        d = e - b;
        s1_baseline{i} = nanmean(s1,2);
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
    xlabel('\Delta S1 (z-score)', 'FontSize', 16, 'Interpreter', 'tex')
    ylabel('\Delta PFC (z-score)', 'FontSize', 16, 'Interpreter', 'tex')    

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

    fprintf('Delta PFC NE by Delta S1 NE\n')
    lme = fitlme(lmeTbl, ...
        'PFC ~ S1 + (1|Session) + (1|Subject)')
    anova(lme)

    saveas(fig, 'Figures/suppFig4b.fig')
    saveas(fig, 'Figures/suppFig4b.svg')

end