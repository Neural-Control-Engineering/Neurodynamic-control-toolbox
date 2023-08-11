function ema_data = computeEMA(data_array, N)
    alpha = 2 / (N + 1);
    ema_data = zeros(size(data_array));
    ema_data(1,:) = data_array(1,:);
    
    for row = 2:size(data_array,1)
        ema_data(row,:) = (1 - alpha) * ema_data(row-1,:) + alpha * data_array(row,:);
    end
end
