function plot_phys_by_states(filename, data, animal, outdir)
% script for plotting physiology data based on states identified by glm-hmm
% Craig Kelley, NEC Lab, 8/25/23

    results = load(filename);
    fig = figure('Visible', 'off');
    hold on;
    cols = ['b', 'r', 'g', 'c', 'y'];
    states = unique(results.predicted_states);
    tbounds = [-0.5, 1.0];

    for i = states
        tmp = data(results.predicted_states == i,:);
        [ch1, ch2, t] = avg_photo_traces(tmp, tbounds);
        n = size(tmp,1);
        subplot(1,3,1)
        hold on 
        try
            semshade(ch1, 0.3, cols(i+1), cols(i+1), t, 1, sprintf('State %i (n=%i)', i, n));
        catch
            plot(t, ch1, 'DisplayName', sprintf('State %i (n=%i)', i, n))
        end
        subplot(1,3,2)
        hold on 
        try
            semshade(ch2, 0.3, cols(i+1), cols(i+1), t, 1, sprintf('State %i (n=%i)', i, n));
        catch
            plot(t, ch2, 'DisplayName', sprintf('State %i (n=%i)', i, n))
        end
        [pupil, t] = avg_pupil_traces(tmp, tbounds);
        subplot(1,3,3)
        hold on
        try
            semshade(pupil, 0.3, cols(i+1), cols(i+1), t, 1, sprintf('State %i (n=%i)', i, n));
        catch
            plot(t, pupil, 'DisplayName', sprintf('State %i (n=%i)', i, n));
        end
    end
    subplot(1,3,1)
    ylabel(sprintf('%s NE', tmp.photometry_region_ch1{1,1}))
    legend('location', 'southwest')
    ylims = ylim;
    plot([0,0],[ylims(1), ylims(2)], 'k:')
    subplot(1,3,2)
    ylabel(tmp.photometry_region_ch2{1,1})
    xlabel('Time (s)')
    plot([0,0],[ylims(1), ylims(2)], 'k:')
    subplot(1,3,3)
    ylabel('Pupil Area')
    plot([0,0],[ylims(1), ylims(2)], 'k:')
    saveas(fig, sprintf('%s%s_%istates.png', outdir, animal,length(states)))
end

function [ch1mat, ch2mat, t] = avg_photo_traces(data, tbounds)
    Fss = getFs(data, 'photometry_ch1');
    ch1mat = zeros(size(data,1), round(max(Fss)*diff(tbounds)));
    ch2mat = ch1mat;
    starts = data.stimulus_time;

    for i = 1:size(data,1)
        if Fss(i) == max(Fss)
            ch1 = data.photometry_ch1{i,1}(:,2);
            ch2 = data.photometry_ch2{i,1}(:,2);
            % just two seconds prior to stimulus 
            t = data.photometry_ch1{i,1}(:,1) - starts(i);
            ch1 = ch1(t > tbounds(1) & t < tbounds(2));
            ch2 = ch2(t > tbounds(1) & t < tbounds(2));
            t = t(t > tbounds(1) & t < tbounds(2));
            ch1mat(i,:) = ch1;
            ch2mat(i,:) = ch2;
        else
            ch1mat(i,:) = nan(1,size(ch1mat,2));
            ch2mat(i,:) = nan(1,size(ch2mat,2));
        end
    end
end

function [pupil, time] = avg_pupil_traces(data, tbounds)
    Fs = 1 / (data.pupil_area{1,1}(2,1)-data.pupil_area{1,1}(1,1));
    pupil = zeros(size(data,1), round(Fs*diff(tbounds)));
    starts = data.stimulus_time;
    time = linspace(tbounds(1), tbounds(2), round(Fs*diff(tbounds)));

    for i = 1:size(data,1)
        t = data.pupil_area{i,1}(:,1) - starts(i);
        p = data.pupil_area{i,1}(:,2);
        p = p(t >= tbounds(1) & t <= tbounds(2));
        t = t(t >= tbounds(1) & t <= tbounds(2));
        pupil(i,:) = interp1(t,p,time);
    end
end