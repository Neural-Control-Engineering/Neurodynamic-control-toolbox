function cleaned_datastore = Dstore_cleanmissingdata(dstore)
    % This function removes rows from the input datastore 'dstore' if the 
    % 'pupil_area', 'photometry_ch1', and 'photometry_ch2' columns are all empty.
    %
    % Args:
    % dstore (table): The datastore to be cleaned.
    %
    % Returns:
    % cleaned_datastore (table): The cleaned datastore.

    % Create a logical index that is true where the specified columns are empty
    idx_pupil_area = cellfun(@isempty, dstore.pupil_area);
    idx_photometry_ch1 = cellfun(@isempty, dstore.photometry_ch1);
    idx_photometry_ch2 = cellfun(@isempty, dstore.photometry_ch2);

    % Combine the indices
    idx = idx_pupil_area | (idx_photometry_ch1 & idx_photometry_ch2);

    % Remove rows where any of the specified columns are empty
    cleaned_datastore = dstore(~idx, :);
end
