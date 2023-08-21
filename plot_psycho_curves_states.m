% script for plotting psychometric curves based on states identified by glm-hmm
% Craig Kelley, NEC Lab, 8/21/23

% load('NT-GLM-HMM/results/all_mpfc_s1_glmhmm_spontaneous_Python2mat2023-08-21-101138.mat')
% load ('NT-GLM-HMM/results/all_mpfc_s1_glmhmm_spontaneous_4state_Python2mat2023-08-21-105220.mat')
% load('NT-GLM-HMM/results/all_mpfc_s1_glmhmm_spontaneous_5state_Python2mat2023-08-21-122631.mat')
load('NT-GLM-HMM/results/all_mpfc_s1_glmhmm_beforeStim_3state_Python2mat2023-08-21-133906.mat')

fig = figure('Visible', 'on');
hold on;

strengths = [0, 0.2, 0.5, 1, 2, 4];
cols = ['b', 'r', 'g', 'c', 'y'];
for i = [0,1,2]
    tmp = data(find(predicted_states == i),:);
    sessions = unique(tmp.session_id);
    mat = nan(size(sessions,1), length(strengths));
    for sesh = 1:length(sessions)
        session = filterTrials(tmp, 'session_id', sessions{sesh});
        for j = 1:size(session.pscho_curve{1,1},2)
            ind = find(strengths == session.pscho_curve{1,1}(1,j));
            mat(sesh, ind) = session.pscho_curve{1,1}(2,j);
        end
    end
    % n = size(tmp,1);
    n = length(sessions);
    semshade(mat, 0.3, cols(i+1), cols(i+1), strengths, 1, sprintf('State %i (n=%i)', i, n));
end

legend('location','southeast')
xlabel('Stimulus Strength (PSI)')
ylabel('Accuracy')