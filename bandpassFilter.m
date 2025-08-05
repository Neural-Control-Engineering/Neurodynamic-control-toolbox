function y = bandpassFilter(x, low, high, fs)
    % Define the filter order
    filter_order = 4;
    
    % Define the cutoff frequencies (normalized by Nyquist frequency)
    nyquist = fs / 2;
    low_cutoff = low / nyquist;
    high_cutoff = high / nyquist;
    
    % Design the Butterworth bandpass filter
    [b, a] = butter(filter_order, [low_cutoff, high_cutoff], 'bandpass');
    
    % Apply the filter using filtfilt to ensure zero-phase distortion
    y = filtfilt(b, a, x);
end
