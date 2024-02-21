function [cleaned_summary_of_sessions] = cleanCombinedData(summary_of_sessions,phases_to_include,exclude_missing_pupil,exclude_missing_photometry,exclude_poor_performance,NT_to_include)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%################ CHOOSE WHICH PHASES TO INCLUDE #########################

if strcmp(phases_to_include,'all')
    cleaned_summary_of_sessions = summary_of_sessions;
elseif strcmp(phases_to_include,'Phase I')
    cleaned_summary_of_sessions = summary_of_sessions(strcmp([summary_of_sessions{:,4}]','Phase I'),:);
    disp("Removed " + (height(summary_of_sessions)-height(cleaned_summary_of_sessions)) + " sessions from the list that were not Phase I.");
elseif strcmp(phases_to_include,'Phase II')
    cleaned_summary_of_sessions = summary_of_sessions(strcmp([summary_of_sessions{:,4}]','Phase II'),:);
    disp("Removed " + (height(summary_of_sessions)-height(cleaned_summary_of_sessions)) + " sessions from the list that were not Phase II.");
elseif strcmp(phases_to_include,'Phase I & Phase II')
    cleaned_summary_of_sessions = summary_of_sessions(strcmp([summary_of_sessions{:,4}]','Phase I') | strcmp([summary_of_sessions{:,3}]','Phase II'),:);
    disp("Removed " + (height(summary_of_sessions)-height(cleaned_summary_of_sessions)) + " sessions from the list that were not Phase I or II.");
elseif strcmp(phases_to_include,'Phase III Cumulative') || strcmp(phases_to_include,'Phase III Learning Period')
    cleaned_summary_of_sessions = summary_of_sessions(strcmp([summary_of_sessions{:,4}]','Phase III'),:);
    disp("Removed " + (height(summary_of_sessions)-height(cleaned_summary_of_sessions)) + " sessions from the list that were not Phase III.");
end

disp(strcat("There are ",string(height(cleaned_summary_of_sessions))," sessions included in this dataset."));

%################ EXCLUDE POOR PERFORMANCE ###############################
if exclude_poor_performance == true
    performance_pass = false(height(cleaned_summary_of_sessions),1);
    for i = 1:height(cleaned_summary_of_sessions)
    
        if height(cleaned_summary_of_sessions{i,33}) == 6
            start_height = height(cleaned_summary_of_sessions);
    
            response_0 = cleaned_summary_of_sessions{i,33}(1,1);
            response_2 = cleaned_summary_of_sessions{i,33}(1,2);
            response_5 = cleaned_summary_of_sessions{i,33}(1,3);
            response_10 = cleaned_summary_of_sessions{i,33}(1,4);
            response_40 = cleaned_summary_of_sessions{i,33}(1,6);
    
            if response_0 < 0.5 && response_2 < 0.90
                performance_pass(i) = true;
            else
                performance_pass(i) = false;
            end
        else
            %performance_pass(i) = false;
        end

    end
    cleaned_summary_of_sessions = cleaned_summary_of_sessions(performance_pass,:);
    disp("Removed " + (start_height-height(cleaned_summary_of_sessions)) + " sessions from the list because the session performance was below threshold.");
end

%################ EXCLUDE MISSING PUPIL ###############################
if exclude_missing_pupil == true
    start_height = height(cleaned_summary_of_sessions);
    pupil_pass = false(height(cleaned_summary_of_sessions));
    for i = 1:height(cleaned_summary_of_sessions)
        pupil_pass(i) = ~isempty(cleaned_summary_of_sessions{i,31});
    end
    cleaned_summary_of_sessions = cleaned_summary_of_sessions(pupil_pass,:);
    disp("Removed " + (start_height-height(cleaned_summary_of_sessions)) + " sessions from the list because there was no pupil data.");
end

%################ EXCLUDE MISSING PHOTOMETRY ############################
if exclude_missing_photometry == true
    start_height = height(cleaned_summary_of_sessions);
    photometry_pass = false(height(cleaned_summary_of_sessions));
    for i = 1:height(cleaned_summary_of_sessions)
        photometry_pass(i) = ~isempty(cleaned_summary_of_sessions{i,30});
    end
    cleaned_summary_of_sessions = cleaned_summary_of_sessions(photometry_pass,:);
    disp("Removed " + (start_height-height(cleaned_summary_of_sessions)) + " sessions from the list because there was no photometry data.");

end

%################ CHOOSE WHICH NEUROTRANSMITTER TO ANALYZE ############################
if NT_to_include == "All"
    cleaned_summary_of_sessions = cleaned_summary_of_sessions;
elseif NT_to_include == "NE"
    start_height = height(cleaned_summary_of_sessions);
    cleaned_summary_of_sessions = cleaned_summary_of_sessions(contains([cleaned_summary_of_sessions{:,1}],"NE"),:);
    disp("Removed " + (start_height-height(cleaned_summary_of_sessions)) + " sessions from the list because they were not NE sessions.");
elseif NT_to_include == "ACh"
    start_height = height(cleaned_summary_of_sessions);
    cleaned_summary_of_sessions = cleaned_summary_of_sessions(contains([cleaned_summary_of_sessions{:,1}],"ACh"),:);
    disp("Removed " + (start_height-height(cleaned_summary_of_sessions)) + " sessions from the list because they were not ACh sessions.");
elseif NT_to_include == "ACh & NE"
    start_height = height(cleaned_summary_of_sessions);
    cleaned_summary_of_sessions = cleaned_summary_of_sessions(contains([cleaned_summary_of_sessions{:,1}],"ACh")|contains([cleaned_summary_of_sessions{:,1}],"NE"),:);
    disp("Removed " + (start_height-height(cleaned_summary_of_sessions)) + " sessions from the list because they were not ACh or NE sessions.");
elseif NT_to_include == "DA"
    start_height = height(cleaned_summary_of_sessions);
    cleaned_summary_of_sessions = cleaned_summary_of_sessions(contains([cleaned_summary_of_sessions{:,1}],"DA"),:);
    disp("Removed " + (start_height-height(cleaned_summary_of_sessions)) + " sessions from the list because they were not DA sessions.");
elseif NT_to_include == "5HT"
    start_height = height(cleaned_summary_of_sessions);
    cleaned_summary_of_sessions = cleaned_summary_of_sessions(contains([cleaned_summary_of_sessions{:,1}],"5HT"),:);
    disp("Removed " + (start_height-height(cleaned_summary_of_sessions)) + " sessions from the list because they were not 5HT sessions.");
end

end