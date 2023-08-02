function [Behavior_Analysis] = IBehavioral_Analysis(file,paths)
old = cd(paths.processed_behavior_data);
file = strtrim(file);
behavior_data = load(file);
cd(paths.repo_path)
%assignin("base","behavior_data",behavior_data)

%% Arranging Stim Times and Strength
Data = behavior_data.behavior_data;

New_OnsetTrials = Data.trial_onset_tone;
New_StimTime = Data.stim_times;
New_StimStrength = Data.stim_strength;

for i = 2:length(New_OnsetTrials)+1
    if i<=length(New_OnsetTrials)
        idx = New_StimTime>New_OnsetTrials(i-1) & New_StimTime<New_OnsetTrials(i);
        idx = find(idx==1);
        if ~isempty(idx)
            Behavior_Analysis.Stim_Times{i-1,1} = New_StimTime(idx);
            Behavior_Analysis.Stim_Strength{i-1,1} = New_StimStrength(idx);
        else
            Behavior_Analysis.Stim_Times{i-1,1} = NaN;
            Behavior_Analysis.Stim_Strength{i-1,1} = NaN;
        end
    else
        idx = New_StimTime>New_OnsetTrials(i-1);
        idx = find(idx==1);
        if ~isempty(idx)
            Behavior_Analysis.Stim_Times{i-1,1} = New_StimTime(idx);
            Behavior_Analysis.Stim_Strength{i-1,1} = New_StimStrength(idx);
        else
            Behavior_Analysis.Stim_Times{i-1,1} = NaN;
            Behavior_Analysis.Stim_Strength{i-1,1} = NaN;
        end
    end
end

%% Arranging Punishment
New_Punishment = Data.punishment_times;

for i=2:length(New_OnsetTrials)+1
    if i<=length(New_OnsetTrials)
        idx = New_Punishment>New_OnsetTrials(i-1) & New_Punishment<New_OnsetTrials(i);
        idx = find(idx==1);
        if ~isempty(idx)
            Behavior_Analysis.Punishment_Times{i-1,1} = New_Punishment(idx);
        else
            Behavior_Analysis.Punishment_Times{i-1,1} = NaN;
        end
    else
        idx = New_Punishment>New_OnsetTrials(i-1);
        idx = find(idx==1);
        if ~isempty(idx)
            Behavior_Analysis.Punishment_Times{i-1,1} = New_Punishment(idx);
        else
            Behavior_Analysis.Punishment_Times{i-1,1} = NaN;
        end
    end
end

%% Arranging Distractor
New_Distractor = Data.distractor_times;

for i=2:length(New_OnsetTrials)+1
    if i<=length(New_OnsetTrials)
        idx = New_Distractor>New_OnsetTrials(i-1) & New_Distractor<New_OnsetTrials(i);
        idx = find(idx==1);
        if ~isempty(idx)
            Behavior_Analysis.Distractor_Times{i-1,1} = New_Distractor(idx);
        else
            Behavior_Analysis.Distractor_Times{i-1,1} = NaN;
        end
    else
        idx = New_Distractor>New_OnsetTrials(i-1);
        idx = find(idx==1);
        if ~isempty(idx)
            Behavior_Analysis.Distractor_Times{i-1,1} = New_Distractor(idx);
        else
            Behavior_Analysis.Distractor_Times{i-1,1} = NaN;
        end
    end
end

%% Arranging Lick
New_Lick = Data.lick_times;

for i=2:length(New_OnsetTrials)+1
    if i<=length(New_OnsetTrials)
        idx = New_Lick>New_OnsetTrials(i-1) & New_Lick<New_OnsetTrials(i);
        idx = find(idx==1);
        if ~isempty(idx)
            Behavior_Analysis.Lick_Times{i-1,1} = New_Lick(idx);
        else
            Behavior_Analysis.Lick_Times{i-1,1} = NaN;
        end
    else
        idx = New_Lick>New_OnsetTrials(i-1);
        idx = find(idx==1);
        if ~isempty(idx)
            Behavior_Analysis.Lick_Times{i-1,1} = New_Lick(idx);
        else
            Behavior_Analysis.Lick_Times{i-1,1} = NaN;
        end
    end
end

%% Final Additions to Structure Before Processing
Behavior_Analysis.Trial_Onset_Times = num2cell(New_OnsetTrials);
Behavior_Analysis.All_Data_PreProcess = [Behavior_Analysis.Trial_Onset_Times Behavior_Analysis.Stim_Times Behavior_Analysis.Stim_Strength Behavior_Analysis.Punishment_Times Behavior_Analysis.Distractor_Times Behavior_Analysis.Lick_Times];

%% Starting Data at the Same Time

[m,n] = size(Behavior_Analysis.All_Data_PreProcess);
for i = 1:m
    for j = 1:n
        if j == 3
            Behavior_Analysis.All_Data_PosProcess{i,j} = Behavior_Analysis.All_Data_PreProcess{i,j};
        else
            Behavior_Analysis.All_Data_PosProcess{i,j} = Behavior_Analysis.All_Data_PreProcess{i,j}-Behavior_Analysis.Trial_Onset_Times{i};
        end
    end
end

%% Plotting Histogram

% Punish = Behavior_Analysis.All_Data_PosProcess(:,4);
% Punish = cell2mat(Punish);
% figure(1)
% subplot(2,3,3)
% histogram(Punish(~isnan(Punish)),round(length(New_OnsetTrials)/10)) %CHANGE
% title('Punishment')
% subplot(2,3,4)
% Lick = Behavior_Analysis.All_Data_PosProcess(:,6);
% Lick = cell2mat(Lick);
% histogram(Lick(~isnan(Lick)),round(length(New_OnsetTrials)/10))
% title('Lick')
% subplot(2,3,5)
% Distractor = Behavior_Analysis.All_Data_PosProcess(:,5);
% Distractor = cell2mat(Distractor);
% histogram(Distractor(~isnan(Distractor)),round(length(New_OnsetTrials)/10))
% title('Distractor')
% subplot(2,3,2)
% idx = 1;
% idx2 = 1;
% for i = 1:length(New_OnsetTrials)    %CHANGE AND ADJUST FOR OTHERS FINAL CELL CANNOT BE MULTIPLE
%     if Behavior_Analysis.Stim_Strength{i}==0
%         Stim_TimeLow(idx) = Behavior_Analysis.All_Data_PosProcess(i,2);
%         idx = idx+1;
%     else
%         Stim_TimeHigh(idx2) = Behavior_Analysis.All_Data_PosProcess(i,2);
%         idx2 = idx2+1;
%     end
% end
% 
% Stim_TimeLow = cell2mat(Stim_TimeLow);
% histogram(Stim_TimeLow(~isnan(Stim_TimeLow)),round(length(New_OnsetTrials)/10))
% title('Low Strength Stim Time')
% subplot(2,3,1)
% Stim_TimeHigh(end) = [];
% Stim_TimeHigh = cell2mat(Stim_TimeHigh);
% histogram(Stim_TimeHigh(~isnan(Stim_TimeHigh)),round(length(New_OnsetTrials)/10))
% title('High Strength Stim Time')
cd(old)

end