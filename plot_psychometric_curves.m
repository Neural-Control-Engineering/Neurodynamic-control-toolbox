function plot_psychometric_curves(responses, figtitle)
%PLOT_PSYCHOMETRIC_CURVES Outputs stacked psychometric curves for an
%animal
%   Receives a matrix with animal response rates for
%   all stimulus strengths and returns a stacked psychometric curve to
%   represent the animals history
if nargin < 2
    figtitle = 'Psychometric Curve';
end

psychometric_fig = figure('Visible','on');

% Plot response rate for individual sessions
plot(responses(1,:),responses(2,:),'Color',[0.85 0.85 0.85]);
hold on

% Plot the most recent trial in cyan
plot(responses(1,:),responses(end,:),'Color','r','LineWidth',5);
xlabel('Stimulus Strength (PSI)');
ylabel('Response Rate');
title(figtitle);

end