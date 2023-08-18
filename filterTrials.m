function db = filterTrials(data, filterBy, value)
% filters trials in table *data*.  specify what you want to filter the
% table by with *filterBy* and *value* and it returns a reduced table.
%   Example: filterTrials(data, 'animal', '109') returns a table only
%           containing trials for the animal 109.
% Craig Kelley, NEC Lab, 8/7/23

    if strcmp(filterBy, 'animal')
        name = cell(size(data,1),1);
        for i = 1:size(data,1)
            name{i} = value;
        end
        inds = cellfun(@contains, data.session_id, name);
        db = data(inds,:);
    elseif strcmp(filterBy, 'session_id')
        db = data(data.session_id == value,:);
    elseif strcmp(filterBy, 'categorical_outcome')
        db = data(data.categorical_outcome == value, :);
    elseif strcmp(filterBy, 'go-nogo')
        db = data(data.go_nogo == value, :);
    elseif strcmp(filterBy, 'stim_strength_less_than')
        db = data(data.stimulus_strength < value, :);
    elseif strcmp(filterBy, 'stim_strength_greater_than')
        db = data(data.stimulus_strength > value, :);
    elseif strcmp(filterBy, 'phase')
        db = data(data.phase == value, :);
    elseif strcmp(filterBy, 'recording_location')
        name = cell(size(data,1),1);
        for i = 1:size(data,1)
            name{i} = value;
        end
        inds = cellfun(@contains, data.session_id, name);
        db = data(inds,:);
    else
        fprintf('Invalid filter method\n')
    end

end