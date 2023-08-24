animals = [3316, 3258, 3133, 200, 199, 198, 197, 196, 180, 167, 152];
% animals = [240, 241, 242, 243];
kstates = [2,3,4,5];
fformat = {'spon_photo_pupil_v2_', 'state_Python2mat.mat'};
results_dir = 'NT-GLM-HMM/results_v1/';
filename = dir(results_dir);
N_folds = 5;
figure('Visible', 'on')
hold on
for a = 1:length(animals)
    mat = nan(N_folds, length(kstates));
    for k = 1:length(kstates)
        fname = sprintf('%s%i_%s%i%s', results_dir, animals(a), fformat{1}, kstates(k), fformat{2});
        tmp = load(fname);
        % for f = 1:length(filename)
        %     if contains(filename(f).name, fname) && contains(filename(f).name, '.mat')
        %         tmp = load(sprintf('%s%s', results_dir, filename(f).name));
        %         break
        %     end
        % end
        mat(:,k) = tmp.accuracy';
    end
    errorbar(kstates+(rand()-0.5)/10, mean(mat), std(mat), 'DisplayName', num2str(animals(a)))
end
xlabel('K States')
ylabel('Prediction Accuracy')
legend('location','southwest')
