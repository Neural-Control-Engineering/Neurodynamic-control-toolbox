function xcorrByOutcomeAllSesh(data)
    sessions = unique(data.session_id);
    
    for i = 1:length(sessions)
        if contains(sessions(i), 'mPFC-S1-NE')
            fprintf('%s\n', sessions(i))
            xcorrByOutcome(data, sessions(i));
        end
    end

end
