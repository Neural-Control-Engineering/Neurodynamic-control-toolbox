function Plot_IBehavior_Analysis(Behavior_Analysis_List)
close all
Color = ['b' 'k' 'm' 'g' 'y' 'c' ];
LegendList = append(Behavior_Analysis_List(1).Name,',');
for i = 2:length(Behavior_Analysis_List)
    LegendList = append(LegendList,Behavior_Analysis_List(i).Name,',');
end
LegendList = split(LegendList,',');
LegendList(end) = [];

TitleList = 'Onset Time, Stimulation High Time, Stimulation Low Time,Punish,Distractor,Lick';
TitleList = split(TitleList,',');
figure(1)
for j = 4:6
subplot(2,3,j-1)
for i = 1:length(Behavior_Analysis_List)
    PPunishment = Behavior_Analysis_List(i).Session.All_Data_PosProcess(:,j);
    Punishment = cell2mat(PPunishment);
    Min_Punishment = min(Punishment,[],'omitnan');
    Max_Punishment = max(Punishment,[],'omitnan');
    Avg_Punishment = mean(Punishment,'omitnan');

    hold on

    L(i) = plot([Min_Punishment Max_Punishment],[i i],Color(i));
    plot([Min_Punishment Max_Punishment],[i i],'o','MarkerFaceColor',Color(i),'MarkerEdgeColor',Color(i))
    plot(Avg_Punishment,i,'o','MarkerFaceColor','r','MarkerEdgeColor','r')
    title(TitleList(j))

end
end
legend(L,LegendList)

%% Stim Times
for i = 1:length(Behavior_Analysis_List)
    Stim = Behavior_Analysis_List(i).Session.All_Data_PosProcess(:,2);
    Strength = Behavior_Analysis_List(i).Session.All_Data_PosProcess(:,3);

    Stim = cell2mat(Stim);
    Strength = cell2mat(Strength);
    idx = 1;
    idx2 = 1;
    for j = 1:length(Stim)
        if Strength(j) == 0
            Stim_Low(idx) = Stim(j);
            idx = idx+1;
        elseif Strength(j) == 2
            Stim_High(idx2) = Stim(j);
            idx2 = idx2+1;
        end
    end


    Max_Stim_High(i) = max(Stim_High,[],'omitnan');
    Min_Stim_High(i) = min(Stim_High,[],'omitnan');
    Avg_Stim_High(i) = mean(Stim_High,'omitnan');

    Max_Stim_Low(i) = max(Stim_Low,[],'omitnan');
    Min_Stim_Low(i) = min(Stim_Low,[],'omitnan');
    Avg_Stim_Low(i) = mean(Stim_Low,'omitnan');
end



for j = 1:2
    subplot(2,3,j)
    title(TitleList(j+1))
    for i = 1:length(Behavior_Analysis_List)
        if j==1
            hold on
            plot([Min_Stim_High(i) Max_Stim_High(i)],[i i],Color(i));
            plot([Min_Stim_High(i) Max_Stim_High(i)],[i i],'o','MarkerFaceColor',Color(i),'MarkerEdgeColor',Color(i))
            plot(Avg_Stim_High(i),i,'o','MarkerFaceColor','r','MarkerEdgeColor','r')
        elseif j==2
            hold on
            plot([Min_Stim_Low(i) Max_Stim_Low(i)],[i i],Color(i));
            plot([Min_Stim_Low(i) Max_Stim_Low(i)],[i i],'o','MarkerFaceColor',Color(i),'MarkerEdgeColor',Color(i))
            plot(Avg_Stim_Low(i),i,'o','MarkerFaceColor','r','MarkerEdgeColor','r')
        end
    end
end
end
