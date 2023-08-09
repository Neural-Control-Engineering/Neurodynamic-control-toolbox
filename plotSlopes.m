function plotSlopes(data, sortBy, t0, t1, outdir)
% compute slope of photometery data between times t0 and t1 by fitting a
% line.  choose to sort by categorical outcome or animal response 
% Craig Kelley, NEC Lab, 8/9/23

    data = swapPhotometryChannels(data);
    fig = figure('Visible', 'off'); hold on;
    colors = ['b', 'r', 'm', 'g', 'y', 'c'];
    
    if strcmp(sortBy, 'outcome')
        outcome_types = unique(data.categorical_outcome);
        filterBy = 'categorical_outcome';
    elseif strcmp(sortBy, 'response')
        outcome_types = [1,0];
        filterBy = 'go-nogo';
    end
    
    responses = {'go', 'no go'};
    
    for out_i = 1:length(outcome_types)
        outcome = outcome_types(out_i);
        if iscell(outcome)
            obj = filterTrials(data, filterBy, outcome{1});
        else
            obj = filterTrials(data, filterBy, outcome);
        end
        if ~isempty(obj)
            slopes = zeros(2,size(obj,1));
            for i = 1:size(obj,1)
                ch1 = obj.photometry_ch1{i,1}(:,2);
                ch2 = obj.photometry_ch2{i,1}(:,2);
                % just two seconds prior to stimulus 
                t = obj.photometry_ch1{i,1}(:,1) - obj.stimulus_time(i);
                ch1 = ch1(t < t1 & t > t0);
                ch2 = ch2(t < t1 & t > t0);
                t = t(t < t1 & t > t0);
                [p1, ~] = polyfit(t, ch1, 1);
                [p2, ~] = polyfit(t, ch2, 1);
                slopes(1,i) = p1(1);
                slopes(2,i) = p2(1);
            end
            if strcmp(sortBy, 'outcome')
                subplot(2,1,1); hold on;
                scatter(ones(1,size(obj,1))+out_i, slopes(1,:), 15, colors(out_i), "filled", 'jitter', 'on', 'DisplayName', outcome)
                subplot(2,1,2); hold on;
                scatter(ones(1,size(obj,1))+out_i, slopes(2,:), 15, colors(out_i), "filled", 'jitter', 'on', 'DisplayName', outcome)
            elseif strcmp(sortBy, 'response')
                subplot(2,1,1); hold on;
                scatter(ones(1,size(obj,1))+out_i, slopes(1,:), 15, colors(out_i), "filled", 'jitter', 'on', 'DisplayName', responses{out_i})
                subplot(2,1,2); hold on;
                scatter(ones(1,size(obj,1))+out_i, slopes(2,:), 15, colors(out_i), "filled", 'jitter', 'on', 'DisplayName', responses{out_i})
            end
        end
    end
    
    subplot(2,1,1)
    n = strsplit(data.session_id(1), '-');
    animal = n(1);
    t = sprintf('%s - %s', animal, data.photometry_region_ch1{1});
    title(t)
    subplot(2,1,2)
    t = sprintf('%s - %s', animal, data.photometry_region_ch2{1});
    title(t)
    xlim([0.5, 7.5])
    
    if strcmp(sortBy, 'outcome')
        subplot(2,1,1)
        xlim([0.5, 7.5])
        subplot(2,1,2)
        xlim([0.5, 7.5])
    else
        subplot(2,1,1)
        xlim([1.5,3.5])
        subplot(2,1,2)
        xlim([1.5,3.5])
    end
    legend()
    if ~exist(outdir, 'dir')
        mkdir(outdir)
    end
    fname = sprintf('%s%s.png', outdir, animal);
    saveas(fig, fname)
    close()

end