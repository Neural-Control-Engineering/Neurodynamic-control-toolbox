% script for plotting physiology data based on states identified by glm-hmm
% Craig Kelley, NEC Lab, 8/25/23

data = filterTrials(Datastore.NE_dstore, 'recording_location', 'mPFC-S1');
animals = fetchAnimals(data);
data(cellfun(@isempty, data.photometry_ch1),:) = [];
ssd_version = 'v2';
kstates = [2, 3, 4, 5, 6];
data_versions = {'last_trial_behavior_no_bias', ... 
    'spontaneous_mpfc_s1_pupil_normalized', ... 
    'last_trial_behavior_drop_stim_no_bias', ...
    'behavior_pupil_mpfc_s1_combo', ... 
    'behavior_pupil_mpfc_combo', ... 
    'behavior_pupil_s1_combo', ...
    'spontaneous_mpfc_s1_pupil_drop_stim', ...
    'behavior_mpfc_s1_combo', ...
    'behavior_mpfc_combo', ...
    'behavior_s1_combo', ...
    'behavior_pupil_combo', ...
    'spontaneous_mpfc_stim', ...
    'spontaneous_s1_stim', ...
    'spontaneous_pupil_stim'};
animals_v1 = [3316, 3258, 3133, 200, 199, 198, 197, 196, 180, 167, 152];
animals_v2 = [240, 241, 242, 243];
animals = animals_v2;

% p = gcp('nocreate');
% if isempty(p)
%     parpool(11)
% end

for dv = 1:length(data_versions)
    data_ver = data_versions{dv};
    fformat = {data_ver, 'state_Python2mat.mat'};
    base_path = sprintf('NT-GLM-HMM/data/%s/%s/unshuffled/results/', ssd_version, data_ver);
    outdir = strcat(base_path, 'figures/phys_by_state/');
    if ~exist(outdir, 'dir')
        mkdir(outdir)
    end
    for a = animals
        tmp = filterTrials(data, 'animal', num2str(a));
        for k = kstates
            filename = sprintf('%s%i_%s_%i%s', base_path, a, fformat{1}, k, fformat{2});
            plot_phys_by_states(filename, tmp, num2str(a), k, outdir)
        end
    end
end

function plot_phys_by_states(filename, data, animal, k, outdir)
    results = load(filename);
    fig = figure('Visible', 'off');
    hold on;
    states = 0:k-1;
    tbounds = [-0.5, 1.0];
    cols = distinguishable_colors(length(states));

    for i = states
        tmp = data(results.predicted_states == i,:);
        if ~isempty(tmp)
            [ch1, ch2, t] = avg_photo_traces(tmp, tbounds);
            % keyboard
            n = size(tmp,1);
            subplot(1,3,1)
            hold on 
            try
                semshade(ch1(:,2:end-1), 0.3, cols(i+1,:), cols(i+1,:), t(2:end-1), 1, sprintf('State %i (n=%i)', i, n));
            catch
                % keyboard
                plot(t, ch1, 'DisplayName', sprintf('State %i (n=%i)', i, n))
            end
            subplot(1,3,2)
            hold on 
            try
                semshade(ch2(:,2:end-1), 0.3, cols(i+1,:), cols(i+1,:), t(2:end-1), 1, sprintf('State %i (n=%i)', i, n));
            catch
                % keyboard
                plot(t, ch2, 'DisplayName', sprintf('State %i (n=%i)', i, n))
            end
            [pupil, t] = avg_pupil_traces(tmp, tbounds);
            % keyboard
            subplot(1,3,3)
            hold on
            try
                semshade(pupil(:,2:end-1), 0.3, cols(i+1, :), cols(i+1, :), t(2:end-1), 1, sprintf('State %i (n=%i)', i, n));
            catch
                % keyboard
                plot(t, pupil, 'DisplayName', sprintf('State %i (n=%i)', i, n));
            end
            ch1_region = tmp.photometry_region_ch1{1,1};
            ch2_region = tmp.photometry_region_ch2{1,1};
        end
    end
    subplot(1,3,1)
    ylabel(sprintf('%s NE', ch1_region))
    legend('location', 'southwest')
    ylims = ylim;
    plot([0,0],[ylims(1), ylims(2)], 'k:')
    subplot(1,3,2)
    ylabel(sprintf('%s NE', ch2_region))
    xlabel('Time (s)')
    plot([0,0],[ylims(1), ylims(2)], 'k:')
    subplot(1,3,3)
    ylabel('Pupil Area')
    plot([0,0],[ylims(1), ylims(2)], 'k:')
    saveas(fig, sprintf('%s%s_%istates.png', outdir, animal,length(states)))
    saveas(fig, sprintf('%s%s_%istates.png', outdir, animal,length(states)))
    saveas(fig, sprintf('%s%s_%istates.png', outdir, animal,length(states)))
    close
end

function [ch1mat, ch2mat, time] = avg_photo_traces(data, tbounds)
    % generates averages of photometry traces 
    Fss = getFs(data, 'photometry_ch1');
    ch1mat = zeros(size(data,1), round(max(Fss)*diff(tbounds)));
    ch2mat = ch1mat;
    starts = data.stimulus_time;
    time = linspace(tbounds(1), tbounds(2), round(max(Fss)*diff(tbounds)));

    for i = 1:size(data,1)
        t = data.photometry_ch1{i,1}(:,1) - starts(i);
        ch1 = data.photometry_ch1{i,1}(:,2);
        ch2 = data.photometry_ch2{i,1}(:,2);
        ch1 = ch1(t > tbounds(1) & t < tbounds(2));
        ch2 = ch2(t > tbounds(1) & t < tbounds(2));
        t = t(t > tbounds(1) & t < tbounds(2));
        % using interp1 to avoid issues with differing sample rates
        ch1mat(i,:) = interp1(t, ch1, time);
        ch2mat(i,:) = interp1(t, ch2, time);
    end
end

function [pupil, time] = avg_pupil_traces(data, tbounds)
    % generates averages of pupil traces
    Fs = 1 / (data.pupil_area{1,1}(2,1)-data.pupil_area{1,1}(1,1));
    pupil = nan(size(data,1), round(Fs*diff(tbounds)));
    starts = data.stimulus_time;
    time = linspace(tbounds(1), tbounds(2), round(Fs*diff(tbounds)));

    for i = 1:size(data,1)
        t = data.pupil_area{i,1}(:,1) - starts(i);
        p = data.pupil_area{i,1}(:,2);
        p = p(t >= tbounds(1) & t <= tbounds(2));
        t = t(t >= tbounds(1) & t <= tbounds(2));
        try
            % again with the sample rate issues
            pupil(i,:) = interp1(t,p,time);
        end
    end
end

