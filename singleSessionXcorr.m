function [lags, cs] = singleSessionXcorr(data, session_id)

    outdir = sprintf('./Xcorrs/%s/', session_id);
    mkdir(outdir)
    
    data = swapPhotometryChannels(data);
    data = data(data.session_id == session_id,:);
    plot_each = 1;

    Fs = 1 / (data.photometry_ch1{1,1}(2,1) - data.photometry_ch1{1,1}(1,1));
    cs = zeros(size(data,1), Fs*4-1);
    lags = zeros(size(data,1), Fs*4-1);
    for i = 1:size(data,1)
        fprintf('Plotting trial %i\n', i)
        ch1 = data.photometry_ch1{i,1}(:,2);
        ch2 = data.photometry_ch2{i,1}(:,2);
        t = data.photometry_ch1{i,1}(:,1) - data.stimulus_time(i);
        ch1 = ch1(t < 0 & t > -2);
        ch2 = ch2(t < 0 & t > -2);
        t = t(t < 0 & t > -2);
        [c, lag] = xcorr(ch1-mean(ch1), ch2-mean(ch2));
        lags(i,:) = lag ./ Fs;
        cs(i,:) = c;
        if plot_each
            fig = figure('Visible', 'off'); 
            subplot(2,1,1); hold on;
            plot(t, ch1-mean(ch1), 'b', 'DisplayName', data.photometry_region_ch1{i})
            plot(t, ch2-mean(ch2), 'r', 'DisplayName', data.photometry_region_ch2{i})
            legend()
            xlabel('Time (s)')
            ylabel('Voltage (mV)')
            subplot(2,1,2)
            plot(lag ./ Fs, c)
            xlabel('Lags (s)')
            ylabel('xcorr')
            subplot(2,1,1)
            t = sprintf('%s, trial %i: %s', session_id, i, data.categorical_outcome(i));
            t = strrep(t, '_', '-');
            title(t)
            fname = sprintf('%s/%s-trial%i.png', outdir, session_id, i);
            saveas(fig, fname)
        end 
    end 
end