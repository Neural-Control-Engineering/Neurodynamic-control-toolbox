
% Datastore = load('Combined-Datastore_created_14-Jan-2024.mat');
% data = filterTrials(Datastore.Datastore, 'recording_location', 'mPFC-S1');
% animals = fetchAnimals(data);
% model = readtable('glmhmm_K3_state_assignments.csv');
% model = model(strcmp(model.model, 'New'),:);
% model(cellfun(@isempty, data.photometry_ch1),:) = [];
% data(cellfun(@isempty, data.photometry_ch1),:) = [];
% sessions = unique(data.session_id);
out = {[],[],[]};
tbounds = [-4.0, 0.0];
alignTo = 'stimulus';
cols = distinguishable_colors(3);
for s = 1:length(sessions)
    tmp_model = model(strcmp(model.session, sessions{s}),:);
    tmp_data = data(strcmp(model.session, sessions{s}),:);
    states = unique(tmp_model.state);
    for ss = 1:length(states)
        tmp = tmp_data(tmp_model.state == states(ss),:);
        if ~isempty(tmp)
            [mpfc, s1, t] = avg_photo_traces(tmp, tbounds, 'stimulus', ver);
            Fs = getFs(tmp, 'photometry_ch1');
            Fs = Fs(1);
            cs = zeros(size(tmp,1), 957); %length([tbounds(1):(1/Fs):tbounds(2)])*2-7);
            lags = zeros(size(tmp,1), 957); %length([tbounds(1):(1/Fs):tbounds(2)])*2-7);
            for i = 1:size(mpfc,1)
                ch1 = mpfc(i,:);
                ch2 = s1(i,:);
                % mpfc x s1 
                [c, lag] = xcorr(ch1(2:end-1), ch2(2:end-1), 'normalized');
                if length(c) == 959
                    lags(i,:) = lag(2:end-1) ./ Fs;
                    cs(i,:) = c(2:end-1); % ./ length(ch1(2:end-1));
                else
                    lags(i,:) = lag ./ Fs;
                    cs(i,:) = c; % ./ length(ch1(2:end-1));
                end
            end
            if size(cs,1) > 1
                % try
                out{states(ss)+1} = [out{states(ss)+1}; nanmean(cs)];
                % end
            else
                out{states(ss)+1} = [out{states(ss)+1}; cs];
            end
        end
    end
end
fig = figure(); hold on;
for s = 1:3 
    semshade(out{s} - nanmean(shuff), 0.3, cols(s,:), cols(s,:), lags(1,:), 1);
end
xlabel('Lag (s)', 'FontSize', 16)
ylabel('Shuffle Corrected Cross Correlation', 'FontSize', 16)

mat = [];
state = [];
for i = 1:length(out)
    mat = [mat; out{i}];
    state = [state; repmat(i-1, size(out{i},1), 1)];
end 
tbl = table(state, mat(:,1), 'VariableNames', {'state', 't0'});
for c = 2:size(mat,2)
    tbl = [tbl, table(mat(:,c), 'VariableNames', {sprintf('t%i',c-1)})];
end
rm = fitrm(tbl, sprintf('t0-t%i ~ state',c-1), 'WithinDesign', lags(1,:));
ranova(rm)