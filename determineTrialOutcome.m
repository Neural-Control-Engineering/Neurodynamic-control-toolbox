function [trial_outcome] = determineTrialOutcome(stim_strength,responses)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

trial_outcome = strings(length(stim_strength),1);
response = responses(:,1);
late_response = responses(:,2);

for i = 1:length(stim_strength)
    psi = stim_strength(i);
    if psi==0 && response(i) == 0 && late_response(i) == 0
        trial_outcome(i) = 'CR';
    elseif psi==0 && response(i) == 1 
        trial_outcome(i) = 'FA'; % the priority of judging FA should be higher than judging Delayed FA
    elseif psi==0 && late_response(i) == 1
        % I add the charactor of CR so depend on how you search the property with contains() or strfind
        % we can treat it as either CR or Delayed FA
        trial_outcome(i) = 'Delayed FA (CR)'; 
    elseif psi > 0 && response(i) == 0 && late_response(i) == 0 % the old code ignore cases when stim_strength = 0.05, 0.1 & 0.2
        trial_outcome(i) = 'Miss';
    elseif psi > 0 && response(i) == 1 % the priority of judging Hit should be higher than judging Near Hit
        trial_outcome(i) = 'Hit';
    elseif psi > 0 && late_response(i) == 1 
        % I add the charactor of CR so depend on how you search the property with contains() or strfind
        % we can treat it as either Miss or Near Hit
        trial_outcome(i) = 'Near Hit (Miss)';
    end
end

