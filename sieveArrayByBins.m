function binIndexArray = sieveArrayByBins(inputArray, binValues)
    % Initialize an array of the same size as the input array to store bin indices
    binIndexArray = zeros(size(inputArray));

    % Sieve the array and assign bin indices
    for i = 1:numel(inputArray)
        value = inputArray(i);
        binIndex = find(binValues >= value, 1);
        binIndexArray(i) = binIndex-1;
    end
end
