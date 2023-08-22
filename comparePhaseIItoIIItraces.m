function fig = comparePhaseIItoIIItraces(Datastore)
    data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
    data = filterTrials(data, 'categorical_outcome', 'Hit');
    phases = {'Phase II', 'Phase III'};
    tbounds = [-0.5, 1.0];
    colors = ['b', 'r'];
    fig = figure('Visible', 'on');
    hold on;
    for p = 1:length(phases)
        tmp = filterTrials(data, 'phase', phases{p});
        Fss = getFs(tmp);
        ch1mat = nan(size(tmp,1), round(max(Fss)*diff(tbounds)));
        ch2mat = ch1mat;
        starts = tmp.stimulus_time;
        for i = 1:size(tmp,1)
            if Fss(i) == max(Fss)
                ch1 = tmp.photometry_ch1{i,1}(:,2);
                ch2 = tmp.photometry_ch2{i,1}(:,2);
                % just two seconds prior to stimulus 
                t = tmp.photometry_ch1{i,1}(:,1) - starts(i);
                ch1 = ch1(t > tbounds(1) & t < tbounds(2));
                ch2 = ch2(t > tbounds(1) & t < tbounds(2));
                t = t(t > tbounds(1) & t < tbounds(2));
                ch1mat(i,:) = ch1;
                ch2mat(i,:) = ch2;
            end
        end
        label = sprintf('%s: (n=%i)', phases{p}, size(ch1mat,1));
        subplot(2,1,1)
        hold on
        semshade(ch1mat, 0.3, colors(p), colors(p), t, [], label);
        subplot(2,1,2)
        hold on
        semshade(ch2mat, 0.3, colors(p), colors(p), t, [], label);
    end
    subplot(2,1,1)
    title(data.photometry_region_ch1{1,1})
    ylabel('NE')
    ylim([-1,2])
    subplot(2,1,2)
    title(data.photometry_region_ch2{1,1})
    ylabel('NE')
    xlabel('Time (s)')
    ylim([-1,2])
    legend()
end

