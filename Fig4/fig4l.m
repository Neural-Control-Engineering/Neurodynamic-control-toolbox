function out = fig4l(data, ver)

    [mpfc, ~, ~] = avg_photo_traces(data, [-0.5, 0], 'stimulus', ver);
    baselines = nanmean(mpfc,2);

    % ptiles = 25:25:100;
    % ptiles = [33, 66, 100];
    ptiles = [20,40,60,80,100];
    low = prctile(baselines, 0);
    stim_strengths = unique(data.stimulus_strength);
    cols = distinguishable_colors(5);
    fig = figure();
    out = {};
    for i = 1:length(ptiles)
        ptile = ptiles(i);
        high = prctile(baselines, ptile);
        x = baselines >= low & baselines <= high;
        low = high;
        tmp = data(x,:);
        stim_strengths = unique(tmp.stimulus_strength);
        sessions = unique(tmp.session_id);
        animals = fetchAnimals(tmp);
        mat = nan(length(sessions), length(stim_strengths));
        for s = 1:length(sessions)
            stmp = filterTrials(tmp, 'session_id', num2str(sessions(s)));
            sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(1));
            fatmp = filterTrials(sstmp, 'categorical_outcome', 'FA');
            mat(s,1) = size(fatmp,1) / size(sstmp,1);
        % mat = nan(length(animals), length(stim_strengths));
        % for s = 1:length(animals)
        %     stmp = filterTrials(tmp, 'animal', num2str(animals(s)));
        %     sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(1));
        %     fatmp = filterTrials(sstmp, 'categorical_outcome', 'FA');
        %     mat(s,1) = size(fatmp,1) / size(sstmp,1);
            for ss = 2:length(stim_strengths)
                sstmp = filterTrials(stmp, 'stim_strength', stim_strengths(ss));
                otmp = filterTrials(sstmp, 'categorical_outcome', 'Hit');
                hr = size(otmp,1) / size(sstmp,1);
                if length(unique(stmp.stimulus_strength)) == 2
                    mat(s,end) = hr;
                else
                    mat(s, ss) = hr;
                end
            end
        end
        % mat = nan(size(tmp,1), length(stim_strengths));
        % for trial = 1:size(tmp,1)
        %     ind = find(stim_strengths == tmp.stimulus_strength(trial));
        %     if strcmp(tmp.categorical_outcome{trial}, 'Hit') || strcmp(tmp.categorical_outcome{trial}, 'CR')
        %         mat(trial, ind) = 1;
        %     else
        %         mat(trial, ind) = 0;
        %     end
        % end
        switch i 
            case 1  
                l = sprintf('Low', i);
            case 2
                l = sprintf('Medium', i);
            case 3
                l = sprintf('High', i);
            otherwise
                l = sprintf('%ith quartile', i);
        end
        n = size(mat,1);
        semshade(mat, 0.3, cols(i,:), cols(i,:), stim_strengths .* 10, 1, sprintf('%s (n=%i)', l, n));
        hold on
        out{i} = mat;
    end
    xlabel('Stimulus Strength (PSI)', 'FontSize', 14)
    ylabel('Response Probability', 'FontSize', 14)
    leg = legend('location', 'southeast');
    leg.Title.String = 'Baseline NE_{mPFC}';

    rppa_session = out;
    % terciles = [zeros(49,1); zeros(49,1)+1; zeros(49,1)+2; zeros(49,1)+3; zeros(49,1)+4];
    terciles = [];
    mat = [];
    for i = 1:length(rppa_session)
        terciles = [terciles; zeros(size(rppa_session{i},1),1)+i-1];
        mat = [mat; rppa_session{i}];
    end
    stim_strengths = stim_strengths .* 10;
    % mat = [rppa_session{1}; rppa_session{2}; rppa_session{3}; rppa_session{4}; rppa_session{5}];
    tbl = table(terciles, mat(:,1), mat(:,2), mat(:,3), mat(:,4), mat(:,5), mat(:,6), mat(:,7), 'VariableNames', {'tercile', 't0', 't1', 't2', 't3', 't4', 't5', 't6'});
    rm = fitrm(tbl, 't0-t6 ~ tercile', 'WithinDesign', stim_strengths);
    ranova(rm)

    saveas(fig, 'Figures/fig4l.fig')
    saveas(fig, 'Figures/fig4l.svg')
end