function [session_list_return] = fetchSessions(paths,animal_id)
%FETCHSESSIONS Provide a complete list of processed sessions for an aninmal
%   This finds all processed behavior data files and presents a list for
%   the user to select
    sessions = dir(fullfile(paths.processed_behavior_data,'*-*.mat'));
    temp_sessions = strings(length(sessions),1);
    
    for i = 1:length(sessions)
        name_split = split(sessions(i).name,'.mat');
        temp_sessions(i) = name_split{1};
    end
    
    session_list = cellstr(temp_sessions(contains(temp_sessions,animal_id)));
    
    [indx, tf] = listdlg('Name','File Selection','PromptString', {'Select at least one session you',...
        'would like to run analysis on.'}, ...
        'ListString', session_list);
    switch tf
        case 1
            session_list_return = session_list(indx);
        case ''
            return
    end
end