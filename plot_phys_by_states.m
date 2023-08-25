function plot_phys_by_states(filename, data, animal, outdir)
% script for plotting psychometric curves based on states identified by glm-hmm
% Craig Kelley, NEC Lab, 8/21/23

    % load('NT-GLM-HMM/results/3133_spon_photo_pupil_v2_2state_Python2mat_2023-08-24-100620.mat')
    results = load(filename);
    fig = figure('Visible', 'off');
    hold on;

    strengths = [0, 0.2, 0.5, 1, 2, 4];
    % strengths = [0, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0];
    cols = ['b', 'r', 'g', 'c', 'y'];
    states = unique(results.predicted_states);
    tbounds = [-0.5, 1.0];

    for i = states
        tmp = data(results.predicted_states == i,:);
        [ch1, ch2, t] = avg_photo_traces(tmp, tbounds);
        n = length(sessions);
        % semshade(mat(:,2:end), 0.3, cols(i+1), cols(i+1), strengths(2:end), 1, sprintf('State %i (n=%i)', i, n));
        try
            semshade(mat(:,2:end), 0.3, cols(i+1), cols(i+1), strengths(2:end), 1, sprintf('State %i (n=%i)', i, n));
        catch
            plot(strengths(2:end), mat(2:end), 'DisplayName', sprintf('State %i (n=%i)', i, n))
        end
        hold on
    end
    xlabel('Stimulus Strength (x10 PSI)')
    ylabel('Performance')
    legend()

    legend('location','southeast')
    xlabel('Stimulus Strength (PSI)')
    ylabel('Accuracy')
    title(sprintf('%s - GLM-HMM Accuracy: %f.3', animal, mean(results.accuracy)))
    ylim([0,1.05])
    saveas(fig, sprintf('%s%s_%istates.png', outdir, animal,length(states)))
end

function [ch1mat, ch2mat, t] = avg_photo_traces(data, tbounds)
    Fss = getFs(data);
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

function [pupil, t] = avg_pupil_traces(data, tbounds)
    Fs = 1 / (data.pupil_area{1,1}(2,1)-data.pupil_area{1,1}(1,1));
    pupil = zeros(size(data,1), round(Fs*diff(tboudns)));
    starts = data.stimulus_time;

    for i = 1:size(data,1)
        t = data.pupil_area{i,1}(:,1) - starts(i);
        pupil = data.pupil_area{i,1}(:,2);
        pupil = pupil(t > tbounds(1) & t < tbounds(2));
        t = t(t > tbounds(1) & t < tbounds(2));
    end
end


% for i = [0,1,2]
%     tmp = data(find(results.predicted_states == i),:);
%     sessions = unique(tmp.session_id);
%     mat = nan(size(sessions,1), length(strengths));
%     for sesh = 1:length(sessions)
%         session = filterTrials(tmp, 'session_id', sessions{sesh});
%         for j = 1:size(session.pscho_curve{1,1},2)
%             ind = find(strengths == session.pscho_curve{1,1}(1,j));
%             mat(sesh, ind) = session.pscho_curve{1,1}(2,j);
%         end
%     end
%     % n = size(tmp,1);
%     n = length(sessions);
%     semshade(mat, 0.3, cols(i+1), cols(i+1), strengths, 1, sprintf('State %i (n=%i)', i, n));
% end

% for i = [0,1,2]
%     tmp = data(results.predicted_states == i,:);
%     mat = nan(size(tmp,1), length(strengths));
%     for trial = 1:size(tmp,1)
%         ind = find(strengths == tmp.stimulus_strength(trial));
%         if strcmp(tmp.categorical_outcome{trial}, 'Hit') || strcmp(tmp.categorical_outcome{trial}, 'CR')
%             mat(trial, ind) = 1;
%         else
%             mat(trial, ind) = 0;
%         end
%     end
%     plot(strengths, nansum(mat,1) ./ sum(~isnan(mat),1),'*-')
%     hold on
% end

% label = sprintf('%s (n=%i)', outcome, size(ch1mat,1));
% if size(ch1mat,1) > 1
%     subplot(2,1,1)
%     hold on
%     semshade(ch1mat, 0.3, colors(out_i), colors(out_i), t, [], label);
%     subplot(2,1,2)
%     hold on
%     semshade(ch2mat, 0.3, colors(out_i), colors(out_i), t, [], label);
% else
%     subplot(2,1,1)
%     hold on
%     plot(t, ch1mat, colors(out_i), 'DisplayName', label)
%     subplot(2,1,2)
%     hold on
%     plot(t, ch2mat, colors(out_i), 'DisplayName', label)
% end