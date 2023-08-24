function plot_psycho_curves_states(filename, data, animal, outdir)
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

    for i = states
        tmp = data(results.predicted_states == i,:);
        sessions = unique(tmp.session_id);
        mat = nan(size(sessions,1), length(strengths));
        for sesh = 1:length(sessions)
            session = filterTrials(tmp, 'session_id', sessions{sesh});
            sesh_mat = nan(size(session,1), length(strengths));
            for trial = 1:size(session,1)
                ind = find(strengths == session.stimulus_strength(trial));
                if strcmp(session.categorical_outcome{trial}, 'Hit') || strcmp(session.categorical_outcome{trial}, 'CR')
                    sesh_mat(trial, ind) = 1;
                else
                    sesh_mat(trial, ind) = 0;
                end
            end
            mat(sesh,:) = nansum(sesh_mat,1) ./ sum(~isnan(sesh_mat),1);
        end
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