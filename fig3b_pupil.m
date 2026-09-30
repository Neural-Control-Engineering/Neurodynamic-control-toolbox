function results = fig3b_pupil(data, ver, baselineOrTask)
%FIG3B_PUPIL Cross-correlate mPFC and S1 photometry with pupil.
%
%   results = fig3b_pupil(data, ver)
%
% This is a pupil-based counterpart to fig3b.m. For each session it:
%   1) extracts mPFC/S1 photometry and pupil traces over the same window,
%   2) interpolates (downsamples) mPFC and S1 onto the pupil time base,
%   3) computes trial-wise normalized cross-correlations:
%          mPFC x pupil
%          S1   x pupil
%   4) averages the trial cross-correlations within each session,
%   5) builds shuffled controls using the same circular-shift strategy as
%      fig3b.m (random shift between 25% and 75% of the neural trace),
%   6) subtracts the mean shuffled cross-correlation from each session.
%
% Assumptions:
%   avg_photo_traces(tmp, tbounds, alignTo, ver) returns [mpfc, s1, t]
%   avg_pupil_traces(tmp, tbounds, alignTo)      returns [p, pt]
%
% Positive/negative lag convention follows MATLAB xcorr(x,y).

    sessions = unique(data.session_id);

    if strcmp(baselineOrTask, 'baseline')
        tbounds = [-4.0, 0];
    else
        tbounds = [0, 4.0];
    end
    alignTo = 'stimulus';
    nShuffles = 1000;

    session_xcor_mpfc_pupil = [];
    session_xcor_s1_pupil   = [];

    %% Real session cross-correlations
    for s = 1:length(sessions)
        tmp = filterTrials(data, 'session_id', num2str(sessions(s)));

        [mpfc, s1, t] = avg_photo_traces(tmp, tbounds, alignTo, ver);
        [p, pt] = avg_pupil_traces(tmp, tbounds, alignTo);

        [mpfc_ds, s1_ds, pupil, pupil_t] = ...
            putOnPupilTimebase(mpfc, s1, t, p, pt);

        Fs_pupil = 1 / median(diff(pupil_t), 'omitnan');

        cs_mpfc = nan(size(pupil,1), 2*(size(pupil,2)-2)-1);
        cs_s1   = nan(size(pupil,1), 2*(size(pupil,2)-2)-1);

        for i = 1:size(pupil,1)
            ch_mpfc = mpfc_ds(i,2:end-1);
            ch_s1   = s1_ds(i,2:end-1);
            ch_pup  = pupil(i,2:end-1);

            if all(isfinite(ch_mpfc)) && all(isfinite(ch_pup))
                cs_mpfc(i,:) = xcorr(ch_pup, ch_mpfc, 'normalized');
            end

            if all(isfinite(ch_s1)) && all(isfinite(ch_pup))
                cs_s1(i,:) = xcorr(ch_pup, ch_s1, 'normalized');
            end
        end

        session_xcor_mpfc_pupil = [session_xcor_mpfc_pupil; ...
                                   mean(cs_mpfc, 1, 'omitnan')];
        session_xcor_s1_pupil   = [session_xcor_s1_pupil; ...
                                   mean(cs_s1, 1, 'omitnan')];
    end

    lagSamples = -(size(pupil,2)-3):(size(pupil,2)-3);
    session_lags = lagSamples ./ Fs_pupil;

    %% Shuffled cross-correlations
    shuff_xcor_mpfc_pupil = [];
    shuff_xcor_s1_pupil   = [];

    for ii = 1:nShuffles
        s = randi(length(sessions));
        tmp = filterTrials(data, 'session_id', num2str(sessions(s)));

        [mpfc, s1, t] = avg_photo_traces(tmp, tbounds, alignTo, ver);
        [p, pt] = avg_pupil_traces(tmp, tbounds, alignTo);

        [mpfc_ds, s1_ds, pupil, pupil_t] = ...
            putOnPupilTimebase(mpfc, s1, t, p, pt);

        Fs_pupil_this = 1 / median(diff(pupil_t), 'omitnan');

        cs_mpfc = nan(size(pupil,1), 2*(size(pupil,2)-2)-1);
        cs_s1   = nan(size(pupil,1), 2*(size(pupil,2)-2)-1);

        for i = 1:size(pupil,1)
            ch_mpfc = mpfc_ds(i,:);
            ch_s1   = s1_ds(i,:);
            ch_pup  = pupil(i,:);

            % Same shuffle logic as fig3b.m: circularly shift the first
            % signal by a random amount between 25% and 75% of its length.
            x = randi([round(length(ch_mpfc)*0.25), ...
                       round(length(ch_mpfc)*0.75)]);

            ch_mpfc = [ch_mpfc(x:end), ch_mpfc(1:x-1)];
            ch_s1   = [ch_s1(x:end),   ch_s1(1:x-1)];

            ch_mpfc = ch_mpfc(2:end-1)-mean(ch_mpfc);
            ch_s1   = ch_s1(2:end-1)-mean(ch_s1);
            ch_pup  = ch_pup(2:end-1)-mean(ch_pup);

            if all(isfinite(ch_mpfc)) && all(isfinite(ch_pup))
                cs_mpfc(i,:) = xcorr(ch_pup, ch_mpfc, 'normalized');
            end

            if all(isfinite(ch_s1)) && all(isfinite(ch_pup))
                cs_s1(i,:) = xcorr(ch_pup, ch_s1, 'normalized');
            end
        end

        shuff_xcor_mpfc_pupil = [shuff_xcor_mpfc_pupil; ...
                                 mean(cs_mpfc, 1, 'omitnan')];
        shuff_xcor_s1_pupil   = [shuff_xcor_s1_pupil; ...
                                 mean(cs_s1, 1, 'omitnan')];
    end

    % Guard against sessions having a different pupil sampling grid.
    if abs(Fs_pupil_this - Fs_pupil) > 1e-6
        warning('Pupil sampling rate differed across sampled sessions.');
    end

    %% Shuffle correction
    shuffleMean_mpfc = mean(shuff_xcor_mpfc_pupil, 1, 'omitnan');
    shuffleMean_s1   = mean(shuff_xcor_s1_pupil,   1, 'omitnan');

    session_xcor_mpfc_pupil_corrected = ...
        session_xcor_mpfc_pupil - shuffleMean_mpfc;

    session_xcor_s1_pupil_corrected = ...
        session_xcor_s1_pupil - shuffleMean_s1;

    %% Plot: mPFC x pupil
    fig_mpfc = figure();
    hold on 
    semshade(session_xcor_mpfc_pupil_corrected, 0.3, 'k', 'k', ...
             session_lags, 1);
    plot([0,0], ylim, 'k--')
    xlabel('Lag (s)', 'FontSize', 16)
    ylabel({'NE_{mPFC} x pupil', ...
            'Shuffle Corrected Cross Correlation'}, 'FontSize', 16)
    saveas(fig_mpfc, 'Figures/fig3b_mpfc_pupil.fig')
    saveas(fig_mpfc, 'Figures/fig3b_mpfc_pupil.svg')

    %% Plot: S1 x pupil
    fig_s1 = figure();
    hold on;
    semshade(session_xcor_s1_pupil_corrected, 0.3, 'k', 'k', ...
             session_lags, 1);
    plot([0,0], ylim, 'k--')
    xlabel('Lag (s)', 'FontSize', 16)
    ylabel({'NE_{S1} x pupil', ...
            'Shuffle Corrected Cross Correlation'}, 'FontSize', 16)
    saveas(fig_s1, 'Figures/fig3b_s1_pupil.fig')
    saveas(fig_s1, 'Figures/fig3b_s1_pupil.svg')

    %% Return all useful outputs
    results.lags = session_lags;
    results.Fs_pupil = Fs_pupil;

    results.session_mpfc_pupil = session_xcor_mpfc_pupil;
    results.session_s1_pupil   = session_xcor_s1_pupil;

    results.shuffle_mpfc_pupil = shuff_xcor_mpfc_pupil;
    results.shuffle_s1_pupil   = shuff_xcor_s1_pupil;

    results.corrected_mpfc_pupil = session_xcor_mpfc_pupil_corrected;
    results.corrected_s1_pupil   = session_xcor_s1_pupil_corrected;
end


function [mpfc_ds, s1_ds, pupil, pupil_t] = ...
    putOnPupilTimebase(mpfc, s1, t, p, pt)
% Interpolate photometry onto the pupil timestamps. This both downsamples
% the faster photometry and makes the samples explicitly time-aligned.

    t = t(:)';
    pupil_t = pt(:)';

    nTrials = min([size(mpfc,1), size(s1,1), size(p,1)]);
    mpfc = mpfc(1:nTrials,:);
    s1   = s1(1:nTrials,:);
    pupil = p(1:nTrials,:);

    % If pt was returned as one row per trial, use the first row as the
    % common pupil time vector.
    if ~isvector(pt)
        pupil_t = pt(1,:);
    end

    % Keep only pupil samples lying within the photometry time range.
    keep = pupil_t >= min(t) & pupil_t <= max(t);
    pupil_t = pupil_t(keep);
    pupil = pupil(:,keep);

    mpfc_ds = nan(nTrials, length(pupil_t));
    s1_ds   = nan(nTrials, length(pupil_t));

    for i = 1:nTrials
        mpfc_ds(i,:) = interp1(t, mpfc(i,:), pupil_t, 'linear');
        s1_ds(i,:)   = interp1(t, s1(i,:),   pupil_t, 'linear');
    end
end
