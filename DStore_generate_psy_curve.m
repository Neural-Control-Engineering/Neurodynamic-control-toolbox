function [figure_out] = DStore_generate_psy_curve(DStore_path,Extra_filter, plot_title)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
if ~exist('Extra_filter','var')
    Extra_filter.property = {1};
    Extra_filter.filter = {'-'};
end
if ~exist('plot_title','var')
% third parameter title does not exist, so default it to something
    plot_title = 'Cumulative Psycurve of target animal';
end

% Example DStore path:
% DStore_path = "H:\.shortcut-targets-by-id\1yB5u8zHl-aBucQQEQZIgnPdQ1Re2j-5E\Project_Neurotransmitter-Exploration\Datastores\Datastore_created_10-Mar-2023.mat";
temp = load(DStore_path);
Datastore = temp.Datastore;
all_nonempty_index = find(~cellfun(@isempty,gather(Datastore(:,5))));
all_trial_number  = cell2mat(gather(Datastore(all_nonempty_index,6)));
all_session_number  = cell2mat(gather(Datastore(all_nonempty_index,5)));
%all_session_ID  = gather(Datastore(all_nonempty_index,1));
all_psy_curve = gather(Datastore(all_nonempty_index,47));


%%
% target animal psy curve alone filtered/No-filter
lg_new_session = (all_session_number(1:end-1) ~= all_session_number(2:end));
lg_new_session=[true;lg_new_session];

%%
%Example extra filter, currently only support properties with class Char or strings
% Extra_filter.property = {1,4,26};
% Extra_filter.filter = {'243-','Phase III','NA'};

lg_psy_curve = lg_new_session;
lg_photometry = logical(all_trial_number);
for i = 1:numel(Extra_filter.property)
    property_this = Extra_filter.property{i};
    filter_this = Extra_filter.filter{i};
    all_this = gather(Datastore(all_nonempty_index,property_this));
    if isstring(all_this{1,1})
        lg_this = contains([all_this{:,1}], filter_this)';
    elseif ischar(all_this{1,1})
        lg_this = contains(all_this(:,1), filter_this);
    end
    lg_psy_curve = lg_psy_curve & lg_this;
    lg_photometry = lg_photometry & lg_this;
end

target_psy_curve = all_psy_curve(lg_psy_curve, 1);
%target_photometry = all_psy_curve(lg_photometry,1);
%%
figure_out = figure();
%subplot(1,2,1);
hold on
sum_curve = zeros(numel(target_psy_curve),numel(target_psy_curve{1}(2,:)));
for i = 1:numel(target_psy_curve)
    p1 = plot(target_psy_curve{i}(1,:), ...
        target_psy_curve{i}(2,:),'k','LineWidth',1.2);
    p1.Color(4) = 0.15;
    sum_curve(i,:) = target_psy_curve{i}(2,:);
end
plot_title = strcat(plot_title,' (',num2str(numel(target_psy_curve)),' Sessions)');
mean_curve = mean(sum_curve);
SEM_curve = std(sum_curve)/sqrt(height(sum_curve));
p2 = errorbar(target_psy_curve{1}(1,:),mean_curve,SEM_curve, ...
    'k','LineWidth',1.7);
legend([p1, p2], "Session Psychometric Curves","Average Psychometric Curve",'Location','Southeast')
title(plot_title)

end