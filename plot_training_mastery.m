%%
clc;clear all; close all;
path = 'H:\.shortcut-targets-by-id\1yB5u8zHl-aBucQQEQZIgnPdQ1Re2j-5E\Project_Neurotransmitter-Exploration\Datastores\';
animal_list= {'242_243.mat','240_241.mat'};
save_path = 'H:\.shortcut-targets-by-id\1yB5u8zHl-aBucQQEQZIgnPdQ1Re2j-5E\Project_Neurotransmitter-Exploration\plots\photometry\';
%%
time_range = [-4,4];
photometry_metrix_mPFC_Phase1_20psi_go_all = [];
photometry_metrix_mPFC_Phase1_0psi_nogo_all = [];
photometry_metrix_mPFC_Phase3_20psi_go_all = [];
photometry_metrix_mPFC_Phase3_0psi_nogo_all = [];
for i = 1:numel(animal_list)
    file_name = strcat(path, animal_list{i});
    
    load(file_name);
    temp  = gather(Datastore(:,5));
    % for trial index
    all_nonempty_index = find(~cellfun(@isempty,temp));
    all_trial_number  = cell2mat(gather(Datastore(all_nonempty_index,6)));
    all_stim_strength = gather(Datastore(all_nonempty_index,10));
    all_phase = gather(Datastore(all_nonempty_index,4));
    all_gonogo = gather(Datastore(all_nonempty_index,13));
    all_ch1_region = gather(Datastore(all_nonempty_index,19));
    % for photometry extraction
    all_stim_time = gather(Datastore(all_nonempty_index,9));
    all_ch1_photometry = gather(Datastore(all_nonempty_index,37));
    %logics arrays for index 
    lg_all = logical(all_trial_number);
    lg_mPFC = contains(all_ch1_region, "mPFC");
    lg_phase1 = ([all_phase{:,1}] == "Phase I")';
    lg_phase3 = ([all_phase{:,1}] == "Phase III")';
    lg_go = ([all_gonogo{:,1}] == 1)';
    lg_nogo = ([all_gonogo{:,1}] == 0)';
    lg_20psi = ([all_stim_strength{:,1}] == 2)';
    lg_0psi = ([all_stim_strength{:,1}] == 0)';

    %combine logics
    lg_mPFC_Phase1_20psi_go = lg_all & lg_mPFC & lg_phase1 & lg_20psi & lg_go;
    %lg_mPFC_Phase1_20psi_nogo = lg_all & lg_mPFC & lg_phase1 & lg_20psi & lg_nogo;
    %lg_mPFC_Phase1_0psi_go  = lg_all & lg_mPFC & lg_phase1 & lg_0psi & lg_go;
    lg_mPFC_Phase1_0psi_nogo = lg_all & lg_mPFC & lg_phase1 & lg_0psi & lg_nogo;
    lg_mPFC_Phase3_20psi_go = lg_all & lg_mPFC & lg_phase3 & lg_20psi & lg_go;
    %lg_mPFC_Phase3_20psi_nogo = lg_all & lg_mPFC & lg_phase3 & lg_20psi & lg_nogo;
    %lg_mPFC_Phase3_0psi_go = lg_all & lg_mPFC & lg_phase3 & lg_0psi & lg_go;
    lg_mPFC_Phase3_0psi_nogo = lg_all & lg_mPFC & lg_phase3 & lg_0psi & lg_nogo;
    photometry_metrix_mPFC_Phase1_20psi_go_this = Dstore_generate_photometry_matrix ( ...
        all_stim_time(lg_mPFC_Phase1_20psi_go,1), ...
        all_ch1_photometry(lg_mPFC_Phase1_20psi_go,1), time_range);
    photometry_metrix_mPFC_mPFC_Phase1_0psi_nogo_this = Dstore_generate_photometry_matrix ( ...
        all_stim_time(lg_mPFC_Phase1_0psi_nogo,1), ...
        all_ch1_photometry(lg_mPFC_Phase1_0psi_nogo,1), time_range);
    photometry_metrix_mPFC_Phase3_20psi_go_this = Dstore_generate_photometry_matrix ( ...
        all_stim_time(lg_mPFC_Phase3_20psi_go,1), ...
        all_ch1_photometry(lg_mPFC_Phase3_20psi_go,1), time_range);
    photometry_metrix_mPFC_Phase3_0psi_nogo_this = Dstore_generate_photometry_matrix ( ...
        all_stim_time(lg_mPFC_Phase3_0psi_nogo,1), ...
        all_ch1_photometry(lg_mPFC_Phase3_0psi_nogo,1), time_range);

    photometry_metrix_mPFC_Phase1_20psi_go_all = vertcat(photometry_metrix_mPFC_Phase1_20psi_go_all,photometry_metrix_mPFC_Phase1_20psi_go_this);
    photometry_metrix_mPFC_Phase1_0psi_nogo_all = vertcat(photometry_metrix_mPFC_Phase1_0psi_nogo_all,photometry_metrix_mPFC_mPFC_Phase1_0psi_nogo_this);
    photometry_metrix_mPFC_Phase3_20psi_go_all = vertcat(photometry_metrix_mPFC_Phase1_0psi_nogo_all,photometry_metrix_mPFC_Phase3_20psi_go_this);
    photometry_metrix_mPFC_Phase3_0psi_nogo_all = vertcat(photometry_metrix_mPFC_Phase1_0psi_nogo_all,photometry_metrix_mPFC_Phase3_0psi_nogo_this);

end
%%
time_axis = linspace(-4,4,961);
photometry_mean_mPFC_Phase1_20psi_go = mean(photometry_metrix_mPFC_Phase1_20psi_go_all)';
photometry_mean_mPFC_Phase1_0psi_nogo = mean(photometry_metrix_mPFC_Phase1_0psi_nogo_all)';
photometry_mean_mPFC_Phase3_20psi_go = mean(photometry_metrix_mPFC_Phase3_20psi_go_all)';
photometry_mean_mPFC_Phase3_0psi_nogo = mean(photometry_metrix_mPFC_Phase3_0psi_nogo_all)';
upper_bond = 1.3*max([photometry_mean_mPFC_Phase1_20psi_go; ...
    photometry_mean_mPFC_Phase1_0psi_nogo; ...
    photometry_mean_mPFC_Phase3_20psi_go; ...
    photometry_mean_mPFC_Phase3_0psi_nogo]);
lower_bond = 1.2*min([photometry_mean_mPFC_Phase1_20psi_go; ...
    photometry_mean_mPFC_Phase1_0psi_nogo; ...
    photometry_mean_mPFC_Phase3_20psi_go; ...
    photometry_mean_mPFC_Phase3_0psi_nogo]);

to_plot = {photometry_mean_mPFC_Phase1_20psi_go,...
    photometry_mean_mPFC_Phase1_0psi_nogo...
    photometry_mean_mPFC_Phase3_20psi_go...
    photometry_mean_mPFC_Phase3_0psi_nogo};
legend_list = {strcat('mPFC NE Phase1 20Psi Go (',num2str(height(photometry_metrix_mPFC_Phase1_20psi_go_all)),' trials)'),...
    strcat('mPFC NE Phase1 0Psi No-Go (',num2str(height(photometry_metrix_mPFC_Phase1_0psi_nogo_all)),' trials)'),...
    strcat('mPFC NE Phase3 20Psi Go (',num2str(height(photometry_metrix_mPFC_Phase3_20psi_go_all)),' trials)'),...
    strcat('mPFC NE Phase3 0Psi No-Go (',num2str(height(photometry_metrix_mPFC_Phase3_0psi_nogo_all)),' trials)')};
%%
figure_this = figure('color', 'white', 'Position',[100 100 950 650]);
color = {'r','b','r','b'};
for i = 1:4
    subplot(2,2,i)
    p_this = plot(time_axis,to_plot{i},color{i},'LineWidth',1.1);
    if i > 2
        p_this.Color(1) = 0.6*p_this.Color(1);
    else
        p_this.Color(4) = 0.6;
    end
    ylim([lower_bond,upper_bond])
    xline(0,'k--')
    grid on
    legend(legend_list{i})
end
%%
save_name1 = strcat(save_path, '4mice_mPFC_NE_training_mastery_comparision.fig');
save_name2 = strcat(save_path, '4mice_mPFC_NE_training_mastery_comparision.jpg');
saveas(figure_this, save_name1);
saveas(figure_this, save_name2);
