function [pyschometric_performance] = calculatePsychometricCurvesSEM(stim_strength,response,phase,puffs)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
%   response is binary of Go/no-go (column 13)

len_puffs = length(puffs);
pyschometric_performance = zeros(3,len_puffs);


if strcmp(phase,'Phase I') || strcmp(phase,'Phase II') || strcmp(phase,'Phase III Learning Period') || strcmp(phase,"Phase II with optogenetics")
    % For 0 psi
    puff = puffs(1);
 
    resp = response(stim_strength == puff);

    pyschometric_performance(1,1) = puff;
    pyschometric_performance(2,1) = sum(resp)/length(stim_strength(stim_strength == puff));
    pyschometric_performance(3,1) = std(resp)/sqrt(length(resp)); % SEM

    puff = puffs(2);

    resp = response(stim_strength == puff);
    
    pyschometric_performance(1,2) = puff;
    pyschometric_performance(2,2) = sum(resp)/length(stim_strength(stim_strength == puff));
    pyschometric_performance(3,2) = std(resp)/sqrt(length(resp)); % SEM
    
elseif strcmp(phase,'Phase III Cumulative') || strcmp(phase,'Phase III')
    for i = 1:length(puffs)
        puff = puffs(i);
        stim_strength_mat = stim_strength(:, 1); %maybe type error?
        sum(stim_strength_mat(stim_strength_mat == 0.0));
        if ~isempty(response(stim_strength_mat == puff))
            pyschometric_performance(1,i) = puff;
            resp = response(stim_strength_mat == puff);
            pyschometric_performance(2,i) = sum(resp)/length(resp);
            pyschometric_performance(3,i) = std(resp)/sqrt(length(resp)); % SEM
        else
            pyschometric_performance(1,i) = nan;
            pyschometric_performance(3,i) = nan; % NaN for SEM when puff is not in data
        end
    end
else
    display(strcat(phase," is not defined in calculatePsychometricCurves"))
end
