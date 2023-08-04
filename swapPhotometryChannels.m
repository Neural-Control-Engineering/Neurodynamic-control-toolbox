function data = swapPhotometryChannels(data)
% returns table with photometry channels swapped for consistency across
% sessions

    [r, c] = size(data);

    % Checking if any of the two channels are swapped
    % Find the most frequently occurring reference in photometry_region_ch1
    [uniqueValues_ch1, ~, occurrences_ch1] = unique(data.photometry_region_ch1, 'stable');
    count_ch1 = accumarray(occurrences_ch1, 1);
    [~, idx_mode_ch1] = max(count_ch1);
    mode_ch1 = uniqueValues_ch1{idx_mode_ch1};
    
    % Find the most frequently occurring reference in photometry_region_ch2
    [uniqueValues_ch2, ~, occurrences_ch2] = unique(data.photometry_region_ch2, 'stable');
    count_ch2 = accumarray(occurrences_ch2, 1);
    [~, idx_mode_ch2] = max(count_ch2);
    mode_ch2 = uniqueValues_ch2{idx_mode_ch2};
    
    % Find rows where photometry_region_ch1 does not match the mode of ch1
    % or photometry_region_ch2 does not match the mode of ch2
    rows_to_swap = ~(strcmp(data.photometry_region_ch1, mode_ch1) & strcmp(data.photometry_region_ch2, mode_ch2));
    
    % Iterate through each variable in the table
    varNames = data.Properties.VariableNames;
    for i = 1:numel(varNames)
        if endsWith(varNames{i}, '_ch1')
            % Find the corresponding ch2 column
            ch2_column = strrep(varNames{i}, '_ch1', '_ch2');
            % Swap the values in ch1 and ch2 for the identified rows
            tmp = data.(varNames{i})(rows_to_swap);
            data.(varNames{i})(rows_to_swap) = data.(ch2_column)(rows_to_swap);
            data.(ch2_column)(rows_to_swap) = tmp;
        end
    end
    for i = 1:length(find(rows_to_swap))
        found_idx = find(rows_to_swap);
        disp("Swapped Channels for Row " + string(found_idx(i)));
    end

end