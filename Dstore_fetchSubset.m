function [subset_datastore] = Dstore_fetchSubset(dstore, filters)
    % This function returns a subset of the input datastore 'dstore' that contains 
    % a specific string in the 'session_id' column.
    %
    % Args:
    % dstore (table): The datastore to be filtered.
    % filters (struct): A struct that may contain a field 'NT' with the string to filter on.
    %
    % Returns:
    % subset_datastore (table): The subset of 'dstore' that contains the string in 'session_id'.

    subset_datastore = dstore;
    
    if isfield(filters, 'NT')
        idx = contains(subset_datastore.photometry_region_ch1, filters.NT) | contains(subset_datastore.photometry_region_ch2, filters.NT);
        subset_datastore = subset_datastore(idx, :);
    end
    
    if isfield(filters, 'Phase')
        idx = contains(subset_datastore.phase, filters.Phase);
        subset_datastore = subset_datastore(idx,:);
    end

    if isempty(subset_datastore)
        warning('No data matches the provided filters. Returning the entire datastore.')
        subset_datastore = dstore;
    end
end
        