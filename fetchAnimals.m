function animals = fetchAnimals(data)
% returns list of animals found in data.  assumes
% animal id is first entry in session_id.
% Craig Kelley, NEC Lab, 8/7/23

    sessions = unique(data.session_id);
    animals = zeros(1,length(sessions));
    for i = 1:length(sessions)
        ids = strsplit(sessions(i),'-');
        animals(i) = ids(1);
    end
    animals = unique(animals);

end
